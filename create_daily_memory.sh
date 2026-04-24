#!/bin/bash

# Create a new daily memory folder with carry-forward from previous day
# Usage: ./create_daily_memory.sh [YYYY-MM-DD]
# If no date provided, uses today's date

DATE=${1:-$(date +%Y-%m-%d)}
MEMORY_DIR="memory/$DATE"

# Calculate yesterday's date using Python (cross-platform)
YESTERDAY=$(python3 -c "from datetime import datetime, timedelta; print((datetime.strptime('$DATE', '%Y-%m-%d') - timedelta(days=1)).strftime('%Y-%m-%d'))" 2>/dev/null || echo "")

if [ -z "$YESTERDAY" ]; then
    # Fallback: use current date minus 1 day
    YESTERDAY=$(date -v-1d +%Y-%m-%d)
fi

YESTERDAY_DIR="memory/$YESTERDAY"

# Function to extract unchecked items from a section
get_unchecked() {
    local file="$1"
    local section="$2"
    
    if [ ! -f "$file" ]; then
        echo ""
        return
    fi
    
    awk -v section="## $section" '
        BEGIN { in_section=0 }
        $0 == section { in_section=1; next }
        in_section && /^## / { in_section=0; exit }
        in_section && /^[[:space:]]*- \[ \]/ { 
            sub(/^[[:space:]]*/, "")
            print
        }
    ' "$file" 2>/dev/null
}

# Function to get next steps from notes
get_next_steps() {
    local file="$1"
    
    if [ ! -f "$file" ]; then
        echo ""
        return
    fi
    
    awk '/^## Next Steps/,/^## [^N]/' "$file" 2>/dev/null | grep -v "^## Next Steps" | grep -v "^$" | grep -v "^---"
}

if [ -d "$MEMORY_DIR" ]; then
    echo "✓ Memory folder for $DATE already exists"
    echo "  Location: $MEMORY_DIR"
else
    mkdir -p "$MEMORY_DIR"
    
    # Check if yesterday's memory exists
    CARRY_IN_PROGRESS=""
    CARRY_PLANNED=""
    CARRY_NEXT_STEPS=""
    CARRIED_COUNT=0
    
    if [ -d "$YESTERDAY_DIR" ]; then
        echo "📋 Carrying forward from $YESTERDAY..."
        
        # Get unchecked tasks
        if [ -f "$YESTERDAY_DIR/tasks.md" ]; then
            CARRY_IN_PROGRESS=$(get_unchecked "$YESTERDAY_DIR/tasks.md" "In Progress")
            CARRY_PLANNED=$(get_unchecked "$YESTERDAY_DIR/tasks.md" "Planned")
        fi
        
        # Get next steps from notes
        if [ -f "$YESTERDAY_DIR/notes.md" ]; then
            CARRY_NEXT_STEPS=$(get_next_steps "$YESTERDAY_DIR/notes.md")
        fi
    fi
    
    # Build tasks.md content
    TASKS_CONTENT="# Tasks - $DATE

## Completed
- [ ] 

## In Progress
"
    if [ -n "$CARRY_IN_PROGRESS" ]; then
        TASKS_CONTENT="${TASKS_CONTENT}${CARRY_IN_PROGRESS}
"
        CARRIED_COUNT=$((CARRIED_COUNT + $(echo "$CARRY_IN_PROGRESS" | grep -c "^")))
    else
        TASKS_CONTENT="${TASKS_CONTENT}- [ ] 
"
    fi
    
    TASKS_CONTENT="${TASKS_CONTENT}
## Planned
"
    if [ -n "$CARRY_PLANNED" ]; then
        TASKS_CONTENT="${TASKS_CONTENT}${CARRY_PLANNED}
"
        CARRIED_COUNT=$((CARRIED_COUNT + $(echo "$CARRY_PLANNED" | grep -c "^")))
    else
        TASKS_CONTENT="${TASKS_CONTENT}- [ ] 
"
    fi
    
    TASKS_CONTENT="${TASKS_CONTENT}
## Blocked
- [ ] 

---

## Carried from $YESTERDAY
"
    
    # Add carried items section
    if [ -n "$CARRY_IN_PROGRESS" ]; then
        TASKS_CONTENT="${TASKS_CONTENT}### Previous In Progress (still active)
$CARRY_IN_PROGRESS

"
    fi
    if [ -n "$CARRY_PLANNED" ]; then
        TASKS_CONTENT="${TASKS_CONTENT}### Previous Planned (still pending)
$CARRY_PLANNED

"
    fi
    if [ -n "$CARRY_NEXT_STEPS" ]; then
        TASKS_CONTENT="${TASKS_CONTENT}### Previous Next Steps
$CARRY_NEXT_STEPS
"
    fi
    
    # Write tasks.md
    echo "$TASKS_CONTENT" > "$MEMORY_DIR/tasks.md"
    
    # Create notes.md
    cat > "$MEMORY_DIR/notes.md" << 'NODES_EOF'
# Daily Notes - $DATE

## Summary
<!-- Brief overview of the day -->

## Key Points
- 
- 
- 

## Learnings
<!-- What did you learn today? -->

## Observations
<!-- Interesting things noticed -->

## Next Steps
<!-- What to focus on next -->
NODES_EOF
    
    echo "✓ Created daily memory folder for $DATE"
    echo "  Location: $MEMORY_DIR"
    
    if [ -d "$YESTERDAY_DIR" ] && [ "$CARRIED_COUNT" -gt 0 ]; then
        echo ""
        echo "📦 Carried $CARRIED_COUNT items from $YESTERDAY"
    fi
fi