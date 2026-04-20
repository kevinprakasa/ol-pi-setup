# Pi Memory System Integration

This project has a **daily memory system** integrated with pi. Here's how it works:

## 🎯 Automatic Reminders

When you start working in this project, pi will:

1. **Check for today's memory folder** (`memory/YYYY-MM-DD/`)
2. **Show a confirmation dialog** asking if you want to update memory
3. **Display memory status** in the editor widget showing last update time

The reminder extension is in `.pi/extensions/memory-reminder.ts` and is automatically loaded by pi.

## 📝 Memory Commands

Use these pi commands to manage your daily memory:

### Create a New Daily Folder
```bash
./create_daily_memory.sh 2026-04-15
```

Or let pi create it:
```
/update-memory 2026-04-15
```

### Update Today's Memory
```
/update-memory 2026-04-14
```

Pi will guide you through:
- Reviewing your work
- Updating `notes.md` with summary, key points, learnings
- Updating `tasks.md` with completed, in-progress, and planned tasks

### Review Memory Period
```
/review-memory 2026-04-10 2026-04-14
```

Pi will summarize your memory entries across a date range and show:
- Timeline of milestones
- Key themes and learnings
- Problems solved
- Patterns and progress

### Update Memory Index
```
/index-memory
```

Pi will create or update `memory/INDEX.md` with:
- Searchable table of all daily entries
- Recent entries highlighted
- Month-by-month organization
- Quick navigation

## 📁 Daily Folder Structure

Each day has this structure:

```
memory/2026-04-14/
├── notes.md      # Daily observations, learnings, next steps
├── tasks.md      # What you completed, in progress, or planned
└── decisions.md  # (Optional) Decisions made and rationale
```

### notes.md Template
- **Summary** - Brief overview of the day
- **Key Points** - Main accomplishments or focus areas
- **Learnings** - What you learned
- **Observations** - Interesting things noticed
- **Next Steps** - What to focus on next

### tasks.md Template
- **Completed** - ✓ Tasks you finished
- **In Progress** - Current work
- **Planned** - Tomorrow's focus
- **Blocked** - Anything stuck and why

## 🔧 Configuration

Pi loads the memory system from:

- **`.pi/settings.json`** - Registers extensions and prompts
- **`.pi/extensions/memory-reminder.ts`** - Reminder extension
- **`.pi/prompts/*.md`** - Command templates

Edit `.pi/settings.json` to customize or disable the extension:

```json
{
  "extensions": [".pi/extensions/memory-reminder.ts"],
  "prompts": [".pi/prompts"]
}
```

## 💡 Tips

### Quick Workflow
1. Start pi: `pi` → reminder pops up
2. Update memory: `/update-memory 2026-04-14`
3. Work on your code
4. Periodically update notes in the editor if needed

### Review Patterns
- End of week: `/review-memory 2026-04-10 2026-04-14`
- End of month: `/index-memory` to rebuild the index
- Before switching projects: review and archive old memories

### Custom Additions
- Add `decisions.md` to any day to document choices
- Add `code_snippets.md` for reference code
- Add `links.md` for resources or references
- Create monthly summary folders in `memory/2026-04/summary.md`

## 🚀 Getting Started

1. **pi will ask on startup** - Just confirm "yes" to update today's memory
2. **Use `/update-memory YYYY-MM-DD`** - Pi guides you through the process
3. **Review regularly** - Use `/review-memory` to see your progress

The system helps you:
- ✅ Stay organized with daily notes
- ✅ Track progress and accomplishments
- ✅ Document learnings and insights
- ✅ Plan work efficiently
- ✅ Review and reflect on your work

---

For more details, see:
- `memory/README.md` - Memory system documentation
- `memory/INDEX.md` - Index of all daily entries
- `.pi/extensions/memory-reminder.ts` - How the reminder works
