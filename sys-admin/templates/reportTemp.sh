#!/bin/bash
COMMUNICATION_SERVER=$(/opt/dynatrace/oneagent/agent/tools/oneagentctl --get-server | cut -d '*' -f 2 | cut -d ';' -f 1 | cut -d '}' -f 1)
# Strips the /communication default path
COMMUNICATION_SERVER=${COMMUNICATION_SERVER%"/communication"}
METRIC_INGEST_TOKEN="{{ oneagent_metrics_token }}"
TENANT_ID=$(/opt/dynatrace/oneagent/agent/tools/oneagentctl --get-tenant)
HOST_ID=$(/opt/dynatrace/oneagent/agent/tools/oneagentctl --get-host-id)
CPU_TEMP=$(head -n 1 /sys/class/thermal/thermal_zone0/temp | xargs -I{} awk "BEGIN {printf \"%.2f\n\", {}/1000}")

curl --silent --show-error --insecure -L -X POST "${COMMUNICATION_SERVER}/e/${TENANT_ID}/api/v2/metrics/ingest" \
     -H "Authorization: Api-Token ${METRIC_INGEST_TOKEN}" \
     -H 'Content-Type: text/plain' \
     --data-raw "cpu.temperature,dt.entity.host=HOST-${HOST_ID} ${CPU_TEMP}"