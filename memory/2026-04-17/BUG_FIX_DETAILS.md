# Bug Fix: Score Widget Index Mismatch

## Bug Description
The code item widget score displayed `0.333` instead of the correct score `1` when viewing a learner's assessment attempt.

## Root Cause
**Index mismatch** between frontend and backend data structures:

### Frontend (OpenLearningClient)
- `questionProps` array contains **all** question items:
  - Sections: HTML, TEXT, VIDEO, AUDIO widgets
  - Interactions: CODE, MULTIPLE_CHOICE, SHORT_ANSWER, etc.
- **Example**: `[HTML, CODE, TEXT, SHORT_ANSWER]`
- Index 1 = CODE widget

### Backend (ol-async-engine)  
- `questionWeightScores` array contains **only** interaction items
- Uses `index_mapping` to track the conversion
- **Example**: `[0.5, 1.0]` where index 0 = CODE, index 1 = SHORT_ANSWER
- Code at index 0 = `0.5` (but frontend tried to access index 1)

### The Problem
When rendering a CODE widget at `questionProps[1]`, the code was accessing `questionWeightScores[1]` (which was SHORT_ANSWER score) instead of `questionWeightScores[0]` (which is CODE score).

**Result**: Wrong score displayed (0.333 instead of 1)

## Solution Implemented

### 1. Merged Index Mapping into Helper
**File**: `OpenLearningClient/src/web/components/Assessment/QuestionBank/QuestionPreviewModal/helper.tsx`

Added two functions to the existing helper file:

```typescript
export function createQuestionIndexMapping(
  questionPropsArray: QuestionProps[]
): Record<number, number>

export function getMappedWeightScoreIndex(
  questionPartIndex: number,
  indexMapping: Record<number, number>
): number | undefined
```

- Filters `questionProps` using `QUIZ_WIDGET_IDENTIFIERS`
- Creates mapping: full index → interaction index
- Example: `{1: 0, 3: 1}` means CODE at index 1 maps to position 0 in interactions

### 2. Updated QuestionPreview Component
- Calculate `indexMapping` using `useMemo`
- Pass `mappedIndex` to `SectionInteractionRenderer`
- Renderer passes to individual interaction components

### 3. Updated Interaction Components
- **CodeRunner**: Pass `mappedIndex ?? index` to ScoreGuidelines
- **LongFormResponse**: Pass through evaluation and to ScoreGuidelines
- **MediaRecording**: Update type and pass in grading component

### 4. Updated Type Definitions
- Modified `QUESTION_RENDERER_MAPPING` to include `mappedIndex?`
- Updated `BaseMediaRecordingProps` type

## Files Changed

```
OpenLearningClient/
└── src/web/components/Assessment/QuestionBank/
    └── QuestionPreviewModal/
        ├── helper.tsx (UPDATED - added indexMapping functions)
        ├── component.tsx (UPDATED - add mapping logic)
        ├── renderers.tsx (UPDATED - type)
        └── Interaction/
            ├── CodeRunner/component.tsx (UPDATED)
            ├── LongFormResponse/component.tsx (UPDATED)
            └── MediaRecording/
                ├── GradingMode/component.tsx (UPDATED)
                └── common/types.ts (UPDATED)
```

## Testing

### Before Fix
- Assessment: exam 14
- Question: "manual evaluation code 1"
- Learner: "learner one"
- Displayed Score: **0.333 / 1** ❌
- Actual Score: 1.0 ✓

### After Fix
- Should display: **1 / 1** ✓
- Same as actual backend score

## Impact
- Fixes score display for all interaction types (CODE, LONG_FORM, MEDIA_RECORDING)
- Maintains backward compatibility
- Uses only `mappedIndex` when available, falls back to `index`

## Related Backend Code
- `ol-async-engine/resources/exam_resource/helpers/exam_attempt_helper.py`
  - Function: `manually_assess_criterion`
  - Uses same index_mapping logic
