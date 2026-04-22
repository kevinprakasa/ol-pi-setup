# Daily Notes - $DATE

## Summary

<!-- Brief overview of the day -->

## Key Points

-
-
-

## Learnings

<!-- What did you learn today? -->

## Observations

<!-- Interesting things noticed -->

## Next Steps

<!-- What to focus on next -->

Question 1 (exam score: 10, sections: MCQ weight=5, code weight=3, code weight=2)
Student gets: MCQ correct, code 10/10, code 5/10 → total = 9.0/10

────────────────────────────────────────────────────────────────────────────────

┌────────────────────────┬──────────────────┬───────────────────────────────┬────────────────────────────────────────────────────────────────────────┐
│ Field │ Type │ Example │ What it is │
├────────────────────────┼──────────────────┼───────────────────────────────┼────────────────────────────────────────────────────────────────────────┤
│ questionScore │ float │ 9.0 │ Total marks earned for this question (sum of all sections) │
├────────────────────────┼──────────────────┼───────────────────────────────┼────────────────────────────────────────────────────────────────────────┤
│ questionRationalScores │ list[Fraction] │ [5, 3, 1] │ Per-section marks — one entry per interaction section │
├────────────────────────┼──────────────────┼───────────────────────────────┼────────────────────────────────────────────────────────────────────────┤
│ questionWeightScores │ list[float] │ [0.5, 0.3, 0.1] │ Per-section weight — (weighted_score × section_weight) / total_weights │
├────────────────────────┼──────────────────┼───────────────────────────────┼────────────────────────────────────────────────────────────────────────┤
│ markingStates │ list[MarkStatus] │ [correct, correct, incorrect] │ Per-section grading status — correct, incorrect, or unmarked │
├────────────────────────┼──────────────────┼───────────────────────────────┼────────────────────────────────────────────────────────────────────────┤
│ rationalMark │ Fraction │ 9/10 │ Question-level ratio — questionScore / question_exam_score │
├────────────────────────┼──────────────────┼───────────────────────────────┼────────────────────────────────────────────────────────────────────────┤
│ mark │ float (0-1) │ 0.9 │ Same ratio as float — used for weighted scoring across criteria │
├────────────────────────┼──────────────────┼───────────────────────────────┼────────────────────────────────────────────────────────────────────────┤
│ autoMarked │ bool │ true │ true if no sections are unmarked (all graded) │
└────────────────────────┴──────────────────┴───────────────────────────────┴────────────────────────────────────────────────────────────────────────┘

Relationships:

```
  questionScore       = sum(questionRationalScores)           = 5 + 3 + 1 = 9.0
  rationalMark        = questionScore / question_exam_score   = 9/10
  mark                = float(rationalMark)                   = 0.9
  autoMarked          = "unmarked" not in markingStates
```

Per-section formula (each index):

```
  questionWeightScores[i] = (weighted_score × section_weight) / total_weights
  questionRationalScores[i] = questionWeightScores[i] × question_exam_score
```

Where weighted_score is:

- MCQ/FITB: 1 (correct) or 0 (incorrect)
- Code: code_value / code_max (from Judge0)
