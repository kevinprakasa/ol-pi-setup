#!/bin/bash

# Create a new daily memory folder
# Usage: ./create_daily_memory.sh [YYYY-MM-DD]
# If no date provided, uses today's date

DATE=${1:-$(date +%Y-%m-%d)}
MEMORY_DIR="memory/$DATE"

if [ -d "$MEMORY_DIR" ]; then
    echo "✓ Memory folder for $DATE already exists"
    echo "  Location: $MEMORY_DIR"
else
    mkdir -p "$MEMORY_DIR"
    
    # Create notes.md
    cat > "$MEMORY_DIR/notes.md" << 'EOF'
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
EOF
    
    # Create tasks.md
    cat > "$MEMORY_DIR/tasks.md" << 'EOF'
# Tasks - $DATE

## Completed
- [ ] 

## In Progress
- [ ] 

## Planned
- [ ] 

## Blocked
- [ ] 
EOF
    
    echo "✓ Created daily memory folder for $DATE"
    echo "  Location: $MEMORY_DIR"
    echo "  Files: notes.md, tasks.md"
fi
