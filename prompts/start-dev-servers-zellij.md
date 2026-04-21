# Start All Dev Servers with Zellij

Start all development services in a persistent Zellij session. Zellij is **modern, intuitive, and much easier than tmux**!

**⚠️ NOTE:** This prompt file is documentation. The actual startup script is at `/tmp/start-all-services-zellij.sh`. If you update one, update the other to keep them in sync!

## Quick Start (Recommended)

```bash
bash /tmp/start-all-services-zellij.sh
```

This automated script will:
1. ✅ Verify Docker is running (start if needed)
2. ✅ Start database containers (`make dbs`)
3. ✅ Create Zellij session with 6 tabs
4. ✅ Start all dev servers
5. ✅ Display status and port information

**That's it!** Your development environment is ready.

---

## Prerequisites: Ensure Docker is Running

⚠️ **REQUIRED:** Docker must be running before starting databases.

### Check if Docker is running:
```bash
docker ps
```

**If you see an error** like "Cannot connect to the Docker daemon", start Docker:
```bash
open /Applications/Docker.app
```

Wait until you see the Docker icon in the menu bar (top right). Then verify:
```bash
docker ps  # Should list containers without error
```

## Manual Setup (If Needed)

If the automated script doesn't work, follow these manual steps:

#### Step 1: Start Docker Databases
```bash
cd /Users/kevinprakasa/dev/ol-docker && make dbs
```

Wait for databases to be ready (~15 seconds).

#### Step 2: Create Zellij Session
```bash
zellij
```

This creates a new session with a single tab. You'll see a prompt at the bottom.

#### Step 3: Create Tabs and Run Services

**Tab 1 — async-engine (with split panes):**

```bash
# In Zellij, press Ctrl+G to enter mode, then:
# Type 'n' for new tab, or use the UI to create a new tab

cd /Users/kevinprakasa/dev/ol-async-engine
source .venv/bin/activate
set -a && source .env && set +a
poe devserver

# To split pane: Ctrl+G then arrow keys (right or down)
# In the split pane:
source .venv/bin/activate
set -a && source .env && set +a
poe service-bus
```

**Tab 2 — ol-engine (with split panes):**
```bash
cd /Users/kevinprakasa/dev/ol-docker/engine/OpenLearningEngine
source .venv/bin/activate
make devserver

# Split pane and run:
source .venv/bin/activate
./start_async_bridge.sh
```

**Tab 3 — ol-client:**
```bash
cd /Users/kevinprakasa/dev/ol-docker/engine/OpenLearningClient
yarn devserver
```

**Tab 4 — exam-engine:**
```bash
cd /Users/kevinprakasa/dev/ol-exam-engine
source .venv/bin/activate
poe api
```

**Tab 5 — exam-client:**
```bash
cd /Users/kevinprakasa/dev/ol-exam-client
yarn dev-local
```

**Tab 6 — code-exec (with split panes):**
```bash
cd /Users/kevinprakasa/dev/code_execution
sh localtunnel.sh olhook

# Split pane and run:
sh dev.sh
```

## Zellij Keyboard Shortcuts

### Navigation

| Action | Keys |
|---|---|
| **Enter mode** | `Ctrl + G` |
| **Next tab** | `Ctrl + G` then `Right Arrow` (in mode) |
| **Previous tab** | `Ctrl + G` then `Left Arrow` (in mode) |
| **New tab** | `Ctrl + G` then `N` (in mode) |
| **Close tab** | `Ctrl + G` then `X` (in mode) |
| **Rename tab** | `Ctrl + G` then `R` (in mode) |
| **List tabs** | `Ctrl + G` then `T` (in mode) |

### Pane Management

| Action | Keys |
|---|---|
| **Split pane (right)** | `Ctrl + G` then `Right Arrow` (in mode) |
| **Split pane (down)** | `Ctrl + G` then `Down Arrow` (in mode) |
| **Close pane** | `Ctrl + G` then `X` (in mode) |
| **Move between panes** | `Ctrl + G` then `Arrow Keys` (in mode) |
| **Fullscreen pane** | `Ctrl + G` then `F` (in mode) |

### Session Management

| Action | Keys |
|---|---|
| **Detach session** | `Ctrl + G` then `D` (in mode) |
| **Scroll up** | `Ctrl + G` then `PageUp` |
| **Scroll down** | `Ctrl + G` then `PageDown` |
| **List all panes** | `Ctrl + G` then `P` (in mode) |
| **Toggle floating pane** | `Ctrl + G` then `W` (in mode) |

---

## Zellij Session Management

### Check Running Sessions
```bash
zellij list-sessions
```

