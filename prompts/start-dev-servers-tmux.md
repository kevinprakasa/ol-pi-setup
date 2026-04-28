# Start All Dev Servers with Tmux

Start all development services in a persistent tmux session that you can detach/re-attach at any time. This is the **professional, production-ready approach**.

## Prerequisites: Ensure Docker is Running

⚠️ **REQUIRED FIRST:** Docker must be running before starting databases.

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

## Start All Services with Tmux

### Option 1: One-Command Startup (Recommended)

```bash
bash /tmp/start-all-services-tmux.sh
```

This will:
1. ✅ Verify Docker is running (start if needed)
2. ✅ Start database containers (`make dbs`)
3. ✅ Create tmux session with 6 windows
4. ✅ Start all dev servers
5. ✅ **Configure smart split keys** — new panes open in current pane's directory

### Option 2: Manual Tmux Setup

#### Step 1: Start Docker Databases
```bash
cd /Users/kevinprakasa/dev/ol-docker && make dbs
```

Wait for databases to be ready (~15 seconds).

#### Step 2: Create Tmux Session
```bash
# Session starts in async-engine directory
cd /Users/kevinprakasa/dev/ol-async-engine
tmux new-session -d -s dev

# CRITICAL: Rebind split keys for smart directory behavior
tmux bind-key '"' split-window -h -c "#{pane_current_path}"
tmux bind-key '%' split-window -h -c "#{pane_current_path}"
tmux bind-key '-' split-window -v -c "#{pane_current_path}"
```

#### Step 3: Create Windows and Run Services

**Window 0 — async-engine:**
```bash
tmux rename-window -t dev:0 "async-engine"
tmux send-keys -t dev:0 "source .venv/bin/activate && set -a && source .env && set +a && poe devserver" Enter
tmux split-window -h -t dev:0 -c "/Users/kevinprakasa/dev/ol-async-engine"
tmux send-keys -t dev:0.1 "source .venv/bin/activate && set -a && source .env && set +a && poe service-bus" Enter
tmux select-layout -t dev:0 even-horizontal
```

**Window 1 — ol-engine:**
```bash
cd /Users/kevinprakasa/dev/ol-docker/engine/OpenLearningEngine
tmux new-window -t dev -n "ol-engine"
tmux send-keys -t dev:1 "source .venv/bin/activate && make devserver" Enter
tmux split-window -h -t dev:1 -c "/Users/kevinprakasa/dev/ol-docker/engine/OpenLearningEngine"
tmux send-keys -t dev:1.1 "source .venv/bin/activate && ./start_async_bridge.sh" Enter
tmux select-layout -t dev:1 even-horizontal
```

**Window 2 — ol-client:**
```bash
cd /Users/kevinprakasa/dev/ol-docker/engine/OpenLearningClient
tmux new-window -t dev -n "ol-client"
tmux send-keys -t dev:2 "yarn devserver" Enter
```

**Window 3 — exam-engine:**
```bash
cd /Users/kevinprakasa/dev/ol-exam-engine
tmux new-window -t dev -n "exam-engine"
tmux send-keys -t dev:3 "source .venv/bin/activate && poe api" Enter
```

**Window 4 — exam-client:**
```bash
cd /Users/kevinprakasa/dev/ol-exam-client
tmux new-window -t dev -n "exam-client"
tmux send-keys -t dev:4 "yarn dev-local" Enter
```

**Window 5 — code-exec:**
```bash
cd /Users/kevinprakasa/dev/code_execution
tmux new-window -t dev -n "code-exec"
tmux send-keys -t dev:5 "sh localtunnel.sh olhook" Enter
tmux split-window -h -t dev:5 -c "/Users/kevinprakasa/dev/code_execution"
tmux send-keys -t dev:5.1 "sh dev.sh" Enter
tmux select-layout -t dev:5 even-horizontal
```

#### Step 4: Attach to Session
```bash
tmux attach -t dev
```

## Tmux Session Management

### View Running Session
```bash
tmux list-sessions
```

### Attach to Session
```bash
tmux attach -t dev
```

### Detach from Session
Press: `Ctrl + B` then `D`

### Kill Entire Session
```bash
tmux kill-session -t dev
```

### Navigate Windows
- `Ctrl + B` then `N` - Next window
- `Ctrl + B` then `P` - Previous window
- `Ctrl + B` then `0-5` - Go to specific window (0-5)
- `Ctrl + B` then `W` - List all windows

### Navigate Panes (within a window)
- `Ctrl + B` then `Arrow Keys` - Move between panes
- `Ctrl + B` then `}` - Move pane right
- `Ctrl + B` then `{` - Move pane left

### Resize Panes
- `Ctrl + B` then `:` then type `resize-pane -R 5` (resize right 5 units)

### Session Layout

```
dev (tmux session)
├── Window 0: async-engine [2 panes]
│   ├── pane 0: poe devserver
│   └── pane 1: poe service-bus
├── Window 1: ol-engine [2 panes]
│   ├── pane 0: make devserver
│   └── pane 1: ./start_async_bridge.sh
├── Window 2: ol-client
│   └── yarn devserver
├── Window 3: exam-engine
│   └── poe api
├── Window 4: exam-client
│   └── yarn dev-local
└── Window 5: code-exec [2 panes]
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
3. View session: `tmux attach -t dev`
4. Check specific window: `tmux send-keys -t dev:0 "C-l"` (clear screen)

### Re-attach After Closing Terminal
```bash
tmux attach -t dev
```

### Restart Everything
```bash
# Kill old session
tmux kill-session -t dev

# Start fresh
bash /tmp/start-all-services-tmux.sh
```

### Check Logs
```bash
# View session output history
tmux send-keys -t dev:0 "C-l"  # Clear pane
tmux capture-pane -t dev:0 -p  # Print pane contents
```

## Advanced: Custom Tmux Config

Create `~/.tmux.conf` for better tmux experience:

```bash
# Set prefix to Ctrl + A (easier than Ctrl + B)
set -g prefix C-a
unbind C-b
bind C-a send-prefix

# Enable mouse
set -g mouse on

# Use vi keybindings
setw -g mode-keys vi

# Increase history
set -g history-limit 10000

# Status bar colors
set -g status-bg black
set -g status-fg white

# Smart splits - new panes open in current pane's directory
bind-key '"' split-window -h -c "#{pane_current_path}"
bind-key '%' split-window -v -c "#{pane_current_path}"
bind-key '-' split-window -v -c "#{pane_current_path}"
```

Then reload: `tmux source-file ~/.tmux.conf`

## Tips & Best Practices

✅ **Smart splits** — `Ctrl+B "` (horizontal), `Ctrl+B %` (vertical), and `Ctrl+B -` (vertical) open new panes in the current pane's directory. This is configured automatically by the startup script.

✅ **Always use tmux for**:
- Development work that lasts hours/days
- Server-based development
- Team collaboration
- Persistent build processes

✅ **Window naming**:
```bash
tmux rename-window -t dev:0 "async-engine"
```

✅ **Check specific service logs**:
```bash
tmux capture-pane -t dev:0 -p -S -100  # Last 100 lines
```

✅ **Run commands in detached session**:
```bash
tmux send-keys -t dev:0 "some command" Enter
```

✅ **Watch specific window**:
```bash
tmux send-keys -t dev:0 "C-c"  # Stop current process
tmux send-keys -t dev:0 "poe devserver --reload" Enter  # Restart
```