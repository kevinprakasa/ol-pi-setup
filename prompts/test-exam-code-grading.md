# Test: Exam Code Grading Flow (E2E Automation)

Automate the full end-to-end test of the exam code grading feature as described in `plan.md`.

This covers:
- Interactive code run during exam (ol-exam-client → ol-exam-engine → code_execution → poll)
- Exam submit triggering auto-grading (ol-exam-engine → ol-async-engine → code_execution → callback → evaluations updated)
- Admin viewing the auto-graded result

**Credentials:**
- Admin: super@ol.com / Passw0rd!
- Learner: learner1@test.com / Passw0rd!

**Key URLs:**
- OL main app: http://openlearning.test
- Exam client: http://exam.openlearning.test:5173
- ol-async-engine: http://127.0.0.1:8002
- ol-exam-engine: http://127.0.0.1:8888
- code_execution: http://127.0.0.1:5000

---

## Phase A — Preflight: Verify All Dev Servers Are Running

Run health checks for each service and report status in a table. Abort with a clear message if critical services are down:

```bash
echo "=== Service Health Checks ==="

check() {
  local name="$1" url="$2"
  if curl -sf --max-time 3 "$url" -o /dev/null 2>&1; then
    echo "✅ $name ($url)"
  else
    echo "❌ $name ($url) — NOT REACHABLE"
  fi
}

check "ol-async-engine"     "http://127.0.0.1:8002/health"
check "OL engine (main)"    "http://0.0.0.0:8008/health"
check "OpenLearningClient"  "http://openlearning.test"
check "ol-exam-engine"      "http://127.0.0.1:8888/health"
check "ol-exam-client"      "http://exam.openlearning.test:5173"
check "code_execution"      "http://127.0.0.1:5000/health"
```

If any critical service (ol-async-engine, ol-exam-engine, ol-exam-client, OL main) is down, stop and tell the user to run the `start-dev-servers.md` prompt first.

---

## Phase B — Admin: Find the Code Exam

Using Playwright MCP:

1. Open `http://openlearning.test` in a new browser tab.
2. Log in as admin: super@ol.com / Passw0rd!
3. Navigate to the institution's course management area. Try navigating to:
   `http://openlearning.test/institutiontestpath/courses/second-course/homepage/`
   (use `window.location.href` JS navigation if direct `goto` is aborted by the SPA).
4. Look for an exam activity on the course page that contains a code question with auto-grading.
   - The exam should have at least one code widget (`native/OpenLearning/CodeWidget`)
   - The code question should have `autoGrade: true` and a `gradingConfigStorageKey` set
5. Note the exam name and any relevant IDs shown in the UI.
6. Take a screenshot at this point.

If you cannot find a suitable exam, report to the user: "No code-grading exam found — please create one first via admin UI (Admin → Exam → add code question with autoGrade on)."

---

## Phase C — Learner: Take the Exam (Interactive Run + Submit)

Open a **new browser context** (incognito/fresh context) so admin and learner sessions don't conflict.

### C.1 — Login as Learner

1. Open `http://openlearning.test` in a new context.
2. Log in as: learner1@test.com / Passw0rd!
3. Navigate to the course: `http://openlearning.test/institutiontestpath/courses/second-course/homepage/`
4. Take a screenshot.

### C.2 — Start the Exam

1. Click the first "Start exam" button visible on the course page.
2. Wait for the exam client to load at `http://exam.openlearning.test:5173/...`
3. Take a screenshot when the exam is open.
4. Report: what questions/widgets are visible?

### C.3 — Interact with the Code Widget

1. Find the code editor widget on the exam page (Monaco editor / CodeRunnerWidget).
2. If there's existing code in the editor, note it. Otherwise type a simple test program, for example for Python:
   ```python
   print("Hello from test")
   x = 5 + 3
   print(f"Result: {x}")
   ```
3. Take a screenshot of the code widget.

### C.4 — Test Interactive Run (click "Run" button)

1. Click the "Run" button in the code widget.
2. Note the timestamp right before clicking.
3. Wait up to 30 seconds for the output to appear in the widget.
4. Take a screenshot of the output area.
5. **Simultaneously check the backend** — in a bash call, check ol-exam-engine logs or Redis for the run state:
   ```bash
   redis-cli keys "exam-code-run:*" 2>/dev/null | head -10
   # Also check recent ol-exam-engine logs if accessible
   tail -20 /tmp/exam-engine.log 2>/dev/null || echo "No log file found"
   ```
6. Report: Did the run succeed? What was the stdout/stderr? Did the poll cycle work?

### C.5 — Submit the Exam

1. Once the code is written (with or without running it first), find the "Submit" button.
2. Note the exact timestamp before submitting.
3. Click Submit. Confirm any confirmation dialog.
4. Wait for the submission confirmation page/message.
5. Take a screenshot.
6. Report the exam attempt ID if visible in the URL or response.

---