### Attach to Session
```bash
zellij attach dev
```

### Detach from Session
Press: `Ctrl + G` then `D`

### Kill Session
```bash
zellij kill-session dev
```

### List All Sessions
```bash
zellij list-sessions
```

---

## Session Layout

```
dev (zellij session)
├── Tab 1: async-engine [2 panes]
│   ├── pane 0: poe devserver
│   └── pane 1: poe service-bus
├── Tab 2: ol-engine [2 panes]
│   ├── pane 0: make devserver
│   └── pane 1: ./start_async_bridge.sh
├── Tab 3: ol-client
│   └── yarn devserver
├── Tab 4: exam-engine
│   └── poe api
├── Tab 5: exam-client
│   └── yarn dev-local
└── Tab 6: code-exec [2 panes]
    ├── pane 0: sh localtunnel.sh olhook
    └── pane 1: sh dev.sh
```

## Expected Ports

| Service | Port/URL |
|---|---|
| ol-async-engine devserver | http://127.0.0.1:8002 |
| OpenLearningEngine devserver | http://0.0.0.0:8008 |
| OpenLearningEngine async_bridge | http://127.0.0.1:8001 |
| OpenLearningClient | http://openlearning.test:8000 |
| ol-exam-engine | http://127.0.0.1:8888 |
| ol-exam-client | http://exam.openlearning.test:5173 |
| code_execution | http://127.0.0.1:5000 |

## Troubleshooting

### Services Not Starting
1. Check Docker is running: `docker ps`
2. Check databases: `docker ps | grep -E "mongo|redis|memcached"`
3. View session: `zellij attach dev`
4. Check logs in each tab

### Re-attach After Closing Terminal
```bash
zellij attach dev
```

### Restart Everything
```bash
# Kill old session
zellij kill-session dev

# Start fresh
bash /tmp/start-all-services-zellij.sh
```

### Check Current Session Info
```bash
zellij list-sessions
```

---

## Why Zellij Over Tmux?

✅ **Zellij Advantages:**
- 🎨 Beautiful, modern UI by default
- 🖱️  Mouse support works great
- ⌨️  More intuitive keybindings (Ctrl+G is easier than Ctrl+B)
- 📋 Better tab/pane management
- 🎯 Floating panes and layouts
- 📖 Excellent built-in help (`Ctrl+G` then `?`)
- 🚀 Faster navigation
- 💾 Auto-saves session state

❌ **Tmux:**
- Ancient, dated UI
- Complex keybindings
- Steep learning curve
- Less intuitive

---

## Tips & Best Practices

✅ **Quick navigation:**
- Always press `Ctrl+G` first to enter mode
- Then use arrow keys or letters
- Press `?` in mode to see all shortcuts

✅ **Rename tabs for clarity:**
```bash
Ctrl+G then R  # Rename current tab
```

✅ **Floating panes:**
```bash
Ctrl+G then W  # Toggle floating pane
```

✅ **Maximize a pane:**
```bash
Ctrl+G then F  # Fullscreen pane
```

✅ **Quick pane creation:**
```bash
Ctrl+G then Right Arrow  # Split right
Ctrl+G then Down Arrow   # Split down
```

---

## Zellij Configuration

Create `~/.config/zellij/config.kdl` for custom settings:

```kdl
keybinds clear-defaults=true {
    normal {
        bind "Ctrl g" { SwitchToMode "tmux"; }
    }
    tmux {
        bind "Ctrl g" { SwitchToMode "normal"; }
        bind "n" { NewTab; SwitchToMode "normal"; }
        bind "h" "Left" { MoveFocusLeft; }
        bind "j" "Down" { MoveFocusDown; }
        bind "k" "Up" { MoveFocusUp; }
        bind "l" "Right" { MoveFocusRight; }
        bind "x" { ClosePane; SwitchToMode "normal"; }
        bind "d" { Detach; }
    }
}

themes {
    dracula {
        bg "#282a36"
        fg "#f8f8f2"
        black "#21222c"
        red "#ff5555"
        green "#50fa7b"
        yellow "#f1fa8c"
        blue "#bd93f9"
        magenta "#ff79c6"
        cyan "#8be9fd"
        white "#f8f8f2"
    }
}

theme "dracula"

mouse_mode true
pane_frames true
```

---

## Next Steps

1. Run the startup script: `bash /tmp/start-all-services-zellij.sh`
2. Zellij will open with all services running
3. Use `Ctrl+G` then arrow keys to navigate
4. Press `Ctrl+G` then `?` anytime for help
5. Enjoy the superior UX! 🎉
