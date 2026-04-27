# Daily Notes - 2026-04-27

## Summary
Fixed HP toggle defaults (allowLearnerFileManagement, allowLearnerRunCode now default to true). Verified checkboxes in Question Bank setup - checkboxes currently showing as unchecked (expected since code needs deployment). Refactored CodeRunner Output tab.

## Code Changes Made
### HP Toggle Defaults (DONE)
- **OpenLearningClient**: `CodeRunnerSetup/component.tsx` - Changed `allowLearnerFileManagement ?? false` → `?? true`, same for `allowLearnerRunCode`
- **ol-exam-client**: `CodeRunner/component.tsx` - Already had `?? true` for both settings
- Need deployment to verify

### Previous Fixes
- BottomPanel Output tab refactor (openlearningui)
- Widget response title styling (14px semibold)

## Browser Verification Results
- Navigated to Assessment > Question Banks > Default bank > Create question > Code response type
- Opened Code widget editor
- Checked checkboxes with `page.locator('input[type="checkbox"]').all()` → returned `[false, false]`
- Checkboxes are unchecked - expected since code changes haven't been deployed
- Code fix was verified in src file: `checked={formState.allowLearnerFileManagement ?? true}`

## Learnings
- Storybook hot-reload reflects changes immediately — no need to restart
- Playwright MCP can interact with Storybook iframes via `page.locator('iframe[title="storybook-preview-iframe"]').contentFrame()`

## Observations
- openlearningui components use Tailwind with custom `ui-` prefix pattern
- Confluence page ID: 2554363905, spaceId: 98522
- Test plan shows 3 FAIL items, 6 Almost items, 5 UI polishes, 6 accessibility issues

## Next Steps
1. Deploy OpenLearningClient code to verify HP toggle defaults
2. Fix HP-07: Default marking guidelines setting should be auto-grade (`autoGrade ?? true`)
3. Fix HP-17: Learner response files should be read-only + no marking guidelines on auto-grading
4. Fix HP-19: Wrap IDE in container with dark grey stroke
5. Fix HP-10: Question type filter not showing "Code"

## Related
- Test Plan: https://openlearning.atlassian.net/wiki/spaces/OPENLEARNI/pages/2554363905/Test+Plan+-+Code+Response+Type
- Storybook running on port 7007