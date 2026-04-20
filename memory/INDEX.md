# Daily Memory Index

Quick reference guide for all daily memory entries, tracking work progress, key decisions, and completed projects.

**Total Entries:** 1 | **This Week:** 1 | **This Month:** 1

---

## 📅 April 2026

| Date | Summary | Tasks | Status |
|------|---------|-------|--------|
| [2026-04-14](#2026-04-14) | Exam code grading stamp refactoring, bug fixes, re-run integrations planning | 21/27 ✓ | In Progress |

---

## 🔄 Recent Memories (Last 5 Days)

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
- **Latest Entry:** [2026-04-14](memory/2026-04-14/notes.md)
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
- **Judge0 RapidAPI subscription** — expired, needs renewal
- **TODO-3 (Redis timeout handling)** — scoring correctness risk (deferred until design clarified)

---

## 🎯 High-Level Progress

```
Exam Code Grading Feature:
  ├─ Phase 1: Stamp persistence (DONE)
  ├─ Phase 2: Client UI for results (DONE)
  ├─ Phase 3: Re-run integrations (PLANNED)
  └─ Issues: HTML encoding, Judge0 subscription

Code Execution Widget:
  ├─ Refactored grading logic (DONE)
  ├─ Fixed binding bugs (DONE)
  ├─ Fixed score calculation (DONE)
  └─ Status: Ready for re-run work
```

---

## 📊 Statistics

| Metric | Count |
|--------|-------|
| Total Daily Entries | 1 |
| Total Tasks Completed | 21 |
| Tasks In Progress | 1 |
| Tasks Planned | 5 |
| Decisions Made | 8 |
| Files Modified | 14+ |
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
