#!/bin/bash

# ==========================================
# Apache Access Log Monitoring Script
# ==========================================

LOG_FILE="/var/log/apache2/access.log"
THRESHOLD_MB=1024

JENKINS_URL="http://100.58.183.196:8080/job/Access-Log-S3-Backup/build"
JENKINS_USER="admin"
JENKINS_TOKEN="YOUR_JENKINS_API_TOKEN"

echo "========================================="
echo "Apache Access Log Monitoring"
echo "========================================="

# Check whether log file exists
if [ ! -f "$LOG_FILE" ]; then
    echo "ERROR: Apache access log not found: $LOG_FILE"
    exit 1
fi

# Get log size in MB
LOG_SIZE_MB=$(du -m "$LOG_FILE" | cut -f1)

echo "Log file: $LOG_FILE"
echo "Current log size: ${LOG_SIZE_MB} MB"
echo "Threshold: ${THRESHOLD_MB} MB"

# Compare log size with threshold
if [ "$LOG_SIZE_MB" -ge "$THRESHOLD_MB" ]; then

    echo "Log size exceeded threshold."
    echo "Triggering Jenkins job..."

    RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" \
        -u "${JENKINS_USER}:${JENKINS_TOKEN}" \
        "${JENKINS_URL}")

    if [ "$RESPONSE" = "201" ] || [ "$RESPONSE" = "200" ]; then
        echo "Jenkins job triggered successfully."
    else
        echo "ERROR: Failed to trigger Jenkins job."
        echo "HTTP response: $RESPONSE"
        exit 1
    fi

else

    echo "Log size is below threshold."
    echo "No Jenkins job triggered."

fi

echo "========================================="
