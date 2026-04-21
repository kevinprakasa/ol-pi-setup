# Daily Memory Index

Quick reference guide for all daily memory entries, tracking work progress, key decisions, and completed projects.

**Total Entries:** 2 | **This Week:** 2 | **This Month:** 2

---

## 📅 April 2026

| Date | Summary | Tasks | Status |
|------|---------|-------|--------|
| [2026-04-21](#2026-04-21) | Critical scoring model fix, question_set_id scoping, grading pipeline refactor | 17/19 ✓ | In Progress |
| [2026-04-14](#2026-04-14) | Exam code grading stamp refactoring, bug fixes, re-run integrations planning | 21/27 ✓ | In Progress |

---

## 🔄 Recent Memories (Last 5 Days)

### 2026-04-21
**Critical Scoring Model Fix & Question Set Scoping**

**Summary:** Deep review of the exam code widget grading flow uncovered a critical scoring bug (REVIEW-14): `resolve_exam_code_grading` treated code widget scores as the entire question score, destroying MCQ/FITB scores. Refactored to per-widget section patching using the same 3-level weighted formula as `_get_score`. Added `question_set_id` throughout the entire pipeline to prevent Redis key collisions when the same question appears standalone and in a question set.

**Key Accomplishments:**
- ✓ Fixed REVIEW-14: 3-level scoring model (code_exec × widget_weight × question_exam_score)
- ✓ Fixed REVIEW-1, 2, 5, 10, 12: TIMEOUT scores, code_files indexing, TOCTOU race, print→logger, Fraction precision
- ✓ Removed `aggregate_widget_results` — fundamentally wrong approach
- ✓ Added `question_set_id` to Redis keys, callback URLs, HMAC tokens, timeout messages, criterion matching
- ✓ Section metadata (section_index, weights, exam_score) stored in Redis at registration time
- ✓ 16 unit tests passing, 3 new question-set isolation tests
- ✓ Fixed `Fraction(float, int)` runtime crash

**Files Modified:** 8 files across ol-async-engine

**Decisions Made:** 4 (per-widget scoring, Redis metadata, question_set_id scoping, fail-fast IndexError)

**Status:** `In Progress` — E2E testing needed, concurrency guard still open

**Tags:** `bug-fix`, `architecture`, `refactoring`, `scoring`, `exam-grading`

**Links:**
- [Notes](memory/2026-04-21/notes.md) | [Tasks](memory/2026-04-21/tasks.md) | [Decisions](memory/2026-04-21/decisions.md)

### 2026-04-14
**Exam Code Grading Pipeline Refactoring & Architecture**

**Summary:** Heavy refactoring of the Stamp system for persisting per-widget code grading results. Fixed critical bugs in the evaluation write path and designed the upcoming re-run integrations feature. Debugged a Judge0 API subscription issue.

**Key Accomplishments:**
- ✓ Settled final Stamp design: `resourceName="examAttemptCriterionEvaluation"`, `resourceId=criterionEvalId`, `provider="codeexecution"`
- ✓ Fixed stamp binding bug (was bound to unmarked criterion, client always loads marked)
- ✓ Updated `push_latest_exam_attempt_evaluation` to return criterion IDs and attempt eval ID
- ✓ Removed TODO-1 autoMarked guard blocking re-run feature
- ✓ Fixed TODO-2 fractional score calculation (int truncation issue)
- ✓ Consolidated duplicate Redis helpers
- ✓ Refactored `CodeWidgetGrading.tsx` to pure render component
- ✓ Debugged & fixed Judge0 API error handling (non-200 status check)

**Files Modified:** 14 core files across ol-async-engine, OpenLearningEngine, OpenLearningClient

**Decisions Made:** 8 major architectural decisions documented in `decisions.md`

**Status:** `In Progress` — HTML entity encoding bug unresolved, re-run implementation planned for next session

**Tags:** `architecture`, `refactoring`, `bug-fixes`, `design`, `exam-grading`

**Links:**
- [Notes](memory/2026-04-14/notes.md) | [Tasks](memory/2026-04-14/tasks.md) | [Decisions](memory/2026-04-14/decisions.md)
- Related: [Re-run Integration Plan](../plans/rerun-integration-plan.md)

---

## 📌 Quick Navigation by Topic

### Exam Code Grading System
- **Latest Entry:** [2026-04-21](memory/2026-04-21/notes.md)
  - Critical scoring model fix (REVIEW-14)
  - question_set_id scoping across entire pipeline
  - Per-widget section patching replaces aggregation
- **Previous:** [2026-04-14](memory/2026-04-14/notes.md)
  - Stamp architecture finalized
  - Bug fixes in evaluation write path
  - Re-run integrations planned
  
### Completed Projects
- None yet (system just started)

### Active Projects
- **Exam Code Grading Pipeline** — Stamp persistence, re-run integrations, widget aggregation
- **Code Widget Grading UI** — Client-side display of per-widget results

### Blocked Items
- **HTML entity encoding in code templates** — write-time issue in OpenLearningEngine save path (investigation in progress)
- **REVIEW-4 (concurrency guard)** — no distributed lock on `resolve_exam_code_grading`, two concurrent last-widget callbacks could both trigger it
- **TODO-3 / REVIEW-3 (Redis timeout handling)** — expired keys cause degenerate resolution

---

## 🎯 High-Level Progress

```
Exam Code Grading Feature:
  ├─ Phase 1: Stamp persistence (DONE)
  ├─ Phase 2: Client UI for results (DONE)
  ├─ Phase 3: Re-run integrations (PLANNED)
  ├─ Scoring model fix (DONE — 2026-04-21)
  ├─ question_set_id scoping (DONE — 2026-04-21)
  └─ Issues: concurrency guard, SAS TTL, rate limiting

Code Execution Widget:
  ├─ Refactored grading logic (DONE)
  ├─ Fixed binding bugs (DONE)
  ├─ Fixed score calculation (DONE)
  ├─ Per-widget section patching (DONE — 2026-04-21)
  └─ Status: E2E testing needed
```

---

## 📊 Statistics

| Metric | Count |
|--------|-------|
| Total Daily Entries | 2 |
| Total Tasks Completed | 38 |
| Tasks In Progress | 3 |
| Tasks Planned | 8 |
| Decisions Made | 12 |
| Files Modified | 22+ |
| Open Issues | 3 |

---

## 🔧 How to Use This Index

1. **Find a specific day**: Browse the month tables above, click the date
2. **Track progress**: Check "Active Projects" and completion percentages
3. **Review decisions**: Each day links to `decisions.md` documenting major choices
4. **Check blockers**: "Blocked Items" section lists what's waiting on what
5. **Navigate by topic**: "Quick Navigation" groups related work across days

## 📝 Updating This Index

When you create a new daily entry:
1. Run `./create_daily_memory.sh YYYY-MM-DD` to scaffold the day
2. Edit `memory/YYYY-MM-DD/notes.md`, `tasks.md`, `decisions.md`
3. Update this INDEX.md:
   - Add a new row to the month table
   - Add a summary block in "Recent Memories"
   - Update "Statistics" section
   - Move old entries out of "Recent Memories" once 5+ entries exist

---

## 🎨 Status Legend

| Status | Meaning |
|--------|---------|
| `In Progress` | Active work, ongoing decisions |
| `Completed` | All tasks done, no open issues |
| `Archived` | Finished project, moved to past reference |
| `Blocked` | Waiting on external dependency or decision |
| `Paused` | Intentionally deferred, may resume later |

---

## 📚 Related Documentation

- **Master Plan:** See `plans/plan.md` for overall roadmap
- **Progress Tracking:** `plans/progress.md` for completed phases
- **Re-Run Design:** `plans/rerun-integration-plan.md` for next feature
