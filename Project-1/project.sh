#!/bin/bash

echo "=========================================="
echo "            LOG ANALYZER"
echo "=========================================="

# Log file locations
SYSTEM_LOG="/home/kali/Documents/system.log"
APPLICATION_LOG="/home/kali/Documents/application.log"

# Log tags
TAGS=("ERROR" "CRITICAL" "FATAL" "WARNING" "EXCEPTION")


analyze_log() {

    LOG_FILE="$1"

    echo
    echo "[$LOG_FILE]"
    echo "------------------------------------------"

    for TAG in "${TAGS[@]}"
    do
        COUNT=$(/usr/bin/grep -c "$TAG" "$LOG_FILE")

        echo "$TAG : $COUNT"

        if [ "$COUNT" -gt 0 ]; then
            /usr/bin/grep "$TAG" "$LOG_FILE"
        fi

        echo
    done
}


# Analyze System Log
if [ -f "$SYSTEM_LOG" ]; then
    analyze_log "$SYSTEM_LOG"
else
    echo "System log not found!"
fi


# Analyze Application Log
if [ -f "$APPLICATION_LOG" ]; then
    analyze_log "$APPLICATION_LOG"
else
    echo "Application log not found!"
fi


echo "=========================================="
echo "          ANALYSIS COMPLETED"
echo "=========================================="
