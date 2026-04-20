# Tasks - 2026-04-14

## Completed ✓

- [x] Refactor stamp `resourceName` → `examAttemptCriterionEvaluation`, `resourceId` → criterion eval ID
- [x] Add `codeexecution` provider to `StampProviders` in OpenLearningEngine
- [x] Add `widgetId` top-level field to `Stamp` model as upsert discriminator
- [x] Remove `CodeExecutionStampData` — reuse `WebhookStampData` instead
- [x] Update `StampResource.retrieve_resource_info` for `examAttemptCriterionEvaluation` resourceName
- [x] Update `StampResource.getAllowedStamps` visibility rules for `codeexecution` provider
- [x] Fix `_write_widget_stamps` bound to wrong (unmarked) criterion — now uses `inserted_criterion_ids[0]`
- [x] Update `push_latest_exam_attempt_evaluation` to return `tuple[list[inserted_ids], attempt_eval_id]`
- [x] Remove TODO-1 autoMarked idempotency guard (blocks re-run, redundant with Redis protection)
- [x] Fix TODO-2 fractional score calculation (replace `int(raw_score_max)` with `Fraction`)
- [x] Consolidate `get_question_widget_results` + `get_question_widget_states_map` → single map function
- [x] Remove step numbers from comments in `exam_code_grading_helper.py` and `timeout_exam_code_grading_helper.py`
- [x] Remove TODO-3 changes from timeout handler (scoring risk — revisit later)
- [x] Refactor `CodeWidgetGrading.tsx` — pure render component, fetching moved to parent
- [x] Fix React hook order violation in `QuestionPreviewModal/component.tsx`
- [x] Restore original UI layout in `CodeWidgetGrading` (shield icon, popover, re-run button)
- [x] Add `CodeExecutionStamps` type to `state.ts`, add to `Stamps` union
- [x] Fix `KeyError: 'token'` in `code_execution/code_runner/service.py` — proper non-200 error handling
- [x] Write re-run integrations plan → `rerun-integration-plan.md`
- [x] Remove `examWidgetGrading` legacy branch from `StampResource.retrieve_resource_info`
- [x] Update `plan.md` — stamp design, resourceName, resourceId, provider decisions

## In Progress

- [ ] **HTML entity encoding bug** — `&lt;`/`&gt;` in code widget template files stored encoded in MongoDB
  - Confirmed write-time issue (encoded in DB, not render-time)
  - Next: trace the question save path in OpenLearningEngine to find where `html.escape()` is applied to `initialFiles[].content`

## Planned (Tomorrow)

- [ ] Fix HTML entity encoding — exclude `initialFiles[].content` from HTML escaping in question save path
- [ ] Re-subscribe Judge0 RapidAPI BASIC plan (`judge0-extra-ce`) — interactive code runs broken
- [ ] Implement re-run integrations feature (follow `rerun-integration-plan.md`):
  - [ ] Add `_prepopulate_widget_from_stamp` helper to `exam_grading_helpers.py`
  - [ ] Add `rerunCodeGrading` method to `ExamResource` in `resource.py`
  - [ ] Add `ExamRerunCodeGrading` interface to `Exam/types.ts`
  - [ ] Wire `handleRerun` in `QuestionPreviewModal/component.tsx`
  - [ ] Update `CodeWidgetGrading.tsx` `onRerun` prop + async handler

## Blocked

- [ ] **Re-run integrations implementation** — waiting on HTML encoding fix first (cleaner to fix bugs before adding features)
- [ ] **TODO-3 (expired Redis key handling)** — blocked on resolving scoring correctness concern: if frozen registry alive but widget state keys expired, aggregate max is understated. Design decision needed before re-implementing.
