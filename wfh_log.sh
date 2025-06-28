#!/bin/env bash
# wfh_log.sh - Run a Query on the wfh_log.sqlite database
# Usage: wfh_log
# For debugging, uncomment the following line
# set -euxo pipefail
# todo:

cd $HOME

RCOL='\e[0m'
RED='\e[0;31m'
GRE='\e[0;32m'

# Run a query on the wfh_log.sqlite database
get_last_ten ()
{
  MAXID=$(sqlite3 $HOME/wfh_log.sqlite "SELECT MAX(id) FROM wfh_log;" \
    2>/dev/null)
  RATEQUERY="SELECT rate FROM wfh_rate ORDER BY start_date DESC LIMIT 1;"
  RATE=$(sqlite3 $HOME/wfh_log.sqlite "$RATEQUERY" 2>/dev/null)
  QUERY="SELECT * FROM view_log;"
  RESULT=$(sqlite3 $HOME/wfh_log.sqlite "$QUERY" -box 2>/dev/null)
  echo "$RESULT"
}

start_log() {
  QUERY="SELECT (id) FROM wfh_log WHERE finish_time IS NULL LIMIT 1;"
  RESULT=$(sqlite3 $HOME/wfh_log.sqlite "$QUERY" 2>/dev/null)
  echo
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
    echo -e "${RED}Log already in progress${RCOL}"
    echo -n1 -s -p "Press any key to continue"
    return
  fi
}

finish_log() {
  QUERY="SELECT (id) FROM wfh_log WHERE finish_time IS NULL LIMIT 1;"
  RESULT=$(sqlite3 $HOME/wfh_log.sqlite "$QUERY" 2>/dev/null)
  if [ "$RESULT" == "" ]; then
    echo -e "${RED}No log to finish${RCOL}"
    echo -n1 -s -p "Press any key to continue"
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
  echo -e "${GRE}Log finished at $(date -d @$FINISHTIME)${RCOL}"
  echo -n1 -s -p "Press any key to continue"
  return 0
}

modify_start_time() {
  QUERY="SELECT start_time FROM wfh_log WHERE id = (SELECT MAX(id) FROM wfh_log);"
  RESULT=$(sqlite3 $HOME/wfh_log.sqlite "$QUERY" 2>/dev/null)
  if [ "$RESULT" == "" ]; then
    echo -e "${RED}No log to modify${RCOL}"
    echo -n1 -s -p "Press any key to continue"
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
  echo -e "${GRE}Log started at $(date -d @$STARTTIME)${RCOL}"
  echo -n1 -s -p "Press any key to continue"
  return 0
}

modify_end_time() {
  QUERY="SELECT finish_time FROM wfh_log WHERE id = (SELECT MAX(id) FROM wfh_log);"
  RESULT=$(sqlite3 $HOME/wfh_log.sqlite "$QUERY" 2>/dev/null)
  if [ "$RESULT" == "" ]; then
    echo -e "${RED}No log to modify${RCOL}"
    echo -n1 -s -p "Press any key to continue"
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
  echo -e "${GRE}Log finished at $(date -d @$ENDTIME)${RCOL}"
  echo -n1 -s -p "Press any key to continue"
  return 0
}

export_data() {
  # Check if ssconvert is available
  if ! SSCONVERT=$(type -P ssconvert) 2>/dev/null; then
    echo -e "${RED}ssconvert is not available. Please install Gnumeric to export data to Excel.${RCOL}"
    read -n1 -s -p "Press any key to continue"
    return 1
  fi
  # Get the starting and ending date for previous fiscal year
  STARTYEAR=$(echo -e "$(date +%Y) - 1" | bc)
  STARTDATE=$(date -d "$STARTYEAR-07-01" +%F)
  read -e -i "$STARTDATE" -p "Enter the Starting Date for export: " STARTDATE
  STARTDATE=$(date -d "$STARTDATE" +%s)
  ENDYEAR=$(echo -e "$(date +%Y)")
  ENDDATE=$(date -d "$ENDYEAR-06-30" +%F)
  read -e -i "$ENDDATE" -p "Enter the Ending Date for export: " ENDDATE
  ENDDATE=$(date -d "$ENDDATE" +%s)
  OUTFILE="WFH-$ENDYEAR.xlsx"
  QUERY="SELECT date(start_time, 'unixepoch', 'localtime') AS 'Date', "
  QUERY="$QUERY strftime('%H:%M', start_time, 'unixepoch', 'localtime') AS 'Start', "
  QUERY="$QUERY strftime('%H:%M', finish_time, 'unixepoch', 'localtime') AS 'Finish', "
  QUERY="$QUERY printf('%.2f', (finish_time - start_time) / 3600.0) AS 'Hours', "
  QUERY="$QUERY reason AS 'Reason' "
  QUERY="$QUERY FROM wfh_log WHERE start_time >= $STARTDATE AND "
  QUERY="$QUERY finish_time <= $ENDDATE ORDER BY id;"
  RESULT=$(sqlite3 -csv -header $HOME/wfh_log.sqlite "$QUERY" | $SSCONVERT -T Gnumeric_Excel:xlsx fd://0 $HOME/$OUTFILE 2>/dev/null)
  echo -e "${GRE}Exported data to $OUTFILE${RCOL}"
  read -n1 -s -p "Press any key to continue"
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
  echo "X. Export Previous Fiscal Year to CSV"
  echo "Q. Quit"
  echo ""

  read -n1 -s -p "Choice: " CHOICE
  case $CHOICE in
    q|Q)
      break
    ;;
    s|S)
      echo ""
      start_log
    ;;
    f|F)
      echo ""
      finish_log
    ;;
    d|D)
      QUERY="DELETE FROM wfh_log WHERE id = (SELECT MAX(id) FROM wfh_log);"
      RESULT=$(sqlite3 $HOME/wfh_log.sqlite "$QUERY" 2>/dev/null)
    ;;
    m|M)
      echo ""
      modify_start_time
    ;;
    e|E)
      echo ""
      modify_end_time
    ;;
    x|X)
      echo ""
      export_data
    ;;
    *)
      echo -e "${RED}Invalid choice${RCOL}"
      echo -n1 -s -p "Press any key to continue"
    ;;
  esac
done
echo ""
exit 0
