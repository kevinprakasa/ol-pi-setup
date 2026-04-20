# Progress

## Status
Completed

## Tasks
- [x] Step 7.1 — Student Exam Review (ol-exam-client)
  - [x] Add `getCodeGradingResults` API function + types to `examApi.ts`
  - [x] Create `CodeGradingResultsPanel` component (polls for results, shows per-widget feedback)
  - [x] Integrate into `ExamSubmitModal` post-submission state
- [x] Step 7.2 — Admin Grading View (OpenLearningClient)
  - [x] Create `CodeWidgetFeedback` component for QuestionPreviewSidebar
  - [x] Update `QuestionPreviewSidebar` to show `CodeWidgetFeedback` for code questions
- [x] Phase 2 prerequisite backend already done (stamp persistence in ol-async-engine)
- [x] Backend: Add `get_all_code_widget_stamps_for_attempt` to `exam_code_grading_helper.py`
- [x] Backend: Add `GET /exam/codeResults/{exam_attempt_id}/` endpoint to ol-async-engine webhook app
- [x] Backend: Add `GET /examsubmission/{exam_id}/code-results/` proxy endpoint to ol-exam-engine

## Files Changed

### ol-async-engine
- `resources/exam_resource/helpers/exam_code_grading_helper.py` — Added `get_all_code_widget_stamps_for_attempt()` helper that fetches ALL stamps for an exam attempt (used by the new API endpoint)
- `middlewares/webhook/main.py` — Added `GET /exam/codeResults/{exam_attempt_id}/` endpoint; added import of `get_all_code_widget_stamps_for_attempt`

### ol-exam-engine
- `api/exam_submission/code_run_router.py` — Added `GET /examsubmission/{exam_id}/code-results/` endpoint that proxies stamp data from ol-async-engine to the exam client; added `generate_signature` import

### ol-exam-client
- `src/resource/Exam/api/examApi.ts` — Added `CodeWidgetGradingResult`, `CodeGradingResultsResponse` types and `getCodeGradingResults()` API function
- `src/components/CodeGrading/CodeGradingResultsPanel.tsx` — NEW: Component that polls for code grading results and displays per-widget score badge, status, and feedback items
- `src/containers/Modals/ExamSubmitModal.tsx` — Imports `CodeGradingResultsPanel`; displays it in post-submission modal; uses `examId` from `useExamContext()`

### OpenLearningClient
- `src/web/components/Assessment/QuestionBank/QuestionPreviewSidebar/CodeWidgetFeedback.tsx` — NEW: Fetches question widget IDs via `getQuestionPropsV1`, fetches stamps via `getStampsForResources`, displays per-widget status/score/feedback
- `src/web/components/Assessment/QuestionBank/QuestionPreviewSidebar/component.tsx` — Imports `CodeWidgetFeedback`; renders it after score row when question has code widgets

## Architecture

```
Student submits exam
      ↓
ExamSubmitModal (isExamSubmitted=true)
      ↓
CodeGradingResultsPanel (polls every 3s, up to ~2 min)
      ↓
GET /examsubmission/{exam_id}/code-results/  [ol-exam-engine]
      ↓  (HMAC-signed with ol_webhook_secret)
GET /webhook/exam/codeResults/{attempt_id}/ [ol-async-engine]
      ↓
MongoDB stamp collection
      ↓
Per-widget: status, score, feedback items displayed
```

```
Admin opens QuestionPreviewSidebar
      ↓
CodeWidgetFeedback (when question.widgets includes 'code')
      ↓
ResourceApi.lookup(QUESTION_BANK, 'getQuestionPropsV1') → widget IDs
      ↓
ResourceApi.lookup(STAMP, 'getStampsForResources', {resourceName: 'examWidgetGrading', resourceIds})
      ↓
Per-widget: StatusChip, ScoreDisplay, FeedbackBlock displayed
```

## Notes

- Authentication: ol-exam-engine signs `exam_attempt_id` with `ol_webhook_secret` (HMAC-SHA256) as the request body equivalent for the GET endpoint. ol-async-engine verifies with the same secret.
- The `CodeGradingResultsPanel` returns `null` gracefully when there are no code questions (empty results array), so it's safe to always render it in the submission modal.
- The `CodeWidgetFeedback` in OpenLearningClient uses `resourceName: 'examWidgetGrading' as 'collection'` cast to bypass the dispatcher's TypeScript type restriction — the backend accepts any string resourceName.
- Phase 2 (stamp persistence) was already implemented in a previous phase; Phase 7 builds on top of it.
