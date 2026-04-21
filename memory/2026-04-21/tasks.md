# Tasks - 2026-04-21

## Completed
- [x] Review grading flow from plan.md, identify major/minor issues → 13 findings documented (REVIEW-1 through REVIEW-13)
- [x] REVIEW-14: Fix 3-level scoring model mismatch — per-widget section patching instead of aggregation
- [x] REVIEW-2: Fix `code_files` always taking `user_submissions[0]` — now uses correct `interaction_index`
- [x] REVIEW-1: Fix TIMEOUT widgets contributing 0/0 — section metadata now in Redis state
- [x] REVIEW-5: Fix TOCTOU race — use `resolve_exam_grading_run` return value directly
- [x] REVIEW-10: Replace `print()` with `logger.debug()` in `exam_code_grading_helper.py`
- [x] REVIEW-12: Fix `Fraction` precision inconsistency — all use `limit_denominator()` default
- [x] Remove unused `aggregate_widget_results` function
- [x] Remove unused `is_question_all_widgets_resolved` function
- [x] Add `question_set_id` scoping to entire grading pipeline (Redis keys, callback URL, HMAC token, timeout message, criterion matching)
- [x] Fix `Fraction(float, int)` runtime crash in `resolve_exam_code_grading`
- [x] Update comments in `exam_grading_helpers.py` — Redis key patterns, examples, timing docs
- [x] Update unit tests for new function signatures (16 tests passing)
- [x] Add `TestQuestionSetIsolation` test class (3 tests for key collision prevention)
- [x] Fix variable ordering bug — `code_interaction_index` loop moved after `total_score`/`question_section_weights` computation
- [x] Replace defensive array padding with explicit `IndexError` for corrupted criterion data
- [x] Add TLDR sequence diagram to plan.md
- [x] Document all review findings in plan.md

## In Progress
- [ ] End-to-end testing of mixed widget scoring (MCQ + code in same question)
- [ ] End-to-end testing of question set collision scenario

## Planned
- [ ] REVIEW-4: Add concurrency guard on `resolve_exam_code_grading` (distributed lock or compare-and-swap)
- [ ] REVIEW-7: Add retry mechanism for `send_submission_webhook` failure
- [ ] REVIEW-8: Increase SAS token TTL from 30 min to match grading window (3600s)
- [ ] REVIEW-9: Add rate limiting on interactive Run button in ol-exam-engine
- [ ] REVIEW-13: Unit tests for `exam_code_grading_helper.py` scoring logic
- [ ] REVIEW-3: Handle expired Redis keys in timeout handler (force aggregation)
- [ ] Phase 2 stamps: Expose stamp lookup in exam review API (TODO-4/TODO-5)
- [ ] Admin re-grade action for failed/timed-out widgets (TODO-6)

## Blocked
- None

## Files Changed Today (8)
- `resources/code_execution_resource/exam_grading_helpers.py`
- `resources/code_execution_resource/client.py`
- `resources/exam_resource/helpers/exam_code_grading_helper.py`
- `resources/exam_resource/helpers/exam_submission_helper.py`
- `middlewares/webhook/main.py`
- `tasks/default/helpers/timeout_exam_code_grading_helper.py`
- `tasks/default/main.py`
- `tests/unit_tests/code_execution_resource/test_exam_grading_helpers.py`
