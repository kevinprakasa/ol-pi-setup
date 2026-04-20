# Daily Notes - 2026-04-14

## Summary
Heavy day of refactoring and design work on the exam code grading pipeline — primarily around the Stamp system for persisting per-widget grading results, fixing bugs in the evaluation write path, and planning the re-run integrations feature. Also debugged a Judge0 API subscription issue that was breaking interactive code runs.

---

## Key Points

### Stamp Design — Final Settled Design
- `resourceName = "examAttemptCriterionEvaluation"`, `resourceId = examAttemptCriterionEvaluationId` (not a compound string)
- `provider = "codeexecution"` (separate from `webhook` and `turnitin`)
- Top-level `widgetId` on `Stamp` document as upsert discriminator — one stamp per widget per criterion
- `data` reuses `WebhookStampData` shape (no separate `CodeExecutionStampData` class needed)
- Stamps are written **after all widgets resolve** (because `resourceId` = new criterion `_id` which only exists after `push_latest_exam_attempt_evaluation`)
- Rejected `examAttemptId` as `resourceId` — duplicate questions in an exam share the same `widgetId`, causing stamp collisions

### Bug Fix — Stamp Bound to Wrong Criterion
- `_write_widget_stamps` was using `target_criterion["_id"]` (the old **unmarked** criterion)
- Client always loads the **latest (marked)** criterion, so stamps were never found
- Fix: `push_latest_exam_attempt_evaluation` now returns `tuple[list[inserted_ids], attempt_evaluation_id]` via `insert_many` return value + `find_one_and_update(return_document=AFTER)`
- Use `inserted_criterion_ids[0]` as the stamp `resourceId` — guaranteed MongoDB-generated, no self-generated ObjectIds

### Bug Fix — autoMarked Idempotency Guard Removed (TODO-1)
- The `if target_criterion.get("autoMarked"): return` guard blocks re-run integrations
- Real duplicate protection is already upstream in Redis: `resolve_exam_grading_run` + `is_question_all_widgets_resolved` prevents `resolve_exam_code_grading` from being called twice
- Guard removed entirely

### Bug Fix — Fractional Score Calculation (TODO-2)
- `int(raw_score_max)` was truncating e.g. `0.5 → 0`, falling back to denominator `1`, producing wrong ratios
- Fixed: `Fraction(raw_score_value).limit_denominator(1000) / Fraction(raw_score_max).limit_denominator(1000)`

### Consolidation — get_question_widget_results Removed
- `get_question_widget_results` (returns `list`) and `get_question_widget_states_map` (returns `dict[widget_id, state]`) did the same thing
- Removed the list version; all callers use `.values()` when they need a list for aggregation

### CodeWidgetGrading Refactor
- No longer fetches its own stamps — parent `QuestionPreviewContent` fetches once per question
- Receives `stamp: CodeExecutionStamps | undefined`, `isLoading`, `onRerun` as props
- Re-run button wired up; UI layout matches original (shield icon + popover + re-run button)
- Fixed React hook order violation (`useQuery` was after early returns)

### Re-Run Integrations Plan
- Single-widget re-run (not all-widgets) via Redis pre-population from Stamps
- Phase 1: `create_exam_grading_run` for target widget (PENDING)
- Phase 2: `_prepopulate_widget_from_stamp` for other widgets (DONE, from Stamp data)
- Phase 3: `_fire_exam_code_execution` for target widget only
- Existing `/callback` pipeline handles everything — no new callback endpoint needed
- Saved to `rerun-integration-plan.md`

### Judge0 API Debug
- `KeyError: 'token'` in `code_execution/code_runner/service.py` — Judge0 RapidAPI returning 403 "You are not subscribed to this API"
- Fixed: added proper non-200 status check before accessing `response.json()["token"]`
- Root cause: RapidAPI subscription to `judge0-extra-ce` lapsed — needs renewal on RapidAPI dashboard (BASIC free plan)

### HTML Entity Encoding Bug (Unresolved)
- Code widget template files show `&lt;` and `&gt;` instead of `<` and `>`
- Confirmed: content is stored as HTML-encoded in MongoDB (write-time issue, not read-time)
- Not in `CodeInteraction.props()` or `question_data_cleanup` — escaping happens earlier in the save path
- Likely in OpenLearningEngine question save flow — investigation in progress

---

## Learnings

- MongoDB `insert_many` mutates dicts in-place to add `_id` in PyMongo, but this is not a documented guarantee in Motor (async wrapper) — safer to read from `InsertManyResult.inserted_ids`
- Self-generating ObjectIds (`ObjectId()`) is not best practice — prefer letting MongoDB assign and reading back via return values
- `$set: {data: {...}}` (full replace) eliminates stale optional fields on re-write; using individual `data.*` paths in `$set` creates a stale fields risk on re-run
- Duplicate questions in an exam share the same `widgetId` (it's a section ID on the question revision, not unique per exam position) — this killed the `examAttemptId` approach for stamp binding
- TODO-3 (Redis expired key handling in timeout handler) is risky for scoring: if the frozen registry is alive but some widget state keys expired, max scores would be underestimated — removed for now

---

## Observations

- The Stamp model in OpenLearningEngine was designed well — adding `codeexecution` as a new provider required minimal changes and fits naturally alongside `webhook`, `turnitin`, `typingdna`
- The `push_latest_exam_attempt_evaluation` function was returning `None` when it could have been returning useful data — small change, big benefit
- The re-run design (pre-populating from stamps instead of re-running all widgets) is elegant because it reuses the entire existing pipeline without any new callback endpoints

---

## Next Steps

- **Fix HTML entity encoding bug** — find where `initialFiles[].content` gets `html.escape()`'d in the OpenLearningEngine question save path and exclude code content from escaping
- **Implement re-run integrations** — follow `rerun-integration-plan.md`: new `rerunCodeGrading` method on `ExamResource` + context reconstruction from DB + `_prepopulate_widget_from_stamp` helper
- **Re-subscribe to Judge0 RapidAPI** — renew BASIC (free) plan subscription for `judge0-extra-ce` so interactive code runs work again
- **TODO-3 revisit** — handle expired Redis key in timeout handler properly once scoring implications are resolved
