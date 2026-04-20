# Dev Environment Sync Checklist

**IMPORTANT:** Keep these files in sync:
- Prompt file: `~/.pi/agent/prompts/start-dev-servers-tmux.md`
- Startup script: `/tmp/start-all-services-tmux.sh`

## What Needs to Stay In Sync

### 🪟 Window Configuration
```
Window 0: async-engine (2 panes)
Window 1: ol-engine (2 panes)
Window 2: ol-client
Window 3: exam-engine
Window 4: exam-client
Window 5: code-exec (2 panes)
```

**If you change this:**
- [ ] Update the script with new `-c` directory paths
- [ ] Update the prompt file with new window list

### 📍 Directory Paths
All these paths must match in BOTH files:
```bash
/Users/kevinprakasa/dev/ol-async-engine
/Users/kevinprakasa/dev/ol-docker/engine/OpenLearningEngine
/Users/kevinprakasa/dev/ol-docker/engine/OpenLearningClient
/Users/kevinprakasa/dev/ol-exam-engine
/Users/kevinprakasa/dev/ol-exam-client
/Users/kevinprakasa/dev/code_execution
```

**If a path changes:**
- [ ] Update the script (in `-c` flags AND in `tmux send-keys`)
- [ ] Update the prompt file's manual setup section

### 🔧 Commands for Each Window
Each window/pane has a command. Must match in both files:

```bash
# Window 0, Pane 0
source .venv/bin/activate && set -a && source .env && set +a && poe devserver

# Window 0, Pane 1
source .venv/bin/activate && set -a && source .env && set +a && poe service-bus

# Window 1, Pane 0
source .venv/bin/activate && make devserver

# Window 1, Pane 1
source .venv/bin/activate && ./start_async_bridge.sh

# Window 2
yarn devserver

# Window 3
source .venv/bin/activate && poe api

# Window 4
yarn dev-local

# Window 5, Pane 0
sh localtunnel.sh olhook

# Window 5, Pane 1
sh dev.sh
```

**If a command changes:**
- [ ] Update the script (in the `tmux send-keys` lines)
- [ ] Update the prompt file's manual section
- [ ] Update the session layout diagram

### 🔗 Expected Ports
```
8002  - ol-async-engine devserver
8008  - OpenLearningEngine devserver
8001  - OpenLearningEngine async_bridge
8000  - OpenLearningClient
8888  - ol-exam-engine
5173  - ol-exam-client
5000  - code_execution
```

**If ports change:**
- [ ] Update the prompt file's "Expected Ports" table
- [ ] Update any port mentions in documentation

## Quick Sync Instructions

When you update ONE file, update the OTHER:

1. **Modified script?** → Update prompt file
   - Update paths
   - Update commands
   - Update session layout diagram

2. **Modified prompt file?** → Update script
   - Update window config
   - Update directory paths
   - Update tmux commands

## Verification

Run this to verify both files are in sync:

```bash
echo "=== Script paths ==="
grep -o "/Users[^ ]*" /tmp/start-all-services-tmux.sh | sort -u

echo "=== Prompt paths ==="
grep -o "/Users[^ ]*" ~/.pi/agent/prompts/start-dev-servers-tmux.md | sort -u

# They should match!
```

## Future: Automated Sync

Consider creating a script that generates BOTH from a single source:
```bash
dev-config.yaml  ← Single source of truth
├─ generate-scripts.sh
├─ start-all-services-tmux.sh  (generated)
└─ start-dev-servers-tmux.md   (generated)
```

This would eliminate manual syncing!
