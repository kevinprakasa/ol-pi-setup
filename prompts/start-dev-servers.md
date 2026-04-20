# Start All Dev Servers

Start all development services in iTerm with the following tab and pane arrangement. **Important: Start the database services first!**

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

## Start Docker Databases

✅ **After Docker is running:** Start the database containers in a separate iTerm tab.

Open a new iTerm window and run:
```bash
cd /Users/kevinprakasa/dev/ol-docker && make dbs
```

Wait for all databases to start (MongoDB, Redis, Memcached, etc.). You should see something like "database container started".

## Dev Servers Setup

1. After databases are running, open another iTerm window for the dev servers
2. Create tabs for each service and run the commands below

### Tab 1 — `async-engine` (split horizontally)

**Pane 1 (top):**
```bash
cd /Users/kevinprakasa/dev/ol-async-engine && source .venv/bin/activate && set -a && source .env && set +a && poe devserver
```

**Pane 2 (bottom):**
- Split the tab horizontally: `Cmd + D`
- Run:
```bash
cd /Users/kevinprakasa/dev/ol-async-engine && source .venv/bin/activate && set -a && source .env && set +a && poe service-bus
```

### Tab 2 — `ol-engine` (split horizontally)

**Pane 1 (top):**
```bash
cd /Users/kevinprakasa/dev/ol-docker/engine/OpenLearningEngine && source .venv/bin/activate && make devserver
```

**Pane 2 (bottom):**
- Split the tab horizontally: `Cmd + D`
- Run:
```bash
cd /Users/kevinprakasa/dev/ol-docker/engine/OpenLearningEngine && source .venv/bin/activate && ./start_async_bridge.sh
```

### Tab 3 — `ol-client`
```bash
cd /Users/kevinprakasa/dev/ol-docker/engine/OpenLearningClient && yarn devserver
```

### Tab 4 — `exam-engine`
```bash
cd /Users/kevinprakasa/dev/ol-exam-engine && source .venv/bin/activate && poe api
```

### Tab 5 — `exam-client`
```bash
cd /Users/kevinprakasa/dev/ol-exam-client && yarn dev-local
```

### Tab 6 — `code-exec` (split horizontally)

**Pane 1 (top):**
```bash
cd /Users/kevinprakasa/dev/code_execution && sh localtunnel.sh olhook
```

**Pane 2 (bottom):**
- Split the tab horizontally: `Cmd + D`
- Run:
```bash
cd /Users/kevinprakasa/dev/code_execution && sh dev.sh
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

## Quick Reference: iTerm Shortcuts

| Action | Shortcut |
|---|---|
| New Tab | `Cmd + T` |
| Split Horizontally | `Cmd + D` |
| Split Vertically | `Cmd + Alt + D` |
| Switch Panes | `Cmd + [` or `Cmd + ]` |
| Close Pane/Tab | `Cmd + W` |

## After Starting

**Verify in order:**
1. ✅ Docker databases running (check ol-docker window)
2. ✅ Each dev server starts (wait 5-10 seconds for initialization)
3. ✅ No connection errors (should connect to running databases)
4. Report the status of all services

**Troubleshooting:**
- If services fail to start, check the ol-docker window for database errors
- Make sure `make dbs` completed successfully before starting dev servers
- Check ports are not already in use: `lsof -i :8002` (etc.)
