#!/bin/bash

DATE=$(date +%F_%H-%M-%S)
LOGDIR="./log"
LOGFILE="$LOGDIR/$DATE.json"
SECTION_NO=$1
SECTION="rhel8cis_section${SECTION_NO}=true"
PTY_SECTION="section${SECTION_NO}"

#ANSIBLE_STDOUT_CALLBACK=json ansible-playbook site.yml --check -e $SECTION -t $PTY_SECTION -t level1-server | tee -a $LOGFILE
echo "Beginning script"

if [[ $1 == all ]]; then
  EXTRA_VARS=""
  for i in {1..6}; do
     EXTRA_VARS="$EXTRA_VARS -e rhel8cis_section${i}=true"

  echo "loop EXTRA_VARS${i}"
  done

  ANSIBLE_STDOUT_CALLBACK=json ansible-playbook site.yml --check $EXTRA_VARS -t level1-server | tee -a $LOGFILE
echo 'playbook execution with "all"'

else
  ANSIBLE_STDOUT_CALLBACK=json ansible-playbook site.yml --check -e "$SECTION" -t level1-server_${PTY_SECTION} | tee -a $LOGFILE
fi
echo "playbook execution with \"${SECTION}\""

#HOST=$(grep -rw '172.17.225' $LOGFILE | head -1 | awk -F'"' '{print $2}')
HOST=$(jq -r '.plays[0].tasks[0].hosts | keys[]' "$LOGFILE" | head -1)

#jq -r --arg host "$HOST" '.plays[].tasks[] | select(.hosts.[$host].changed == true or .hosts.[$host].failed == true or .hosts.[$host].ignored == true) | .task.name' $LOGFILE > "$LOGDIR/${DATE}_${HOST}_${PTY_SECTION}.txt"

for host in $(jq -r '.plays[].tasks[].hosts | keys[]' "$LOGFILE" | sort -u); do
  jq -r --arg host "$host" '
    .plays[].tasks[]
    | select(.hosts[$host] | {changed,failed,ignored} | to_entries | any(.value == true))
    | .task.name
  ' "$LOGFILE" > "$LOGDIR/${DATE}_${host}_${PTY_SECTION}.txt"
done
