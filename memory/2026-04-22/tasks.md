# Tasks - 2026-04-22

## Completed
- [x] Add `readOnly` prop to `CodeRunnerWidget` in OpenLearningUi
  - Added to `CodeRunnerWidgetProps` (types.ts)
  - Wired through `component.web.tsx` → `CodeEditorPane` → Monaco `options.readOnly`
  - Added `GradingMode` Storybook story
- [x] Use `readOnly` prop in OpenLearningClient evaluation mode
  - Set `readOnly={isEvaluating}` in `QuestionPreviewModal/Interaction/CodeRunner/component.tsx`

## In Progress
- [ ] End-to-end test of grading mode (verify Monaco non-editable in real exam attempt)

## Planned
- [ ] Add visual indicator in grading mode (e.g. "Viewing student submission" badge)
- [ ] Audit other interaction types (ShortAnswer, LongForm) for similar grading mode gaps
- [ ] Publish updated `@openlearningnet/openlearningui` package with `readOnly` prop

## From Meeting with Danny
- [ ] Check if timeout grading sets score to 0 or leaves it unmarked — should leave it **unmarked**
- [ ] Make sure LTI is not published if there are pending code executions
- [ ] Rename the scoring part in the exam grading helper

## Blocked
- None
