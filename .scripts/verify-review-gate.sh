#!/bin/bash
# Cross-Host Review Gate Script
# Run this BEFORE claiming a child is complete. It verifies review artifacts exist.
#
# Usage: ./verify-review-gate.sh <child-id>
# Example: ./verify-review-gate.sh 2.3

set -e

CHILD_ID="$1"
if [ -z "$CHILD_ID" ]; then
    echo "❌ ERROR: No child ID provided"
    echo "Usage: $0 <child-id>"
    exit 1
fi

CHILD_DIR="Children/$CHILD_ID"
REVIEW_FILE="$CHILD_DIR/REVIEW-IMPL.md"
STATUS_FILE="$CHILD_DIR/STATUS.md"

echo "🔒 Cross-Host Review Gate for Child $CHILD_ID"
echo "============================================"

# Check 1: Does the review file exist?
if [ ! -f "$REVIEW_FILE" ]; then
    echo "❌ FAIL: REVIEW-IMPL.md not found at $REVIEW_FILE"
    echo ""
    echo "You must complete Step 4 (VERIFY) before proceeding."
    echo "Run a cross-host review and save the output to REVIEW-IMPL.md"
    exit 1
fi

echo "✅ REVIEW-IMPL.md exists"

# Check 2: Does the review file contain actual reviewer output?
# Look for keywords that indicate a real review happened
if grep -q "APPROVED\|NEEDS_REVISION\|APPROVED_WITH_NOTES" "$REVIEW_FILE"; then
    echo "✅ Review verdict found in REVIEW-IMPL.md"
else
    echo "⚠️ WARNING: No clear verdict (APPROVED/NEEDS_REVISION) found in REVIEW-IMPL.md"
    echo "   Make sure the file contains the actual reviewer output."
fi

# Check 3: If self-reviewed, is there documentation?
if grep -qi "self-review\|self reviewed" "$REVIEW_FILE"; then
    if [ ! -f "$STATUS_FILE" ]; then
        echo "❌ FAIL: Self-review detected but STATUS.md is missing"
        echo "   Document all failed reviewer attempts in STATUS.md"
        exit 1
    fi
    echo "⚠️ Self-review detected — verifying STATUS.md exists"
    echo "   Ensure STATUS.md documents ALL failed cross-host reviewer attempts"
fi

# Check 4: Does the review file look substantial?
LINE_COUNT=$(wc -l < "$REVIEW_FILE")
if [ "$LINE_COUNT" -lt 10 ]; then
    echo "⚠️ WARNING: REVIEW-IMPL.md is only $LINE_COUNT lines"
    echo "   A real review should be more substantial. Make sure you captured the full output."
fi

echo ""
echo "============================================"
echo "✅ Review gate PASSED for Child $CHILD_ID"
echo ""
echo "Next steps:"
echo "  1. If verdict is NEEDS_REVISION: fix blockers, re-run review"
echo "  2. If verdict is APPROVED/APPROVED_WITH_NOTES: proceed to Step 5 (DOCUMENT)"
