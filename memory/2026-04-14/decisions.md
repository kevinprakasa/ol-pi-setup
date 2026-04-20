# Decisions - 2026-04-14

## 1. Stamp bound to `examAttemptCriterionEvaluationId` (not `examAttemptId`)

**Decision:** Use `resourceId = examAttemptCriterionEvaluationId`

**Rejected:** `resourceId = examAttemptId`

**Reason:** Duplicate questions in an exam share the same `widgetId` (it's a section ID on the question revision, not unique per exam position). Under `examAttemptId`, the upsert key `(resourceName, resourceId, provider, widgetId)` would collide — second question's stamp overwrites the first.

---

## 2. `widgetId` as top-level Stamp field (not in `data`)

**Decision:** `widgetId` lives as a top-level field on the `Stamp` document, not inside `data`

**Reasoning:**
- Using `data.widgetId` in the upsert filter conflicts with `$set: {data: {...}}` (MongoDB path conflict on insert)
- Using individual `data.*` paths in `$set` avoids the conflict but introduces stale optional field risk on re-run
- Top-level `widgetId` + full `data` object replacement = clean upsert, no stale fields, no path conflicts

---

## 3. `CodeExecutionStampData` removed — reuse `WebhookStampData`

**Decision:** Map `CODEEXECUTION` provider to `DocumentField(WebhookStampData)` in the PolymorphicField

**Reason:** `CodeExecutionStampData` was identical to `WebhookStampData` minus the `link` field. `link` could be useful for code results too. No need for a separate class — `data` is flexible.

---

## 4. Stamps written after all widgets resolve (not per-widget)

**Decision:** Write stamps in `resolve_exam_code_grading` after `push_latest_exam_attempt_evaluation`

**Rejected:** Writing stamps per-widget as each callback arrives

**Reason:** Stamps use `resourceId = criterionEvaluationId`. The new criterion `_id` only exists after `push_latest_exam_attempt_evaluation` runs (which only happens after all widgets resolve). Can't write stamps earlier without knowing the ID. Per-widget writing would require a different `resourceId` scheme.

---

## 5. `push_latest_exam_attempt_evaluation` returns `tuple[list[Any], Any]`

**Decision:** Return `(inserted_criterion_ids, attempt_evaluation_id)` instead of `None`

**Reason:** Callers need the new criterion `_id` to bind stamps to the correct (latest, marked) document. Reading back the ID from MongoDB's `InsertManyResult.inserted_ids` is cleaner than re-querying or self-generating ObjectIds.

---

## 6. TODO-1 autoMarked guard removed

**Decision:** Remove `if target_criterion.get("autoMarked"): return` guard from `resolve_exam_code_grading`

**Reason:** Guard was designed to prevent duplicate callback writes, but it would block re-run integrations (the criterion would already be `autoMarked=True` from the first run). Real duplicate protection is already upstream: `resolve_exam_grading_run` + `is_question_all_widgets_resolved` ensure `resolve_exam_code_grading` is only called once per grading flow.

---

## 7. Re-run triggers for single widget, not all widgets

**Decision:** Admin re-runs one specific widget; aggregation uses stamp-based pre-population for others

**Rejected:** Re-running all widgets for the question on every re-run button click

**Reason:** More precise (cheaper, faster, only re-grades what needs re-grading). Works by:
1. Registering target widget as PENDING in Redis
2. Pre-populating other widgets' Redis state from their existing Stamps (as DONE)
3. Existing aggregation pipeline handles the rest naturally

---

## 8. TODO-3 removed for now

**Decision:** Revert the expired-Redis-key handling in `timeout_exam_code_grading_helper.py`

**Reason:** If the frozen registry is alive but some individual widget state keys have expired, aggregation would use an incomplete widget set — understating `score.max` and inflating the student's ratio. The scoring correctness risk outweighs the rare edge case benefit. To be revisited with a proper solution.
