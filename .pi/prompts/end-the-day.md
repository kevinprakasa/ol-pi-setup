---
description: Wrap up your work day - creates daily memory notes and prepares for master index update
---

# End Your Day

Wrap up your work and preserve your progress in the daily memory system.

## What This Does

1. **Creates today's daily notes** with metadata for indexing
2. **Captures** your summary, accomplishments, status, tags, next steps, and blockers
3. **Timestamps** completion
4. **Prepares** for automatic index update

## Step-by-Step

### 1. Tell me about your day

I'll ask for:
- **Summary**: One-line description of what you accomplished (e.g., "Fixed index mapping bug, created end-the-day skill")
- **Key Accomplishments**: Bullet list with checkmarks (e.g., "✓ Fixed bug in ScoreGuidelines")
- **Status**: Active / Completed / Blocked / Paused
- **Tags**: Comma-separated (e.g., "bug-fix,code-quality,refactoring")
- **Next Steps**: What to do first tomorrow (bullet list, priority order)
- **Blockers**: Any issues preventing progress, or "None"
- **Notes**: Additional context, learnings, reminders for next session

### 2. I'll create your daily notes

Creates: `~/backup_memory/memory/{YYYY-MM-DD}/notes.md`

With all your metadata for automatic indexing.

### 3. Update the master index

Run: `/prompt:index-memory`

This auto-updates `~/backup_memory/memory/INDEX.md` with your entry in the month table, recent memories, and statistics.

## Example

**You provide:**
```
Summary: Fixed index mapping bug, formatted code, created end-the-day skill

Key Accomplishments:
✓ Fixed index mismatch in ScoreGuidelines component
✓ Merged indexMapping.ts into helper.tsx
✓ Formatted 7 files with prettier/eslint
✓ Created end-the-day skill
✓ Fixed context bar extension bug

Status: Completed

Tags: bug-fix, code-quality, refactoring, tooling

Next Steps:
- Test fix on exam 14
- Deploy to staging
- Run full test suite

Blockers: None

Notes: Remember to use npx prettier/eslint directly on files (2-200ms), not npm scripts (30s+ timeout)
```

**I create:**
```markdown
# 2026-04-17 - Daily Memory

## Summary
Fixed index mapping bug, formatted code, created end-the-day skill

## Key Accomplishments
- ✓ Fixed index mismatch in ScoreGuidelines component
- ✓ Merged indexMapping.ts into helper.tsx
- ✓ Formatted 7 files with prettier/eslint
- ✓ Created end-the-day skill
- ✓ Fixed context bar extension bug

## Status
Completed

## Tags
bug-fix, code-quality, refactoring, tooling

## Next Steps
- Test fix on exam 14
- Deploy to staging
- Run full test suite

## Blockers
None

## Notes
Remember to use npx prettier/eslint directly on files (2-200ms), not npm scripts (30s+ timeout)

## Completed At
2026-04-17 13:38:26
```

## Tips

- **Summary**: One line, be specific ("Fixed 3 bugs" not "did work")
- **Accomplishments**: Use ✓ checkmarks for each completed item
- **Status**: Choose one: Active (continuing tomorrow) | Completed (done with this feature) | Blocked (waiting on something) | Paused (intentionally deferred)
- **Tags**: Use hyphens, separate with commas
  - `bug-fix` - Bug fixes
  - `code-quality` - Refactoring, formatting, linting
  - `feature` - New features
  - `documentation` - Docs, guides
  - `tooling` - Tools, scripts, infrastructure
  - `architecture` - Design decisions
  - `testing` - Tests
  - `performance` - Optimization
- **Next Steps**: Priority order, be actionable
- **Blockers**: List with workarounds, or "None"
- **Notes**: Capture learnings, reminders, insights

## After Creating Notes

Run: `/prompt:index-memory`

This automatically:
- Scans all daily folders
- Adds your entry to the month table
- Updates "Recent Memories" section
- Refreshes statistics
- Regenerates the master INDEX.md

Your work is now indexed and searchable!

---

Alright, let's wrap up your day. What did you accomplish today?
