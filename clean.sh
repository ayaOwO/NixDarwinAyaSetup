#!/usr/bin/env bash
set -euo pipefail

echo "=== Nix Store Cleanup ==="
echo ""

# Function to format bytes to human readable
format_bytes() {
    local bytes=$1
    
    # Validate input: check if empty or not a number (including negative)
    if [ -z "$bytes" ] || ! [[ "$bytes" =~ ^-?[0-9]+$ ]]; then
        echo "0 B"
        return
    fi
    
    # Handle negative numbers separately
    local is_negative=false
    if [ $bytes -lt 0 ]; then
        is_negative=true
        bytes=$((bytes * -1))  # Make positive for calculations
    fi
    
    local sign=""
    if [ "$is_negative" = true ]; then
        sign="-"
    fi
    
    if [ $bytes -ge 1073741824 ]; then
        local gb=$(awk "BEGIN {printf \"%.2f\", $bytes/1073741824}")
        echo "${sign}${gb} GiB"
    elif [ $bytes -ge 1048576 ]; then
        local mb=$(awk "BEGIN {printf \"%.2f\", $bytes/1048576}")
        echo "${sign}${mb} MiB"
    elif [ $bytes -ge 1024 ]; then
        local kb=$(awk "BEGIN {printf \"%.2f\", $bytes/1024}")
        echo "${sign}${kb} KiB"
    else
        echo "${sign}${bytes} B"
    fi
}

# Get before stats
echo "📊 BEFORE:"
echo "--------"

# Count generations
set +e
GENERATION_COUNT_BEFORE=$(sudo nix-env --list-generations --profile /nix/var/nix/profiles/system 2>/dev/null | wc -l | tr -d ' ')
[ -z "$GENERATION_COUNT_BEFORE" ] && GENERATION_COUNT_BEFORE="0"
set -e
echo "  System Generations: ${GENERATION_COUNT_BEFORE}"

# Get store size before
set +e
STORE_SIZE_BEFORE=$(du -sb /nix/store 2>/dev/null | cut -f1)
[ -z "$STORE_SIZE_BEFORE" ] && STORE_SIZE_BEFORE="0"
set -e
STORE_SIZE_BEFORE_FORMATTED=$(format_bytes ${STORE_SIZE_BEFORE})
echo "  Store Size: ${STORE_SIZE_BEFORE_FORMATTED}"

# Count store paths
set +e
STORE_PATHS_BEFORE=$(find /nix/store -maxdepth 1 -type d 2>/dev/null | wc -l | tr -d ' ')
[ -z "$STORE_PATHS_BEFORE" ] && STORE_PATHS_BEFORE="0"
set -e
echo "  Store Paths: ${STORE_PATHS_BEFORE}"
echo ""

# Run cleanup
echo "🧹 Running cleanup..."
echo ""

echo "  1. Deleting old system generations..."
sudo nix-env --delete-generations old --profile /nix/var/nix/profiles/system 2>&1 | grep -v "warning:" || true

echo "  2. Running garbage collection..."
nix-collect-garbage -d 2>&1 | grep -v "warning:" | grep -E "(deleting|store paths)" || true

echo "  3. Optimizing store (hard-linking duplicate files)..."
sudo nix-store --optimise 2>&1 | grep -v "warning:" | grep -E "(freed|MiB)" || true

echo ""
echo "📊 AFTER:"
echo "--------"

# Get after stats
set +e
GENERATION_COUNT_AFTER=$(sudo nix-env --list-generations --profile /nix/var/nix/profiles/system 2>/dev/null | wc -l | tr -d ' ')
[ -z "$GENERATION_COUNT_AFTER" ] && GENERATION_COUNT_AFTER="0"
set -e
echo "  System Generations: ${GENERATION_COUNT_AFTER}"

set +e
STORE_SIZE_AFTER=$(du -sb /nix/store 2>/dev/null | cut -f1)
[ -z "$STORE_SIZE_AFTER" ] && STORE_SIZE_AFTER="0"
set -e
STORE_SIZE_AFTER_FORMATTED=$(format_bytes ${STORE_SIZE_AFTER})
echo "  Store Size: ${STORE_SIZE_AFTER_FORMATTED}"

set +e
STORE_PATHS_AFTER=$(find /nix/store -maxdepth 1 -type d 2>/dev/null | wc -l | tr -d ' ')
[ -z "$STORE_PATHS_AFTER" ] && STORE_PATHS_AFTER="0"
set -e
echo "  Store Paths: ${STORE_PATHS_AFTER}"
echo ""

# Calculate differences (with defaults for empty values)
GENERATION_COUNT_BEFORE=${GENERATION_COUNT_BEFORE:-0}
GENERATION_COUNT_AFTER=${GENERATION_COUNT_AFTER:-0}
STORE_SIZE_BEFORE=${STORE_SIZE_BEFORE:-0}
STORE_SIZE_AFTER=${STORE_SIZE_AFTER:-0}
STORE_PATHS_BEFORE=${STORE_PATHS_BEFORE:-0}
STORE_PATHS_AFTER=${STORE_PATHS_AFTER:-0}

GENERATIONS_REMOVED=$((GENERATION_COUNT_BEFORE - GENERATION_COUNT_AFTER))
STORE_SIZE_FREED=$((STORE_SIZE_BEFORE - STORE_SIZE_AFTER))
STORE_PATHS_REMOVED=$((STORE_PATHS_BEFORE - STORE_PATHS_AFTER))
STORE_SIZE_FREED_FORMATTED=$(format_bytes ${STORE_SIZE_FREED})

echo "✅ Cleanup Complete!"
echo "   - Generations removed: ${GENERATIONS_REMOVED}"
echo "   - Space freed: ${STORE_SIZE_FREED_FORMATTED}"
echo "   - Store paths removed: ${STORE_PATHS_REMOVED}"

