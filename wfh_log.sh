#!/bin/env bash
# wfh_log - Run a Query on the wfh_log.sqlite database
# Usage: wfh_log
# For debugging, uncomment the following line
# set -euxo pipefail
# todo:

cd $HOME

# Run a query on the wfh_log.sqlite database
function get_last_ten ()
{
  MAXID=$(sqlite3 $HOME/wfh_log.sqlite "SELECT MAX(id) FROM wfh_log;" \
    2>/dev/null)
  RATEQUERY="SELECT rate FROM wfh_rate ORDER BY start_date DESC LIMIT 1;"
  RATE=$(sqlite3 $HOME/wfh_log.sqlite "$RATEQUERY" 2>/dev/null)
  QUERY="SELECT * FROM view_log;"
  RESULT=$(sqlite3 $HOME/wfh_log.sqlite "$QUERY" -box 2>/dev/null)
  echo "$RESULT"
}

function start_log() {
  QUERY="SELECT (id) FROM wfh_log WHERE finish_time IS NULL LIMIT 1;"
  RESULT=$(sqlite3 $HOME/wfh_log.sqlite "$QUERY" 2>/dev/null)
  if [ "$RESULT" == "" ]; then
    read -p "Enter a reason: " REASON
    STARTTIME=$(date +%s)
    # Round to the nearest 15 minutes
    REMAINDER=$(echo "$STARTTIME % 900" | bc)
    STARTTIME=$(echo "$STARTTIME / 900 * 900" | bc)
    if [[ $REMAINDER -gt 450 ]]; then
      STARTTIME=$(echo "$STARTTIME + 900" | bc)
    fi
    QUERY="INSERT INTO wfh_log (id, start_time, finish_time, reason) "
    QUERY="$QUERY VALUES (($MAXID + 1), $STARTTIME, NULL, '$REASON');"
    RESULT=$(sqlite3 $HOME/wfh_log.sqlite "$QUERY" 2>/dev/null)
  else
    echo "Log already in progress"
    sleep 1
    return
  fi
}

function finish_log() {
  QUERY="SELECT (id) FROM wfh_log WHERE finish_time IS NULL LIMIT 1;"
  RESULT=$(sqlite3 $HOME/wfh_log.sqlite "$QUERY" 2>/dev/null)
  if [ "$RESULT" == "" ]; then
    echo "No log to finish"
    sleep 1
    return 1
  fi
  FINISHTIME=$(date +%s)
  # Round to the nearest 15 minutes
  REMAINDER=$(echo "$FINISHTIME % 900" | bc)
  FINISHTIME=$(echo "$FINISHTIME / 900 * 900" | bc)
  if [[ $REMAINDER -gt 450 ]]; then
    FINISHTIME=$(echo "$FINISHTIME + 900" | bc)
  fi
  QUERY="UPDATE wfh_log SET finish_time = $FINISHTIME"
  QUERY="$QUERY WHERE id = (SELECT MAX(id) FROM wfh_log);"
  RESULT=$(sqlite3 $HOME/wfh_log.sqlite "$QUERY" 2>/dev/null)
  echo "Log finished at $(date -d @$FINISHTIME)"
  return 0
}

function modify_start_time() {
  QUERY="SELECT start_time FROM wfh_log WHERE id = (SELECT MAX(id) FROM wfh_log);"
  RESULT=$(sqlite3 $HOME/wfh_log.sqlite "$QUERY" 2>/dev/null)
  if [ "$RESULT" == "" ]; then
    echo "No log to modify"
    sleep 1
    return 1
  fi
  STARTSTRING=$(date '+%F %H:%M' -d @$RESULT)
  DATESTR=$(echo $STARTSTRING | cut -d' ' -f1)
  TIMESTR=$(echo $STARTSTRING | cut -d' ' -f2)
  read -p "Enter new start time (HH:MM): " REPLY
  STARTTIME=$(date +%s -d "$DATESTR $REPLY")
  QUERY="UPDATE wfh_log SET start_time = $STARTTIME"
  QUERY="$QUERY WHERE id = (SELECT MAX(id) FROM wfh_log);"
  RESULT=$(sqlite3 $HOME/wfh_log.sqlite "$QUERY" 2>/dev/null)
  echo "Log started at $(date -d @$STARTTIME)"
  return 0
}

function modify_end_time() {
  QUERY="SELECT finish_time FROM wfh_log WHERE id = (SELECT MAX(id) FROM wfh_log);"
  RESULT=$(sqlite3 $HOME/wfh_log.sqlite "$QUERY" 2>/dev/null)
  if [ "$RESULT" == "" ]; then
    echo "No log to modify"
    sleep 1
    return 1
  fi
  ENDSTRING=$(date '+%F %H:%M' -d @$RESULT)
  DATESTR=$(echo $ENDSTRING | cut -d' ' -f1)
  TIMESTR=$(echo $ENDSTRING | cut -d' ' -f2)
  read -p "Enter new end time (HH:MM): " REPLY
  ENDTIME=$(date +%s -d "$DATESTR $REPLY")
  QUERY="UPDATE wfh_log SET finish_time = $ENDTIME"
  QUERY="$QUERY WHERE id = (SELECT MAX(id) FROM wfh_log);"
  RESULT=$(sqlite3 $HOME/wfh_log.sqlite "$QUERY" 2>/dev/null)
  echo "Log finished at $(date -d @$ENDTIME)"
  return 0
}

# Loop until the user quits
while true; do
  clear
  get_last_ten
  echo ""
  echo "S. Start a new log"
  echo "F. Finish the current log"
  echo "D. Delete the latest log entry"
  echo "M. Modify latest start time"
  echo "E. Modify latest finish time"
  echo "Q. Quit"
  echo ""

  read -p "Choice: " CHOICE
  case $CHOICE in
    q|Q)
      break
    ;;
    s|S)
      start_log
    ;;
    f|F)
      finish_log
    ;;
    d|D)
      QUERY="DELETE FROM wfh_log WHERE id = (SELECT MAX(id) FROM wfh_log);"
      RESULT=$(sqlite3 $HOME/wfh_log.sqlite "$QUERY" 2>/dev/null)
    ;;
    m|M)
      modify_start_time
    ;;
    e|E)
      modify_end_time
    ;;
    *)
      echo "Invalid choice"
      sleep 1
    ;;
  esac
  exit 0
done
