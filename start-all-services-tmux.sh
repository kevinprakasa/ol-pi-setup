#!/bin/bash

# Start All Dev Servers with Tmux
# Usage: cd /Users/kevinprakasa/dev/backup_memory && bash ./start-all-services-tmux.sh

set -e

echo "🚀 Starting all dev services..."

# Check Docker
if ! docker ps > /dev/null 2>&1; then
    echo "⚠️  Docker not running. Starting Docker..."
    open /Applications/Docker.app
    echo "Waiting for Docker to start..."
    for i in {1..30}; do
        if docker ps > /dev/null 2>&1; then
            echo "✅ Docker is ready"
            break
        fi
        sleep 1
    done
fi

# Start databases
echo "📦 Starting databases..."
cd /Users/kevinprakasa/dev/ol-docker && make dbs
echo "Waiting for databases to be ready..."
sleep 5

# Kill existing session if any
tmux kill-session -t dev 2>/dev/null || true

# Create tmux session
echo "🖥️  Creating tmux session 'dev'..."
tmux new-session -d -s dev

# Window 0: async-engine
echo "📦 Starting async-engine..."
tmux rename-window -t dev:0 "async-engine"
tmux send-keys -t dev:0 "cd /Users/kevinprakasa/dev/ol-async-engine && source .venv/bin/activate && set -a && source .env && set +a && poe devserver" Enter
tmux split-window -h -t dev:0
tmux send-keys -t dev:0.1 "cd /Users/kevinprakasa/dev/ol-async-engine && source .venv/bin/activate && set -a && source .env && set +a && poe service-bus" Enter

# Window 1: ol-engine
echo "⚙️  Starting ol-engine..."
tmux new-window -t dev:1 -n "ol-engine"
tmux send-keys -t dev:1 "cd /Users/kevinprakasa/dev/ol-docker/engine/OpenLearningEngine && source .venv/bin/activate && make devserver" Enter
tmux split-window -h -t dev:1
tmux send-keys -t dev:1.1 "cd /Users/kevinprakasa/dev/ol-docker/engine/OpenLearningEngine && source .venv/bin/activate && ./start_async_bridge.sh" Enter

# Window 2: ol-client
echo "🎨 Starting ol-client..."
tmux new-window -t dev:2 -n "ol-client"
tmux send-keys -t dev:2 "cd /Users/kevinprakasa/dev/ol-docker/engine/OpenLearningClient && yarn devserver" Enter

# Window 3: exam-engine
echo "📝 Starting exam-engine..."
tmux new-window -t dev:3 -n "exam-engine"
tmux send-keys -t dev:3 "cd /Users/kevinprakasa/dev/ol-exam-engine && source .venv/bin/activate && poe api" Enter

# Window 4: exam-client
echo "📋 Starting exam-client..."
tmux new-window -t dev:4 -n "exam-client"
tmux send-keys -t dev:4 "cd /Users/kevinprakasa/dev/ol-exam-client && yarn dev-local" Enter

# Window 5: code-exec
echo "💻 Starting code-exec..."
tmux new-window -t dev:5 -n "code-exec"
tmux send-keys -t dev:5 "cd /Users/kevinprakasa/dev/code_execution && sh localtunnel.sh olhook" Enter
tmux split-window -h -t dev:5
tmux send-keys -t dev:5.1 "cd /Users/kevinprakasa/dev/code_execution && sh dev.sh" Enter

# Select first window
tmux select-window -t dev:0

echo ""
echo "✅ All services started in tmux session 'dev'"
echo ""
echo "Expected Ports:"
echo "  • async-engine:     http://127.0.0.1:8002"
echo "  • ol-engine:        http://0.0.0.0:8008"
echo "  • ol-engine bridge: http://127.0.0.1:8001"
echo "  • ol-client:        http://openlearning.test:8000"
echo "  • exam-engine:      http://127.0.0.1:8888"
echo "  • exam-client:      http://exam.openlearning.test:5173"
echo "  • code_execution:  http://127.0.0.1:5000"
echo ""
echo "Attach to session: tmux attach -t dev"
echo "Detach: Ctrl+B then D"