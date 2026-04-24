# Config File Validation on Upload

## Goal
Validate run/grading config files (JSON or ZIP) **before** they are uploaded to blob storage, so invalid configs are rejected immediately with user-facing errors — not silently stored to break a live exam later.

---

## Architecture Decisions

- **Single source of truth:** Validation logic (models + parsing) lives **only in `code_execution`**. No model duplication in `ol-async-engine`.
- **Validate before upload:** Client calls a validation endpoint before uploading to blob storage. If invalid → show error, block upload. If valid → proceed.
- **No changes to `question_data_cleanup`:** Question save flow is untouched.
- **`ol-async-engine` proxies to `code_execution`:** Client never calls `code_execution` directly.

---

## Flow

```
User selects config file in client
  → Client reads file as DataURL (base64)
  → POST /json/question/execute/validateCodeConfig/  (ol-async-engine)
      → forwards to POST /validate  (code_execution)
      → code_execution parses + validates against Pydantic models
  → 422? Show inline error, block upload
  → 200? Proceed with blob upload → save question as normal
```

---

## Implementation Plan

### 1. `code_execution` — New validation module

**New file:** `code_execution/validate/__init__.py` — empty

**New file:** `code_execution/validate/validator.py`

Add two pure validation functions:

```python
validate_run_config(file_bytes: bytes, filename: str) -> None
  - if .zip: open with zipfile, assert config.json in namelist,
             json.load, assert 'run' in config OR 'run' script in namelist,
             RunConfigModel(**data)
  - if .json: json.loads, assert config.get("run") is not None, RunConfigModel(**data)
  - raise ValueError with human-readable message on any failure

validate_grading_config(file_bytes: bytes, filename: str) -> None
  - if .zip: open with zipfile, assert config.json in namelist,
             json.load, GradingConfigModel(**data)
  - if .json: json.loads, GradingConfigModel(**data)
  - raise ValueError with human-readable message on any failure
```

Imports:
- `code_execution/run_config/config_model.py:ConfigModel as RunConfigModel`
- `code_execution/submission_config/config_model.py:ConfigModel as GradingConfigModel`

---

### 2. `code_execution` — Add auth dependency

**Modify:** `code_execution/auth.py`

Add a lightweight HMAC-only auth dependency (no user identity needed):

```python
async def ol_body_auth(
    request: Request,
    x_ol_signature: Annotated[str | None, Header(alias="x-ol-signature")] = None
) -> None:
    if not x_ol_signature:
        raise HTTPException(status_code=403, detail="Missing X-OL-Signature header")
    body = await request.body()
    if not verify_signature(body, x_ol_signature):
        raise HTTPException(status_code=401, detail="Invalid HMAC signature")
```

---

### 3. `code_execution` — Add `POST /validate` endpoint

**Modify:** `code_execution/main.py`

```python
class ValidateConfigRequest(BaseModel):
    file_b64: str        # base64-encoded file bytes (DataURL or raw base64)
    filename: str        # e.g. "config.json" or "config.zip"
    config_type: str     # "run" | "grading"

class ValidateConfigResponse(BaseModel):
    valid: bool
    error: Optional[str] = None

@app.post("/validate")
async def validate_config(
    payload: ValidateConfigRequest,
    _: None = Security(ol_body_auth)
) -> ValidateConfigResponse:
    # 1. Decode base64 (strip DataURL prefix if present)
    # 2. Route to validate_run_config or validate_grading_config
    # 3. Return ValidateConfigResponse(valid=True)
    # On ValueError: raise HTTPException(422, {"valid": False, "error": str(e)})
    # On unknown config_type: raise HTTPException(400, ...)
```

---

### 4. `ol-async-engine` — Add forwarding function

**Modify:** `ol-async-engine/resources/code_execution_resource/client.py`

```python
async def forward_config_validation(
    file_bytes: bytes, filename: str, config_type: str
) -> dict:
    import base64
    payload = {
        "file_b64": base64.b64encode(file_bytes).decode(),
        "filename": filename,
        "config_type": config_type,
    }
    body = json.dumps(payload).encode()
    signature = create_hmac_signature(body)
    headers = {"Content-Type": "application/json", "X-OL-Signature": signature}

    async with httpx.AsyncClient(timeout=30.0) as client:
        response = await client.post(
            f"{settings.CODE_EXECUTION_URL}/validate",
            content=body,
            headers=headers,
        )

    if response.status_code == 422:
        detail = response.json().get("detail", {})
        return {"valid": False, "error": detail.get("error", "Invalid config")}
    response.raise_for_status()
    return {"valid": True}
```

---

### 5. `ol-async-engine` — Add `validateCodeConfig` to QuestionResource

**Modify:** `ol-async-engine/resources/question_resource/resource.py`

```python
from resources.code_execution_resource.client import forward_config_validation

@update(staticAccessMethod=lambda _user: _user is not None, requiresCommit=False)
@staticmethod
async def validateCodeConfig(
    _user: UserResource,
    file_b64: str,
    filename: str,
    config_type: str,
) -> dict:
    # Guard: max 5MB raw before decode
    raw_b64 = file_b64.split(",")[-1] if "," in file_b64 else file_b64
    file_bytes = base64.b64decode(raw_b64)
    if len(file_bytes) > 5 * 1024 * 1024:
        raise ResourceInvalidError(response_data={"error": "Config file must be under 5MB"})
    return await forward_config_validation(file_bytes, filename, config_type)
```

