# Code Context: Stamp `resourceName` Convention — `examWidgetGrading` vs collection name

## Files Retrieved

1. `ol-async-engine/resources/exam_resource/helpers/exam_code_grading_helper.py` (lines 231–325) — Where stamp is written and queried; defines `_STAMP_RESOURCE_NAME = "examWidgetGrading"`
2. `ol-async-engine/resources/exam_resource/helpers/exam_attempt_helper.py` (lines 1008–1045) — Thin wrapper that exposes stamps; shows the shape of a stamp document
3. `ol-async-engine/resources/exam_resource/resource.py` (line 87) — `_resource_name: str = "exam"`
4. `ol-async-engine/resources/block_resource/resource.py` (lines 109, 800, 1239) — Reference: `_resource_name = "block"`, stamps use `"resourceName": self._resource_name` → `"block"`
5. `ol-async-engine/resources/collected_item_resource/resource.py` (line 51) — `_resource_name = "collection"`
6. `ol-exam-client/src/common/resourceNames.ts` (line 35) — `export const STAMP = 'stamp'` (MongoDB collection name)

## Key Code

### The convention across all other resources

Every resource that writes to a cross-resource collection (stamp, widgetIntegration, etc.) uses its **own `_resource_name`** as the `resourceName` discriminator:

```python
# block_resource/resource.py — line 109, 800
_resource_name: str = "block"
{"resourceName": self._resource_name, "resourceId": self.id}  # → "block"

# page_resource/collected_item_helper.py
{"resourceName": "page", "resourceID": page_id}
{"resourceName": "block", ...}

# ai_assistant_revision_resource/factories/page.py
{"resourceName": "page", ...}
{"resourceName": "block", ...}
```

All `_resource_name` values are the **plain collection/entity name**:

| Resource class                    | `_resource_name`          |
|----------------------------------|---------------------------|
| `ExamResource`                   | `"exam"`                  |
| `BlockResource`                  | `"block"`                 |
| `CollectedItemResource`          | `"collection"`            |
| `CourseResource`                 | `"course"`                |
| `QuestionBankResource`           | `"questionbank"`          |
| `WidgetIntegrationProviderResource` | `"widgetIntegrationProvider"` |

### What the exam stamp actually uses

```python
# exam_code_grading_helper.py — line 34, 240, 303
_STAMP_RESOURCE_NAME = "examWidgetGrading"

# Written as:
{
    "resourceName": "examWidgetGrading",   # ← breaks convention
    "resourceId":   "{exam_attempt_id}:{question_id}:{widget_id}",
    "provider":     "webhook",
    "data": { "status": ..., "score": ..., "feedback": ..., "visibility": "class" }
}
```

## Architecture

The `stamp` MongoDB collection is a **shared, generic collection** (like `widgetIntegration`). All resources that write to it disambiguate their documents using:
- **`resourceName`** → identifies which resource/entity type owns the stamp
- **`resourceId`** → the specific instance (can be composite, e.g. `attemptId:questionId:widgetId`)

The universal convention is that `resourceName` = the resource's own **`_resource_name`** string (the collection/entity name, short and lowercase camelCase). This is how `block`, `page`, `course`, etc. all do it.

## The Problem with `examWidgetGrading`

`"examWidgetGrading"` **breaks the established convention** in two ways:

1. **Not the resource name** — The exam resource's `_resource_name` is `"exam"`, not `"examWidgetGrading"`.
2. **Overly descriptive** — It encodes *what the stamp is for* (widget grading) rather than *who owns it* (exam). Other resources never put the "purpose" in the `resourceName` field — the purpose is inferred from context or stored in `data`.

### What it should be

Following the pattern, the stamp `resourceName` should simply be `"exam"`:

```python
_STAMP_RESOURCE_NAME = "exam"
# resourceId = "{exam_attempt_id}:{question_id}:{widget_id}"
```

The `resourceId` already contains enough information to scope down to widget-level grading. If there were a concern about collisions with other `"exam"` stamps in the future, the `resourceId` prefix (or a `provider` field) would be the right place to discriminate — **not** by overloading `resourceName` with a descriptive tag.

## Start Here

Start at `ol-async-engine/resources/exam_resource/helpers/exam_code_grading_helper.py` line 34 where `_STAMP_RESOURCE_NAME` is defined, then compare to `block_resource/resource.py` line 109 + 800 to see the expected pattern clearly. The fix is a one-liner: change `_STAMP_RESOURCE_NAME = "examWidgetGrading"` → `_STAMP_RESOURCE_NAME = "exam"` (and update any existing data migration if needed since data is already in MongoDB with the old key).
