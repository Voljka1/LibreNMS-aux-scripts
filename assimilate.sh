#!/bin/bash
set -e
# P.S. Actually, this is not a bash script, this is the BORG script now. :)
shopt -s nullglob

# Terminal (but not deadly) colors
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[0;33m'
RESET='\033[0m'

error() { printf '%b\n' "${RED}$1${RESET}"; }
warning() { printf '%b\n' "${YELLOW}$1${RESET}"; }
info() { printf '%b\n' "${BLUE}$1${RESET}"; }
BORG() { printf '%b\n' "${GREEN}$1${RESET}"; }

# 0. Variable Initialization
CONTAINERS_LIST="librenms_main,librenms_dispatcher"

# Define Source MIBs Folder
MIBS_SRC_DIR="mibs"

# Updated Source Paths
# We point these to the directories provided: images/os/ and images/logos/
ICONS_SRC_PREFIX="images/os/"
LOGOS_SRC_PREFIX="images/logos/"

# Other Source Prefixes
OS_DET_SRC_PREFIX="os_detection_"
OS_DISC_SRC_PREFIX="os_discovery_"
OS_SRC_PREFIX="os_logic_"
TRAITS_SRC_PREFIX="os_traits_"

# Define Internal Container Paths (destinations)
VENDOR=""
ICON_DEST="/opt/librenms/html/images/os/"
LOGO_DEST="/opt/librenms/html/images/logos/"
YAML_DET_DEST="/opt/librenms/resources/definitions/os_detection/"
YAML_DISC_DEST="/opt/librenms/resources/definitions/os_discovery/"
OS_DEST="/opt/librenms/LibreNMS/OS/"
TRAITS_DEST="/opt/librenms/LibreNMS/OS/Traits/"

# 1. Greetings
BORG "Starting Assimilation..."
BORG "Resistance is futile."

# 2. Functions block
docker_exec_all() {
    local user=$1
    shift
    for container in "${CONTAINERS[@]}"; do
        docker exec -u "$user" "$container" "$@"
    done
}

docker_cp_all() {
    local src=$1
    local dest=$2
    for container in "${CONTAINERS[@]}"; do
        docker cp "$src" "$container":"$dest"
    done
}

assimilate() {
    local prefix=$1
    local dest_dir=$2
    
    # This will now catch files inside the directory prefixes or files starting with string prefixes
    local raw_files=( "${prefix}"* )

    if (( ${#raw_files[@]} == 0 )); then
        return
    fi

    for raw_filename in "${raw_files[@]}"; do
        # Skip if it's a directory (relevant for the new folder-based prefixes)
        [ -d "$raw_filename" ] && continue

        local stripped_name="${raw_filename#"$prefix"}"
        local full_dest_path="$dest_dir$stripped_name"

        info "Assimilating $raw_filename -> $stripped_name"
        docker_cp_all "$raw_filename" "$full_dest_path"
        docker_exec_all 0 chown librenms:librenms "$full_dest_path"
        docker_exec_all 0 chmod 644 "$full_dest_path"
    done
}

# 3. Detect Vendor
VENDOR_FILES=( __*__* )
[[ ${#VENDOR_FILES[@]} -gt 1 ]] && { error "Error: Multiple markers found: ${VENDOR_FILES[*]}"; exit 1; }
if [[ "${VENDOR_FILES[0]}" =~ ^__(.+)__ ]]; then
    VENDOR="${BASH_REMATCH[1]//-/\/}"
    VENDOR="${VENDOR,,}"
fi

# 4. Container list support
CONTAINERS_LIST=${CONTAINERS_LIST//[[:space:]]/}
IFS=',' read -ra CONTAINERS <<< "$CONTAINERS_LIST"

if [[ ${#CONTAINERS[@]} -eq 0 ]]; then
    error "Error: CONTAINERS_LIST is empty."
    exit 1
fi

# 5. Mass Assimilation of MIBs
if [ -d "$MIBS_SRC_DIR" ] && [ -n "$VENDOR" ]; then
    info "Assimilating MIB files for vendor: $VENDOR"
    MIB_DEST="/opt/librenms/mibs/$VENDOR/"
    docker_exec_all librenms mkdir -p "$MIB_DEST"
    for mib in "$MIBS_SRC_DIR"/*; do
        mib_filename=$(basename "$mib")
        docker_cp_all "$mib" "$MIB_DEST$mib_filename"
    done
    docker_exec_all 0 chown -R librenms:librenms "$MIB_DEST"
    docker_exec_all 0 chmod -R u=rwX,g=rX,o=rX "$MIB_DEST"
fi

# 6. Consolidated Assimilation Calls
# Using the updated directory-based prefixes for icons and logos
assimilate "$ICONS_SRC_PREFIX"      "$ICON_DEST"
assimilate "$LOGOS_SRC_PREFIX"      "$LOGO_DEST"
assimilate "$OS_DET_SRC_PREFIX"     "$YAML_DET_DEST"
assimilate "$OS_DISC_SRC_PREFIX"    "$YAML_DISC_DEST"
assimilate "$OS_SRC_PREFIX"         "$OS_DEST"
assimilate "$TRAITS_SRC_PREFIX"     "$TRAITS_DEST"

# 7. Finalize
info "Clearing cache..."
docker_exec_all librenms php lnms cache:clear

# 8. Final Words
BORG "Assimilation complete. Your files is now part of the Collective."