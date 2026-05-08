#!/bin/bash

# 1. Configuration & Defaults
DEFAULT_CONTAINER="librenms_main"
LIMIT_QTY=10

run_query() {
    local query=$1
    local container=$2
    local exec_cmd="docker exec -i $container sh -c 'mariadb --table -h \"\$DB_HOST\" -u \"\$DB_USER\" -p\"\$DB_PASSWORD\" \"\$DB_NAME\" -e \"$query\"'"
    
    echo -e "\n--- Generated Query ---\n$query\n"
    if [ -t 1 ]; then
        eval "$exec_cmd" | less -S
    else
        eval "$exec_cmd"
    fi
}

clear
echo "====================================================="
echo "       LibreNMS Step-by-Step Query Builder"
echo "====================================================="

# --- STEP 1: TARGET DEVICE ---
echo "--- STEP 1: Select Target Device ---"
read -p "Enter Device ID (or press Enter for ALL): " DEV_ID

if [[ -n "$DEV_ID" ]]; then
    WHERE_CLAUSE="WHERE device_id = '$DEV_ID'"
else
    WHERE_CLAUSE="LIMIT $LIMIT_QTY"
fi

# --- STEP 2: SELECT TABLE (Auto-Numbered) ---
echo -e "\n--- STEP 2: Select Table ---"

# Define your tables in an array
TABLES=("access_points" "devices" "device_groups" "device_group_device" "entPhysical" "ipv4_addresses" "ports" "sensors" "wireless_sensors" "Custom Table")

# Loop through the array to print the menu
for i in "${!TABLES[@]}"; do
    echo "$((i+1))) ${TABLES[$i]}"
done

read -p "Select [1-${#TABLES[@]}]: " TABLE_CHOICE

# Subtract 1 from choice to get the correct array index
INDEX=$((TABLE_CHOICE-1))
FROM_VAL="${TABLES[$INDEX]}"

# Handle the "Custom Table" case specifically
if [[ "$FROM_VAL" == "Custom Table" ]]; then
    read -p "Enter table name: " FROM_VAL
fi

# --- STEP 3: SELECT COLUMNS ---
echo -e "\n--- STEP 3: Select Columns ---"
echo "1) All (*)"
echo "2) Summary (ID and relevant Labels)"
echo "3) Custom columns"
read -p "Select [1-3]: " COL_CHOICE

case $COL_CHOICE in
    1) SELECT_VAL="*" ;;
    2) 
        # Logic to pick best summary columns based on the table
        if [[ "$FROM_VAL" == "devices" ]]; then
            SELECT_VAL="device_id, hostname, sysName, os"
        elif [[ "$FROM_VAL" == "ports" ]]; then
            SELECT_VAL="port_id, device_id, ifName, ifAlias"
        elif [[ "$FROM_VAL" == "sensors" || "$FROM_VAL" == "wireless_sensors" ]]; then
            SELECT_VAL="sensor_id, device_id, sensor_class, sensor_descr, sensor_current"
        else
            SELECT_VAL="device_id, *"
        fi
        ;;
    3) read -p "Enter columns (comma separated): " SELECT_VAL ;;
    *) SELECT_VAL="*" ;;
esac

# --- FINAL EXECUTION ---
# Optimized for LibreNMS 26.4.1 Eloquent structures
FINAL_QUERY="SELECT $SELECT_VAL FROM $FROM_VAL $WHERE_CLAUSE;"
run_query "$FINAL_QUERY" "$DEFAULT_CONTAINER"