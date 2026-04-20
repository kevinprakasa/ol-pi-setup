# Plan: Re-Run Integrations (Admin Re-Grade, Single Widget)

## Goal

Add a functional "Re-run integrations" button to `CodeWidgetGrading` that re-triggers code execution for a **single widget** and produces a correct aggregated score across all widgets for the question — by pre-populating non-target widgets' Redis state from their existing Stamps.

---

## Data Flow

```
Admin clicks "Re-run integrations" on widget W1 of question Q1 (which has W1 + W2)

→ OpenLearningClient calls ExamResource.rerunCodeGrading({ cohortMembershipId, examAttemptId, questionId, widgetId })
→ ol-async-engine reconstructs execution context from ExamAttemptCriterionEvaluation + QuestionRevision

→ [Phase 1] create_exam_grading_run(W1)           — PENDING in Redis + pending set + frozen registry
→ [Phase 2] _prepopulate_widget_from_stamp(W2)    — DONE in Redis (from Stamp) + frozen registry only (NOT pending set)
→ [Phase 3] _fire_exam_code_execution(W1)         — same callback URL, HMAC, timeout

→ code_execution runs W1, calls back to existing /callback endpoint
→ existing pipeline:
    resolve_exam_grading_run(W1)                   — removes W1 from pending set → empty → all resolved
    get_question_widget_results()                  — reads frozen registry {W1, W2} → reads both states from Redis
      W1: fresh result from code execution
      W2: stamp-sourced result (pre-populated)
    aggregate_widget_results([W1, W2])             — correct combined score
    resolve_exam_code_grading()                    — overwrites evaluation + upserts stamps

→ Client invalidates stamp query → fresh results appear
```

**Why this works for single-widget re-run:**
- Only W1 fires code execution (cheaper, faster)
- W2's last known result is read from its Stamp (persistent in MongoDB) and pre-loaded into Redis
- The existing aggregation logic sees both widgets and produces the correct combined score
- No changes needed to the callback endpoint, aggregation, or resolve logic

---

## Redis State at Each Phase

```
After Phase 1 (register target):
  exam_grade_pending:A:Q1           → SET {"W1"}
  exam_grade_q_widgets:A:Q1         → SET {"W1"}
  exam_grade:A:Q1:W1                → { status: PENDING, result: null }

After Phase 2 (pre-populate others from stamps):
  exam_grade_pending:A:Q1           → SET {"W1"}          ← unchanged, W2 NOT added
  exam_grade_q_widgets:A:Q1         → SET {"W1", "W2"}    ← W2 added to frozen registry
  exam_grade:A:Q1:W1                → { status: PENDING, result: null }
  exam_grade:A:Q1:W2                → { status: DONE, result: { score: {value:8, max:10}, ... } }

After W1 callback arrives:
  exam_grade_pending:A:Q1           → SET {}              ← W1 removed → empty → all resolved
  exam_grade:A:Q1:W1                → { status: DONE, result: { score: {value:5, max:5}, ... } }
  exam_grade:A:Q1:W2                → { status: DONE, result: { score: {value:8, max:10}, ... } }
  → aggregate: { score: { value: 13, max: 15 } }
  → resolve_exam_code_grading updates evaluation + stamps
```

---

## Files to Modify

### 1. `ol-async-engine/resources/code_execution_resource/exam_grading_helpers.py`

Add new helper:

```python
async def prepopulate_widget_from_stamp(
    exam_attempt_id: str,
    question_id: str,
    widget_id: str,
    criterion_evaluation_id: str,
) -> None:
    """Read a widget's last result from its Stamp and write it into Redis
    as a DONE state so aggregation includes it without re-running.

    Adds the widget to the frozen registry but NOT the pending set — so
    is_question_all_widgets_resolved only waits for the target widget.
    """
    from resources.common.data.mongo import get_db

    stamp = await get_db()["Stamp"].find_one({
        "resourceName": "examAttemptCriterionEvaluation",
        "resourceId": criterion_evaluation_id,
        "provider": "codeexecution",
        "widgetId": widget_id,
    })

    # If no stamp exists (widget was never graded), use zero score.
    if stamp and stamp.get("data"):
        result = {
            "score": stamp["data"].get("score", {"value": 0, "max": 0}),
            "text": stamp["data"].get("text"),
            "feedback": stamp["data"].get("feedback"),
        }
    else:
        result = {"score": {"value": 0, "max": 0}}

    # Write DONE state to per-widget key (NOT pending — already resolved).
    state = {"status": CodeRunStatus.DONE, "result": result}
    await redis_set(
        _grade_key(exam_attempt_id, question_id, widget_id),
        json.dumps(state),
        ex=_EXAM_GRADE_REDIS_TTL,
    )

    # Add to frozen registry only — NOT to pending set.
    q_key = _question_widgets_key(exam_attempt_id, question_id)
    await redis_sadd(q_key, [widget_id])
    await redis_expire(q_key, _EXAM_GRADE_REDIS_TTL)
```

### 2. `ol-async-engine/resources/exam_resource/resource.py`

Add `rerunCodeGrading` method after `manuallyAssessByAttemptId`:

```python
async def rerunCodeGrading(
    _user: UserResource,
    cohortMembershipId: str,
    examAttemptId: str,
    questionId: str,
    widgetId: str,
) -> None:
```

Steps:
1. Auth: `has_assessor_access` check on cohortMembership
2. `get_student_latest_exam_attempt_criterion_evaluations(examAttemptId)` → find criterion by questionId
3. Load `QuestionRevision` by `target_criterion["questionRevisionId"]`
4. Extract `code_files` from `target_criterion["questionSubmissions"]["0"]`
5. Find all code widget sections from the question revision (where `type == "code" and autoGrade and gradingConfigStorageKey`)
6. Validate that `widgetId` is in the list of code widget sections
7. Load student: `UserResource._lookup_one(id=str(target_criterion["studentId"]))`
8. Derive `exam_revision_id` from `target_criterion["reportRevisionId"]`
9. Get `criterion_evaluation_id = str(target_criterion["_id"])`
10. Three-phase execution:

