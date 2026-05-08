#!/bin/bash

# --- CONFIGURATION ---
COMMUNITY="Home"
TARGET="172.16.2.254"
# Path to your dumped LibreNMS MIBs
MIB_DIR="/usr/share/snmp/mibs"

# --- VALIDATION ---
if [ ! -d "$MIB_DIR" ]; then
    echo "Error: Directory $MIB_DIR not found."
    exit 1
fi

echo "Scanning $TARGET..."
echo "Using MIBs from: $MIB_DIR"
echo "---------------------------------------"

# -M: Points to your folder
# -m ALL: Loads every file
# -O T: Forces 'Print MIB-module' format for every object
# 2>/dev/null: Hides the "Module not found" errors common with bulk dumps
snmpwalk -v2c -c "$COMMUNITY" "$TARGET" .1 \
    -M "$MIB_DIR" \
    -m ALL \
    -O T 2>/dev/null | \
    grep -oE '^[A-Z0-9-]+-MIB|^[A-Z0-9-]+-SMI' | \
    sort -u

echo "---------------------------------------"
echo "Scan Complete."
