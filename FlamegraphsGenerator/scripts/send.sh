#!/usr/bin/env bash
mkdir -p timestamps

LC_ALL=C
MONGODB_PORT=5001 #Point to gunicorn
TIME_WINDOW_SECONDS="${1:-30}"

echo "[MONGODB SENDER] Going to send data every '$TIME_WINDOW_SECONDS' seconds."
while true
do
	for filename in "out"/*.data
	do
		if [ $filename == "out/*.data" ]; then
		   #Skip directory expansion failed because it was empty
		   echo "Nothing to send at " `date`
		else
		   timestamp=$(echo $filename | cut -d "/" -f 2 | cut -d "." -f 1)
		   echo "Sending" $filename "with timestamp " $timestamp
		   export TIMESTAMP=$timestamp
		   (perf script -F comm,pid,tid,cpu,time,event,ip,sym,dso -i $filename 2>/dev/null \
		   | ./FlameGraph/stackcollapse-perf.pl --pid \
		   | python3 ../src/stacks-to-jsons.py \
		   | python3 ../src/jsons-to-mongodb.py && rm $filename) &
		fi
	done
	sleep $TIME_WINDOW_SECONDS
done