```python
# Phase 1: Register target widget as PENDING
target_item = next(item for item in code_widgets if item["widget_id"] == widgetId)
await create_exam_grading_run(examAttemptId, questionId, widgetId)

# Phase 2: Pre-populate other widgets from their stamps
for item in code_widgets:
    if item["widget_id"] != widgetId:
        await prepopulate_widget_from_stamp(
            examAttemptId, questionId, item["widget_id"], criterion_evaluation_id,
        )

# Phase 3: Fire code execution for target widget only
await _fire_exam_code_execution(
    item=target_item,
    exam_attempt_id=examAttemptId,
    exam_revision_id=exam_revision_id,
    user=student_user,
    user_id=user_id,
    course_path=cohort_membership.course_path,
    cohort_path=cohort_membership.cohort_path,
)
```

### 3. `OpenLearningClient/src/resource/Exam/types.ts`

Add interface:

```typescript
export interface ExamRerunCodeGrading extends ExamResourceUpdateMethod {
  name: 'rerunCodeGrading';
  args: {
    cohortMembershipId: string;
    examAttemptId: string;
    questionId: string;
    widgetId: string;
  };
  return: void;
}
```

### 4. `OpenLearningClient/.../QuestionPreviewModal/component.tsx`

- Add `useQueryClient` import
- Add `EXAM` to resource names import
- Add `handleRerun` callback:

```typescript
const queryClient = useQueryClient();

const handleRerun = React.useCallback(
  async (widgetId: string): Promise<void> => {
    if (!evaluation?.cohortMembershipId || !attempt?._id || !questionId) return;
    await ResourceApi.update<ExamResource, ExamRerunCodeGrading>(
      EXAM,
      'rerunCodeGrading',
      {
        cohortMembershipId: evaluation.cohortMembershipId,
        examAttemptId: attempt._id,
        questionId,
        widgetId,
      }
    );
    await queryClient.invalidateQueries({
      queryKey: ['codeWidgetStamps', criteria?._id],
    });
  },
  [evaluation?.cohortMembershipId, attempt?._id, questionId, criteria?._id, queryClient]
);
```

- Pass `onRerun` and `widgetId` to `<CodeWidgetGrading>`:

```tsx
<CodeWidgetGrading
  stamp={codeWidgetStamps.find((s) => s.widgetId === q.id)}
  isLoading={isLoadingStamps}
  onRerun={() => handleRerun(q.id)}
/>
```

### 5. `OpenLearningClient/.../CodeWidgetGrading.tsx`

- Add `onRerun?: () => Promise<void>` prop
- Replace stub `handleRerun`:

```typescript
const handleRerun = async (): Promise<void> => {
  if (!onRerun) return;
  setIsRerunning(true);
  try {
    await onRerun();
  } catch (e) {
    console.error('Re-run failed', e);
  } finally {
    setIsRerunning(false);
  }
};
```

- Update button: `disabled={isRerunning || !onRerun}`

---

## New Files

None. Everything reuses existing pipeline endpoints and helpers.

---

## Endpoint Design

```
POST /exam/rerunCodeGrading
  Body: { cohortMembershipId, examAttemptId, questionId, widgetId }
  Auth: has_assessor_access on cohortMembership
  Returns: void (200 OK)

  Internal flow:
    1. Find criterion eval for the question
    2. Load question revision → find all code widget sections
    3. Validate widgetId is a valid code widget
    4. [Phase 1] create_exam_grading_run for target widget only
    5. [Phase 2] prepopulate_widget_from_stamp for each OTHER widget
    6. [Phase 3] _fire_exam_code_execution for target widget only

  Then existing /callback pipeline handles everything.
```

---

## Edge Cases

### Question with a single code widget
Phases 1 + 3 only (no Phase 2 needed — no other widgets to pre-populate). Simplest case.

### No existing stamp for a non-target widget
`prepopulate_widget_from_stamp` falls back to `score: {value: 0, max: 0}`. This means the non-target widget contributes zero to the aggregation — same as if it had timed out. Correct behaviour since it was never graded.

### Widget was never graded (first run still pending)
If the original grading is still in-flight (within Redis TTL), the admin shouldn't re-run — the pending set would conflict. The trigger endpoint should check if the widget is already PENDING in Redis and return 409 Conflict. Add a guard:

```python
existing_state = await get_exam_grading_state(examAttemptId, questionId, widgetId)
if existing_state and existing_state.get("status") == CodeRunStatus.PENDING:
    raise ResourceInvalidError("Widget is already being graded")
```

---

## Risks

1. **Concurrent re-run race** — Double-click: second `create_exam_grading_run` overwrites Redis state. First callback may find set already resolved. Safe but wasteful. The PENDING guard above mitigates this.

2. **Stamp invalidation timing** — After `invalidateQueries`, stamps refetch but code execution is async. UI shows stale stamps until grading completes. Acceptable for MVP. Optional: add `refetchInterval: 5000` while `isRerunning` is true.

3. **`questionSubmissions["0"]` shape** — Must match the `code_files` shape expected by `_fire_exam_code_execution`. Cross-reference with the original submit flow in `assess_exam_txn`.

4. **Import paths in `resource.py`** — `_fire_exam_code_execution` from `exam_submission_helper.py`, `create_exam_grading_run` and `prepopulate_widget_from_stamp` from `exam_grading_helpers.py`. Verify no circular imports.
