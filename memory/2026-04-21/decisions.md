# Decisions - 2026-04-21

## Decision 1: Per-widget scoring instead of aggregation

**Context**: `resolve_exam_code_grading` was aggregating all code widget scores into a single number and applying it to the full question score. This destroyed non-code widget scores.

**Decision**: Eliminate aggregation entirely. Each code widget callback patches its own section index in the existing per-section arrays using the same weighted formula as `_get_score`.

**Rationale**: The exam scoring system has 3 levels (code_exec_score × widget_weight × question_exam_score). Aggregation collapses level 1 and loses per-widget identity, making it impossible to correctly handle mixed-widget questions (MCQ + code).

**Trade-off**: All widgets must be resolved before scoring fires (can't score incrementally per-widget). Accepted because incremental scoring would require read-modify-write on the criterion document with race conditions.

---

## Decision 2: Store section metadata in Redis at registration time

**Context**: At callback time, the handler needs to know `section_index`, `section_weight`, `total_question_weights`, and `question_exam_score` to compute the weighted score. This data comes from the question structure which is available at submit time but expensive to re-derive at callback time.

**Decision**: Bake section metadata into the Redis widget state at `create_exam_grading_run` time.

**Rationale**: Avoids re-querying the exam revision and re-parsing the question structure on every callback. The metadata is immutable for the lifetime of the grading run.

---

## Decision 3: Add question_set_id to all Redis keys and callback URLs

**Context**: The UI allows adding Question A as standalone AND in a question set that draws from the same bank. Without `question_set_id`, Redis keys collide and the criterion matching picks the wrong evaluation.

**Decision**: Thread `question_set_id` through every layer — Redis keys (`exam_grade:{attempt}:{qset}:{question}:{widget}`), callback URLs, HMAC tokens, timeout messages, and criterion matching.

**Rationale**: `questionId` alone is not unique within an exam when the same question appears in multiple contexts. `question_set_id` ("default" for standalone, ObjectId string for sets) provides the necessary disambiguation.

---

## Decision 4: Fail-fast on section_index out of bounds

**Context**: The per-section arrays are populated at submit time. A defensive `while` loop was padding arrays with zeros if `section_index` exceeded their length.

**Decision**: Replace with an explicit `IndexError` raise.

**Rationale**: Silent zero-padding masks bugs (corrupted criterion, mismatched question structure). An `IndexError` with a descriptive message surfaces the root cause immediately.