Exposes: `POST /json/question/execute/validateCodeConfig/`

---

### 6. `OpenLearningClient` — Intercept file selection with validation

**Modify:** `src/web/components/Assessment/QuestionBank/QuestionBankDetail/CreateQuestion/QuestionSetup/QuestionItem/CodeRunner/Setup/component.tsx`

**Add state:**
```tsx
const [runConfigValidationError, setRunConfigValidationError] = useState<string | null>(null);
const [gradingConfigValidationError, setGradingConfigValidationError] = useState<string | null>(null);
const [isValidatingRunConfig, setIsValidatingRunConfig] = useState(false);
const [isValidatingGradingConfig, setIsValidatingGradingConfig] = useState(false);
```

**Add helper:**
```tsx
const validateConfigFile = async (
  file: File,
  configType: 'run' | 'grading',
  setError: (e: string | null) => void,
  setValidating: (v: boolean) => void,
  onValid: () => void
) => {
  setError(null);
  setValidating(true);
  const reader = new FileReader();
  reader.onload = async () => {
    const file_b64 = reader.result as string; // DataURL
    try {
      const result = await RESOURCE.execute('question', 'validateCodeConfig', {
        file_b64,
        filename: file.name,
        config_type: configType,
      });
      if (result?.result?.valid === false) {
        setError(result.result.error ?? 'Invalid configuration file');
      } else {
        onValid();
      }
    } catch {
      setError('Failed to validate configuration. Please try again.');
    } finally {
      setValidating(false);
    }
  };
  reader.readAsDataURL(file);
};
```

**Intercept `onFilesSelected` for run config:**
```tsx
onFilesSelected={(files) => {
  validateConfigFile(
    files[0],
    'run',
    setRunConfigValidationError,
    setIsValidatingRunConfig,
    () => runConfigUploaderRef.current?.startUploads(files)
  );
}}
```

**Intercept `onFilesSelected` for grading config:**
```tsx
onFilesSelected={(files) => {
  validateConfigFile(
    files[0],
    'grading',
    setGradingConfigValidationError,
    setIsValidatingGradingConfig,
    () => gradingConfigUploaderRef.current?.startUploads(files)
  );
}}
```

**Show inline errors** below each `PreviewDropZone` using existing error styling.

**Clear errors on `onClear`** for each respective drop zone.

---

## Files Summary

### New Files
| Repo | File |
|------|------|
| `code_execution` | `code_execution/validate/__init__.py` |
| `code_execution` | `code_execution/validate/validator.py` |

### Modified Files
| Repo | File | Change |
|------|------|--------|
| `code_execution` | `code_execution/auth.py` | Add `ol_body_auth` dependency |
| `code_execution` | `code_execution/main.py` | Add `POST /validate` endpoint |
| `ol-async-engine` | `resources/code_execution_resource/client.py` | Add `forward_config_validation()` |
| `ol-async-engine` | `resources/question_resource/resource.py` | Add `validateCodeConfig` static method |
| `OpenLearningClient` | `CodeRunner/Setup/component.tsx` | Add validation state, helper, intercept `onFilesSelected` |

---

## Error Messages

| Scenario | Message |
|----------|---------|
| ZIP missing `config.json` | `"Invalid grading config: ZIP is missing config.json"` |
| ZIP missing `run` definition | `"Invalid grading config: 'run' not defined and no run script found in ZIP"` |
| JSON missing `run` | `"Invalid config JSON: 'run' command must be defined"` |
| Pydantic schema mismatch | `"Invalid config format: <pydantic error details>"` |
| Blob fetch failure | `"Could not retrieve config: <error>"` |
| File too large | `"Config file must be under 5MB"` |

---

## Risks

1. **`RESOURCE.execute` may return jQuery Deferred** — if so, rewrite `validateConfigFile` using `.done()/.fail()` instead of `async/await`. Verify before implementing.

2. **`ol_body_auth` is HMAC-only** — `code_execution` is not exposed to the client directly. Never expose `CODE_EXECUTION_URL` to the client.

3. **Base64 size overhead** — base64 adds ~33%. The 5MB guard is applied on decoded bytes. A 5MB config encodes to ~6.7MB in transit — acceptable.

4. **`config.json` name is case-sensitive** on Linux ZIP extraction. Matches the existing `run_config_helper.py` assumption. Document this constraint.

5. **Client bypass** — direct API calls to `createQuestion`/`updateQuestion` with an invalid `gradingConfigStorageKey` will still succeed (no save-time grading config validation exists). Acceptable per requirements, but worth noting.

6. **`@update` + `@staticmethod` decorator order** — apply `@update(...)` outer, `@staticmethod` inner. Confirm this matches existing patterns in `question_resource/resource.py` (e.g. `runCodeDraftMode`).
