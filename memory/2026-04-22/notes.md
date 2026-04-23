# Daily Notes - 2026-04-22

## Summary

Added `readOnly` prop to `CodeRunnerWidget` in OpenLearningUi and wired it to evaluation mode in OpenLearningClient so graders can't accidentally edit student-submitted code.

---

## Key Points

- `CodeRunnerWidget` now accepts `readOnly?: boolean` prop (defaults `false`)
- Prop flows: `CodeRunnerWidgetProps` → `component.web.tsx` → `CodeEditorPane` → Monaco `options.readOnly`
- In OpenLearningClient, `isEvaluating` (from `useQuestionPreview()`) is used as the value — already existed, just needed to be passed
- Added `GradingMode` Storybook story in OpenLearningUi for visual testing
- Scoring data model notes (from earlier in the day) preserved below

---

## Learnings

- Monaco Editor accepts `readOnly` inside its `options` object — straightforward to wire
- OpenLearningClient's `CodeRunner` interaction component already had `isEvaluating` available via `useQuestionPreview()` — no new state needed
- The `readOnly` prop is intentionally separate from `settings.allowLearnerFileManagement` — file management and editor editability are orthogonal concerns

---

## Observations

- Grading mode already blocked file management and run code via `settings`, but the editor itself was still editable — this was a gap
- The Storybook story for "student — read only" (`settings` both false) is different from grading mode (`readOnly` true + can still run code) — important distinction

---

## Files Changed

### OpenLearningUi (`/Users/kevinprakasa/dev/OpenLearningUi`)
- `src/components/widgets/CodeRunner/types.ts` — added `readOnly?: boolean` to `CodeRunnerWidgetProps`
- `src/components/widgets/CodeRunner/component.web.tsx` — destructured `readOnly`, passed to `CodeEditorPane`
- `src/components/widgets/CodeRunner/components/CodeEditorPane/component.tsx` — accepted `readOnly`, passed to Monaco options
- `src/components/widgets/CodeRunner/component.stories.tsx` — added `GradingMode` story

### OpenLearningClient (`/Users/kevinprakasa/dev/ol-docker/engine/OpenLearningClient`)
- `src/web/components/Assessment/QuestionBank/QuestionPreviewModal/Interaction/CodeRunner/component.tsx` — added `readOnly={isEvaluating}` to `CodeRunnerWidget`

---

## Next Steps

- Test grading mode end-to-end in a real exam attempt to verify Monaco is non-editable
- Consider whether `readOnly` should also visually indicate read-only state (e.g. a banner/badge "Viewing student submission")
- Check if other interaction types (ShortAnswer, LongForm) have a similar gap in grading mode

---

## Exam Scoring Data Model (Reference Notes)

Question 1 (exam score: 10, sections: MCQ weight=5, code weight=3, code weight=2)
Student gets: MCQ correct, code 10/10, code 5/10 → total = 9.0/10

| Field | Type | Example | What it is |
|---|---|---|---|
| questionScore | float | 9.0 | Total marks earned for this question (sum of all sections) |
| questionRationalScores | list[Fraction] | [5, 3, 1] | Per-section marks — one entry per interaction section |
| questionWeightScores | list[float] | [0.5, 0.3, 0.1] | Per-section weight — (weighted_score × section_weight) / total_weights |
| markingStates | list[MarkStatus] | [correct, correct, incorrect] | Per-section grading status — correct, incorrect, or unmarked |
| rationalMark | Fraction | 9/10 | Question-level ratio — questionScore / question_exam_score |
| mark | float (0-1) | 0.9 | Same ratio as float — used for weighted scoring across criteria |
| autoMarked | bool | true | true if no sections are unmarked (all graded) |

```
questionScore       = sum(questionRationalScores)           = 5 + 3 + 1 = 9.0
rationalMark        = questionScore / question_exam_score   = 9/10
mark                = float(rationalMark)                   = 0.9
autoMarked          = "unmarked" not in markingStates
```

Per-section formula:
```
questionWeightScores[i] = (weighted_score × section_weight) / total_weights
questionRationalScores[i] = questionWeightScores[i] × question_exam_score
```

weighted_score: MCQ/FITB = 1 or 0 | Code = code_value / code_max (Judge0)
