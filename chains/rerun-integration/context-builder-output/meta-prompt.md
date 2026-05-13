# Meta-Prompt: Implement Re-Run Integrations (Single Widget Admin Re-Grade)

## Goal

Add a functional "Re-run integrations" button to `CodeWidgetGrading` that re-triggers code execution for a **single widget** and produces a correct aggregated score across all widgets for the question.

---

## Context / Evidence

- **Plan**: `/Users/kevinprakasa/dev/backup_memory/plans/rerun-integration-plan.md`
- **Redis model**: `exam_grading_helpers.py` lines 1–130 — three keys: grade, pending, frozen registry
- **Stamp structure**: `exam_code_grading_helper.py` lines 410–430 — `resourceName=examAttemptCriterionEvaluation, provider=codeexecution, widgetId`
- **Fire execution**: `exam_submission_helper.py` lines 690–740 — `_fire_exam_code_execution(item, ...)` with callback URL, config, payload
- **Endpoint pattern**: `resource.py` lines 1815+ — `@update` decorator with `has_assessor_access` check
- **UI components**: `CodeWidgetGrading.tsx` has commented-out re-run button; `QuestionPreviewModal/component.tsx` fetches stamps at `['codeWidgetStamps', criteria?._id]`

---

## Success Criteria

1. Admin clicks "Re-run integrations" on a single code widget → only that widget re-runs code execution
2. Other widgets in the same question are pre-populated from their Stamps (DONE state in Redis, NOT in pending set)
3. Aggregation reads all widget states → produces correct combined score
4. Stamps in MongoDB are updated via existing callback pipeline
5. UI refreshes via `invalidateQueries(['codeWidgetStamps', criteria._id])` → fresh results

---

## Hard Constraints

- Do NOT modify the callback endpoint `/webhook/exam/codeResult/{...}/callback`
- Do NOT modify `resolve_exam_grading_run` or `get_question_widget_states_map`
- Do NOT add non-target widgets to the pending set (prepopulate only writes frozen registry + DONE state)
- Auth required: `has_assessor_access` on cohortMembership
- Validate widgetId is a code widget before proceeding
- Return 409 if widget is already PENDING (concurrent re-run guard)
- TypeScript interface must extend `ExamResourceUpdateMethod`

---

## Suggested Approach

### Step 1: `exam_grading_helpers.py` — add `prepopulate_widget_from_stamp()`

```python
async def prepopulate_widget_from_stamp(
    exam_attempt_id: str,
    question_set_id: str,
    question_id: str,
    widget_id: str,
    criterion_evaluation_id: str,
) -> None:
    # 1. Query Stamp: {resourceName, resourceId, provider, widgetId}
    # 2. If found: result = stamp["data"]; else: result = {score: {value: 0, max: 0}}
    # 3. Write to Redis: {status: DONE, result} at grade key (NOT pending)
    # 4. SADD widget_id to frozen registry (exam_grade_q_widgets)
```

### Step 2: `resource.py` — add `rerunCodeGrading()` endpoint

```python
@update(staticAccessMethod=lambda _user: _user is not None)
async def rerunCodeGrading(_user, cohortMembershipId, examAttemptId, questionId, widgetId):
    # 1. Auth: has_assessor_access on cohortMembership
    # 2. Load criterion evaluations via get_student_latest_exam_attempt_criterion_evaluations
    # 3. Find target criterion by questionId → get questionRevisionId, reportRevisionId
    # 4. Load QuestionRevision → extract code widget sections (type=="code", autoGrade, gradingConfigStorageKey)
    # 5. Validate widgetId in list
    # 6. Load student UserResource by target_criterion["studentId"]
    # 7. Derive exam_revision_id = target_criterion["reportRevisionId"]
    # 8. Get criterion_evaluation_id = str(target_criterion["_id"])
    # 9. Extract code_files from target_criterion["questionSubmissions"]["0"]
    # 10. Phase 1: create_exam_grading_run(target_widget) — PENDING + frozen
    # 11. Phase 2: for each other widget → prepopulate_widget_from_stamp — DONE + frozen only
    # 12. Phase 3: _fire_exam_code_execution(target_item, ...) — dispatch only target
```

### Step 3: `types.ts` — add `ExamRerunCodeGrading` interface

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

### Step 4: `QuestionPreviewModal/component.tsx` — add `handleRerun`

```typescript
const queryClient = useQueryClient();

const handleRerun = React.useCallback(async (widgetId: string): Promise<void> => {
  if (!evaluation?.cohortMembershipId || !attempt?._id || !questionId) return;
  await ResourceApi.update<ExamResource, ExamRerunCodeGrading>(EXAM, 'rerunCodeGrading', {
    cohortMembershipId: evaluation.cohortMembershipId,
    examAttemptId: attempt._id,
    questionId,
    widgetId,
  });
  await queryClient.invalidateQueries({ queryKey: ['codeWidgetStamps', criteria?._id] });
}, [evaluation?.cohortMembershipId, attempt?._id, questionId, criteria?._id, queryClient]);

// Pass to CodeWidgetGrading:
// <CodeWidgetGrading stamp={...} onRerun={() => handleRerun(q.id)} />
```

### Step 5: `CodeWidgetGrading.tsx` — add `onRerun` prop

```typescript
export const CodeWidgetGrading: React.FC<{
  stamp: CodeExecutionStamps | undefined;
  isLoading?: boolean;
  onRerun?: () => Promise<void>;
}> = ({ stamp, isLoading, onRerun }) => {
  const [isRerunning, setIsRerunning] = React.useState(false);

  const handleRerun = async (): Promise<void> => {
    if (!onRerun) return;
    setIsRerunning(true);
    try { await onRerun(); }
    catch (e) { console.error('Re-run failed', e); }
    finally { setIsRerunning(false); }
  };

  // Uncomment button in PopoverAria:
  // <RunAgainButton onClick={handleRerun} disabled={isRerunning || !onRerun}>
  //   {isRerunning ? <Spinner /> : 'Re-run integrations'}
  // </RunAgainButton>
};
```

---

## Validation

1. **Single code widget question**: Re-run produces correct score (no Phase 2 needed)
2. **Multi-widget question**: Re-run aggregates correctly — target widget fires, others read from Stamp
3. **No existing stamp**: Falls back to zero score — correct behavior
4. **Concurrent re-run**: Returns 409 if widget already PENDING
5. **UI refresh**: Stamps update after callback completes

Run: `poetry run pytest` for backend, `npm run type-check` for frontend.

---

## Stop / Escalation Rules

- Stop if `_fire_exam_code_execution` import fails — check circular import paths
- Stop if `questionSubmissions["0"]` structure doesn't match `code_files` expected shape
- Ask if `question_set_id` is not always "default" for standalone questions
- Ask if there are multiple exam attempts per student that could confuse the criterion lookup