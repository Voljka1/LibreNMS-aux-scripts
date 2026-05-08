#!/bin/bash
set -e

if [ "$#" -lt 1 ]; then
    clear
    echo "---------------------------------------------------------------------"
    echo "Usage: ./discover.sh device_id [module] [debug_level] [-who]"
    echo "optional: module: sensors, os, ports"
    echo "optional: debug_level: v, vv, vvv"
    echo "optional: -who : run discovery and show activated modules only"
    echo
    echo "Examples:"
    echo "  ./discover.sh 20"
    echo "  ./discover.sh 20 vv"
    echo "  ./discover.sh 20 sensors"
    echo "  ./discover.sh 20 sensors vv"
    echo "  ./discover.sh 20 -who"
    echo "  ./discover.sh 20 os -who"
    exit 1
fi

DEVICE_ID="$1"
MODULE=""
DEBUG=""
WHO=false

for arg in "${@:2}"; do
    case "$arg" in
        -who|who)
            WHO=true
            ;;
        v|vv|vvv|-v|-vv|-vvv)
            DEBUG="-${arg#-}"
            ;;
        *)
            MODULE="$arg"
            ;;
    esac
done


# ---- WHO MODE  ----
if $WHO; then
    CMD="lnms device:discover $DEVICE_ID"

    [ -n "$MODULE" ] && CMD="$CMD -m $MODULE"

    echo "Executing inside container (WHO mode): $CMD"
    echo "------------------------------------------------------------"

    docker exec -it -u librenms librenms_main \
        $CMD 2>&1 | grep -E '^#### Load'

    exit 0
fi

# ---- NORMAL discover MODE ----
CMD="lnms device:discover"

[ -n "$MODULE" ] && CMD="$CMD -m $MODULE"
[ -n "$DEBUG" ]  && CMD="$CMD $DEBUG"

CMD="$CMD $DEVICE_ID"

echo "Executing inside container: $CMD"

docker exec -it -u librenms librenms_main $CMD