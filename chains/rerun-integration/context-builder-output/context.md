# Context: Re-Run Integrations (Single Widget Admin Re-Grade)

## Key Files

### Backend

| File | Lines | Purpose |
|------|-------|---------|
| `resources/code_execution_resource/exam_grading_helpers.py` | 1–270 | Redis state management for async exam code grading |
| `resources/exam_resource/helpers/exam_submission_helper.py` | 600–800 | `_fire_exam_code_execution()` — builds callback URL, signs config, dispatches to code_execution service |
| `resources/exam_resource/helpers/exam_code_grading_helper.py` | 380–480 | Stamp persistence — writes `resourceName=examAttemptCriterionEvaluation, provider=codeexecution, widgetId=widget_id` |
| `resources/exam_resource/resource.py` | 84, 1815–1910 | `ExamResource` with `@update` decorator pattern; `manuallyAssessByAttemptId` at line ~1830 shows auth + transaction pattern |

### Frontend

| File | Lines | Purpose |
|------|-------|---------|
| `src/web/components/Assessment/QuestionBank/QuestionPreviewSidebar/CodeWidgetGrading.tsx` | 1–180 | **Has commented-out re-run button** with TODO — props: `stamp`, `isLoading` |
| `src/web/components/Assessment/QuestionBank/QuestionPreviewModal/component.tsx` | 230–290 | Fetches stamps via `useQuery(['codeWidgetStamps', criteria?._id])` — filters `provider === 'codeexecution'` |
| `src/resource/Exam/types.ts` | 1–400 | Pattern for `ExamResourceUpdateMethod` — add `ExamRerunCodeGrading` |

---

## Redis State Model

```
exam_grade:{attempt}:{qset}:{question}:{widget}  — per-widget {status, result, section_index, ...}
exam_grade_pending:{attempt}:{qset}:{question}    — SET of pending widget_ids
exam_grade_q_widgets:{attempt}:{qset}:{question} — SET of ALL widget_ids (frozen registry)
_EXAM_GRADE_REDIS_TTL = 3720
```

**Key functions in `exam_grading_helpers.py`:**
- `create_exam_grading_run()` — adds to BOTH pending set AND frozen registry
- `get_exam_grading_state()` — reads single widget state
- `get_question_widget_states_map()` — reads frozen registry → fetches all widget states
- `resolve_exam_grading_run()` — marks DONE, removes from pending, returns `True` if empty

---

## Stamp Structure

```python
# exam_code_grading_helper.py lines 410-420
{
    "resourceName": "examAttemptCriterionEvaluation",
    "resourceId": criterion_evaluation_id,
    "provider": "codeexecution",
    "widgetId": widget_id,
    "data": {
        "score": {"value": int, "max": int},
        "status": str,
        "feedback": list,
        "text": dict,
    }
}
```

---

## _fire_exam_code_execution() Shape

```python
# exam_submission_helper.py lines 690-740
async def _fire_exam_code_execution(
    item: dict,           # has: question_id, question_set_id, widget_id, code_files, grading_config_key
    exam_attempt_id: str,
    exam_revision_id: str,
    user: Any,
    user_id: str,
    course_id: str,
    course_path: str,
    cohort_path: str,
) -> None
```

---

## Pattern: Adding ExamResource Update Method

```python
# resource.py after manuallyAssessByAttemptId (line ~1830)
@staticmethod
@update(staticAccessMethod=lambda _user: _user is not None)
async def rerunCodeGrading(
    _user: UserResource,
    cohortMembershipId: str,
    examAttemptId: str,
    questionId: str,
    widgetId: str,
) -> None:
    # 1. has_assessor_access check
    # 2. load criterion evaluations → find target criterion by questionId
    # 3. load QuestionRevision → find all code widget sections
    # 4. validate widgetId is in code widget list
    # 5. Phase 1: create_exam_grading_run for target widget
    # 6. Phase 2: prepopulate_widget_from_stamp for other widgets
    # 7. Phase 3: _fire_exam_code_execution for target widget only
```

---

## Risks

1. **Concurrent re-run race** — Double-click could overwrite Redis state. Need PENDING guard check before Phase 1.
2. **questionSubmissions["0"]** — Must match shape expected by `_fire_exam_code_execution`. The `code_files` come from `item["code_files"]` which is `questionSubmissions["0"]` in the original flow.
3. **question_set_id** — Must be "default" for standalone questions. Verify this matches the pattern in `exam_submission_helper.py`.
4. **Import paths** — `_fire_exam_code_execution` from `exam_submission_helper`, `create_exam_grading_run` from `exam_grading_helpers`.

---

## Constraints

- Admin must have `assessor_access` on cohortMembership
- Widget must be a valid code widget (checked against question revision)
- Cannot re-run if widget is already PENDING (return 409)
- `question_set_id` is "default" for standalone questions
- Stamp query uses `criteria?._id` as `resourceId` (the criterion evaluation ID)