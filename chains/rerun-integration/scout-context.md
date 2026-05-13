

The file path appears to be a task directive. Here's my focused output:

---

# Scout Context: Re-Run Integrations Feature

## Files Retrieved

### 1. `ol-async-engine/resources/code_execution_resource/exam_grading_helpers.py` (lines 1-270)
**Purpose:** Redis state management for exam code grading

**Key functions:**
- `_grade_key()` → `exam_grade:{attempt}:{qset}:{question}:{widget}`
- `_pending_key()` → `exam_grade_pending:{attempt}:{qset}:{question}`
- `_question_widgets_key()` → `exam_grade_q_widgets:{attempt}:{qset}:{question}` (frozen registry)
- `create_exam_grading_run()` - registers widget PENDING, adds to pending set AND frozen registry
- `get_exam_grading_state()` - reads widget state
- `resolve_exam_grading_run()` - marks DONE, removes from pending, returns True if empty
- `get_question_widget_states_map()` - reads frozen registry, fetches all widget states

**Constants:** `_EXAM_GRADE_TTL=3600`, `_EXAM_GRADE_REDIS_TTL=3720`

### 2. `ol-async-engine/resources/exam_resource/helpers/exam_submission_helper.py` (lines 640-740)
`_fire_exam_code_execution()` - builds callback URL, signs config, sends to code_execution service

### 3. `ol-async-engine/resources/exam_resource/resource.py` (lines 84, 1815+)
`ExamResource` class. Pattern: `manuallyAssessByAttemptId` uses `@update` decorator with `has_assessor_access` auth

### 4. `ol-async-engine/resources/exam_resource/helpers/exam_code_grading_helper.py` (lines 400-430)
Stamp persistence: `resourceName="examAttemptCriterionEvaluation"`, `provider="codeexecution"`, `widgetId=widget_id`

**Stamp structure:**
```python
{
    "resourceName": "examAttemptCriterionEvaluation",
    "resourceId": criterion_evaluation_id,
    "provider": "codeexecution",
    "widgetId": widget_id,
    "data": {"score": {"value": int, "max": int}, "status": str, "feedback": [...]}
}
```

### 5. `OpenLearningClient/.../CodeWidgetGrading.tsx`
- Props: `stamp`, `isLoading`
- **Has commented-out re-run button** (TODO: re-enable later)

### 6. `OpenLearningClient/.../QuestionPreviewModal/component.tsx`
- Fetches stamps via `useQuery(['codeWidgetStamps', criteria?._id])`
- Filters: `provider === 'codeexecution'`
- Passes `stamp={codeWidgetStamps.find((s) => s.widgetId === q.id)}`

### 7. `OpenLearningClient/src/resource/Exam/types.ts`
Pattern for update methods - add `ExamRerunCodeGrading extends ExamResourceUpdateMethod`

---

## Architecture

### Single Widget Re-Run Flow
```
Admin clicks "Re-run" on W1 (of W1+W2)
→ Phase 1: create_exam_grading_run(W1) → PENDING in Redis + frozen
→ Phase 2: prepopulate_widget_from_stamp(W2) → DONE from Stamp → frozen ONLY (not pending)
→ Phase 3: _fire_exam_code_execution(W1) → dispatch only W1
→ Callback for W1 → resolve → aggregate W1 + W2 → correct combined score
```

---

## Files to Modify

| File | Change |
|------|--------|
| `exam_grading_helpers.py` | Add `prepopulate_widget_from_stamp()` |
| `resource.py` | Add `rerunCodeGrading()` endpoint |
| `types.ts` | Add `ExamRerunCodeGrading` interface |
| `QuestionPreviewModal/component.tsx` | Add `handleRerun` + invalidate queries |
| `CodeWidgetGrading.tsx` | Add `onRerun` prop + button |

---

## Start Here

1. **Redis model:** `exam_grading_helpers.py` lines 1-130
2. **Endpoint pattern:** `resource.py` - `manuallyAssessByAttemptId` at line 1815
3. **Stamp persistence:** `exam_code_grading_helper.py` lines 400-430
4. **UI component:** `CodeWidgetGrading.tsx` - uncomment re-run button