## Phase D — Backend Verification: Grading Pipeline

After submission, verify the grading pipeline triggered correctly. Run these checks using bash:

### D.1 — Check Redis for Pending Grading State

```bash
echo "=== Redis exam_grade keys ==="
redis-cli keys "exam_grade:*" 2>/dev/null
redis-cli keys "exam_grade_pending:*" 2>/dev/null
redis-cli keys "exam_grade_q_widgets:*" 2>/dev/null
echo "=== exam-code-run keys ==="
redis-cli keys "exam-code-run:*" 2>/dev/null
```

Expected: after submission you should see `exam_grade:{attempt_id}:{q_id}:{widget_id}` with status PENDING, and the attempt ID in `exam_grade_pending:{attempt_id}`.

### D.2 — Check ol-async-engine Received the Webhook

```bash
# Check ol-async-engine recent activity (last 30 lines of devserver output)
# Or ping health + check any accessible logs
curl -s http://127.0.0.1:8002/health 2>/dev/null
```

### D.3 — Check code_execution Received the Submission

```bash
# Hit code_execution status/health
curl -s http://127.0.0.1:5000/health 2>/dev/null
```

### D.4 — Wait for Grading Callback (up to 90 seconds)

Poll Redis every 5 seconds until the `exam_grade:*` keys change from PENDING to DONE or TIMEOUT:

```bash
for i in $(seq 1 18); do
  echo "--- Poll attempt $i ($(date '+%H:%M:%S')) ---"
  redis-cli keys "exam_grade_pending:*" 2>/dev/null
  # Print all exam_grade values
  for key in $(redis-cli keys "exam_grade:*" 2>/dev/null); do
    val=$(redis-cli get "$key" 2>/dev/null)
    echo "  $key → $val" | python3 -c "import sys,json; d=json.load(sys.stdin) if False else None; [print(l) for l in sys.stdin]" 2>/dev/null || echo "  $key → $val"
  done
  # Check if pending list is empty
  pending=$(redis-cli keys "exam_grade_pending:*" 2>/dev/null | wc -l)
  if [ "$pending" -eq "0" ]; then
    echo "✅ All grading jobs resolved!"
    break
  fi
  sleep 5
done
```

Report: Did grading complete (DONE) or timeout? How long did it take?

---

## Phase E — Admin: Verify Auto-Graded Results

### E.1 — Navigate to the Assessment Grading Table

1. Log in (or switch) to admin: super@ol.com / Passw0rd!
2. Navigate directly to the assess page:
   `http://openlearning.test/assessment/assess/?cohort=institutiontestpath%2Fcourses%2Fsecond-course%2Fcohorts%2Fclassof2022&course=institutiontestpath%2Fcourses%2Fsecond-course`
3. Take a screenshot of the full grading table.

### E.2 — Open the Learner's Exam Submission

1. In the table, find the row for **learner1@test.com** (profile: `learnerone-r8rk70`).
2. Find the column for the **Code exam zip configs** exam and click the cell/score for that learner.
3. Take a screenshot of the grading sidebar that opens.

### E.3 — Check Latest Attempt and Questions Tab

1. In the grading sidebar, open the **attempt selector** and choose the **latest attempt**.
2. Click the **Questions** tab.
3. Find the code question row and click its score cell.
4. Take a screenshot — it should show the auto-graded score (e.g. `100/100`) and **not** show a manual "Grade" button.

### E.4 — Verify Score and autoMarked

Look for:
- Score value displayed (e.g. `1/1` or `100/100` depending on config)
- Status indicator showing "Auto-graded" (not "Pending auto-grade" or "Grade" button)
- No UNMARKED state remaining

Take a screenshot. Report what you see.

### E.5 — API-Level Verification

```bash
mongosh openlearning --quiet --eval '
  db.examattemptcriterion_evaluation.find({}).sort({_id:-1}).limit(3).forEach(e => {
    print(JSON.stringify({id: e._id, autoMarked: e.autoMarked, questionScore: e.questionScore, markingStates: e.markingStates}));
  });
' 2>/dev/null || echo "mongosh not available"
```

---

## Phase F — Final Report

Summarise the test run:

| Step | Expected | Actual | Pass/Fail |
|------|----------|--------|-----------|
| Dev servers running | All 6 up | ... | ... |
| Code widget visible in exam | Yes | ... | ... |
| Interactive Run returned output | stdout non-empty | ... | ... |
| Exam submission accepted | 200/redirect | ... | ... |
| Redis PENDING keys created | exam_grade:* PENDING | ... | ... |
| code_execution received submission | 200 from /submission | ... | ... |
| Grading callback received | Redis DONE within 90s | ... | ... |
| Admin sees auto-graded score | score ≥ 0, autoMarked=true | ... | ... |

If any step fails, include:
- The exact error or unexpected value observed
- The relevant log snippet or screenshot
- A suggested fix or next debugging step based on `plan.md`
