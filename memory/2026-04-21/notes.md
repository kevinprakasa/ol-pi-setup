# Daily Notes - 2026-04-21

## Summary

Deep review and major refactor of the exam code widget grading flow in ol-async-engine. Found and fixed critical scoring bugs where code widget results were incorrectly applied to the full question score, ignoring the 3-level weighted scoring hierarchy. Also added `question_set_id` scoping throughout the entire grading pipeline to prevent key collisions when the same question appears standalone and inside a question set.

## Key Points

- **REVIEW-14 (Critical)**: `resolve_exam_code_grading` was treating code widget scores as the entire question score, destroying non-code widget scores (MCQ, FITB etc.) that were already graded at submit time. Fixed by patching per-section arrays instead of overwriting the whole criterion.
- **3-level scoring model**: `code_exec_score × (widget_weight / total_weights) × question_exam_score`. Both `_get_score` (submit time) and `_compute_widget_section_score` (callback time) now follow the same formula.
- **Section metadata in Redis**: `section_index`, `section_weight`, `total_question_weights`, `question_exam_score` stored at registration time so callbacks can score without re-deriving the question structure.
- **Removed `aggregate_widget_results`**: Aggregation was fundamentally wrong — it collapsed per-widget identity. Each widget is now scored individually into its own section index.
- **`question_set_id` scoped everywhere**: Redis keys, callback URLs, HMAC tokens, timeout messages, criterion matching — all now include `question_set_id` to prevent collisions when the same question appears in multiple contexts within an exam.
- **TOCTOU race fix (REVIEW-5)**: Callers now use the return value of `resolve_exam_grading_run` / `mark_exam_grading_timeout` directly instead of calling a separate `is_question_all_widgets_resolved`.
- **Removed `is_question_all_widgets_resolved`**: Unused after the TOCTOU fix.
- **`Fraction` consistency**: All `limit_denominator()` calls now use the default (10^6), matching `_get_score`. Fixed a runtime crash where `Fraction(float, int)` was used — two-arg `Fraction` requires both to be `Rational`.

## Learnings

- **Redis SADD/SREM atomicity**: Single Redis commands can't be interleaved by other clients (Redis is single-threaded). A JSON list read-modify-write pattern creates a race window between GET and SET. `SADD`/`SREM` eliminate this.
- **`Fraction(a, b)` requires Rational**: Two-arg `Fraction` constructor requires both args to be `int` or `Fraction`. Passing a `float` raises "both arguments should be Rational instances". Use `Fraction(float_val) / int_val` instead.
- **`*` in function signatures**: Forces all subsequent parameters to be keyword-only, preventing positional arg mixups when multiple params share the same type.

## Observations

- The exam UI allows adding Question A as standalone AND including a question set from a bank that contains Question A — this is a real user scenario, not just theoretical.
- Question sets assign the same score to every question in the set (`ExamQuestionSet.score`), unlike standalone questions which each have their own score.
- `get_student_latest_exam_attempt_criterion_evaluations` deduplicates by `(questionSetId, questionId)`, so the two instances of the same question are distinct criteria — but the old code only matched by `questionId`, picking the wrong one.
- The `print()` statements in production webhook handlers were leaking student code and scores to stdout.

## Next Steps

- **Test end-to-end**: Submit an exam with mixed widgets (MCQ + code) and verify scores are correct
- **Test question set scenario**: Same question as standalone + in a set, verify both grade independently
- **REVIEW-4 (concurrency guard)**: `resolve_exam_code_grading` still has no distributed lock — two concurrent callbacks for the last widget could both trigger it
- **REVIEW-7 (retry on webhook failure)**: No retry mechanism for `send_submission_webhook` — transient failures → timeout → 0 score
- **REVIEW-8 (SAS TTL)**: Grading config SAS URL is 30 min but grading window is 1 hour
- **REVIEW-9 (rate limiting)**: No rate limit on interactive Run button in ol-exam-engine
- **Unit tests for `exam_code_grading_helper.py`**: The scoring logic itself has no tests yet
