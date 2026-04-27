# Tasks - 2026-04-27

## Completed
- [x] Refactor CodeRunner Output tab — replaced textarea with read-only line-numbered layout (matching Input tab)
- [x] Fixed alignment: Input/Output now use identical 10px padding and 14px font
- [x] Fixed Output empty state: now shows 5 lines with matching dark background (#1c1c1c)
- [x] Fixed stdout/stderr coloring (red for errors, gray for output)
- [x] Added exit code display below output

## In Progress
- [ ] Fix HP-07: Default marking guidelines setting should be auto-grade
- [ ] Fix HP-17: Learner response files should be read-only + no marking guidelines on auto-grading
- [ ] Fix HP-19: Wrap IDE in container with dark grey stroke

## Planned
- [ ] 

## Blocked
- [ ] 

---

## From Test Plan - Code Response Type (2026-04-27)

### 🔴 FAIL - Must Fix Before Release

| ID | Issue | Source |
|----|-------|--------|
| **HP-08** | JS crash: `TypeError: Cannot read properties of null (reading 'match')` in `BottomPanel` when loading Code question in Question Bank editor | openlearningui |
| **EC-13** | Should return error when user selects auto grade but no grading config exists | ol-async-engine |
| **EC-14** | Empty submission shows warning but question shows as "not attempted" in gradebook | ol-exam-client |

### 🟠 Almost - Need Fixes

| ID | Issue |
|----|-------|
| **HP toggle (DONE)** | "Allow learners to rename, delete and add additional files" — default should be ON (FIXED: changed to `?? true`, needs deployment) |
| **HP toggle (DONE)** | "Allow learners to run their code" — default should be ON (FIXED: changed to `?? true`, needs deployment) |
| **HP-07 (DONE)** | Default marking guidelines setting should be auto-grade (FIXED: `autoGrade ?? true`, needs deployment) |
| **NEW: Run Config Required** | If "Allow learners to run their code" is checked, run config file MUST be uploaded before saving (FIXED: added validation state + disabled Save button) |
| **HP-17** | Learner response files should be read-only + no marking guidelines on auto-grading |
| **HP-07** | Default setting should be auto-grade |
| **EC-09** | Alignment tag field should only show learning outcomes (not other tags) |
| **HP-17** | Learner response and files should be read-only + not showing marking guidelines on auto-grading |
| **EC-08** | If no starting files configured, should "allow learners to edit/delete/rename" be checked? |

### 🎨 UI Polishes

| Location | Issue |
|----------|-------|
| **HP-02** | Remove duplicate buttons in red box — only need one set for IDE empty state |
| **HP-08** | Widget response title should be 14px semibold |
| **HP-08** | Output styling looks like big text area — remove the box? |
| **HP-19** | Wrap IDE and assessment guidelines in container with dark grey stroke |
| **HP-10** | Question type filter not showing "Code" yet |

### ♿ Accessibility (PENDING)

| ID | Issue |
|----|-------|
| **A-01** | File tabs outer div not keyboard focusable; options button (⋮) doesn't open menu on Enter/Space |
| **A-02** | After execution, focus drops to `<body>` — screen reader users won't know output appeared |
| **A-04** | Output area has no `aria-live` — screen readers won't announce output |
| **A-05** | "New file" button: contrast ratio 2.99 (white on `#1ea69e`) — fails WCAG AA (needs 4.5:1) |
| **A-08** | Command-line args field: `readOnly=true`, `focusable=false` — not keyboard reachable |
| **A-09** | Output textarea/pre have no `aria-live` — errors won't be announced |

### 📊 Summary

| Category | Count |
|----------|-------|
| FAIL | 3 |
| Almost | 6 |
| UI Polishes | 5 |
| Accessibility | 6 |

---

## Carried from 2026-04-21

### In Progress (from previous)
- [ ] End-to-end testing of mixed widget scoring (MCQ + code in same question)
- [ ] End-to-end testing of question set collision scenario

### Planned (from previous)
- [ ] REVIEW-4: Add concurrency guard on `resolve_exam_code_grading` (distributed lock or compare-and-swap)
- [ ] REVIEW-7: Add retry mechanism for `send_submission_webhook` failure
- [ ] REVIEW-8: Increase SAS token TTL from 30 min to match grading window (3600s)
- [ ] REVIEW-9: Add rate limiting on interactive Run button in ol-exam-engine
- [ ] REVIEW-13: Unit tests for `exam_code_grading_helper.py` scoring logic
- [ ] REVIEW-3: Handle expired Redis keys in timeout handler (force aggregation)
- [ ] Phase 2 stamps: Expose stamp lookup in exam review API (TODO-4/TODO-5)
- [ ] Admin re-grade action for failed/timed-out widgets (TODO-6)