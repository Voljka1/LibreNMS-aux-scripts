#!/bin/bash
set -e

docker exec librenms_main tail -n 50 /data/logs/librenms.log

