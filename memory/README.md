# Memory System

A daily note-taking and memory organization system.

## Structure

```
memory/
├── 2026-04-14/
│   ├── notes.md        # Daily notes
│   ├── tasks.md        # Tasks completed/pending
│   └── ...other files...
├── 2026-04-13/
│   └── notes.md
└── INDEX.md            # Quick reference & navigation
```

## Usage

### Create Today's Memory Folder

Run the create script:
```bash
./create_daily_memory.sh
```

Or manually:
```bash
mkdir -p memory/YYYY-MM-DD
touch memory/YYYY-MM-DD/notes.md
```

### File Types in Daily Folders

- **notes.md** - Daily thoughts, learnings, observations
- **tasks.md** - Tasks completed, in progress, or planned
- **decisions.md** - Decisions made and rationale
- **code_snippets.md** - Code references or snippets
- *Any custom files as needed*

## Quick Links

See [INDEX.md](INDEX.md) for a summary of all daily entries.

## Tips

1. Keep one folder per day using YYYY-MM-DD format
2. Start with notes.md in each folder
3. Add other files as needed (tasks.md, decisions.md, etc.)
4. Reference previous days: `../2026-04-13/notes.md`
