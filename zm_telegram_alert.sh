#!/bin/bash

#	Created by David Fiorenza
# 	https://github.com/TheDave1022/ZoneMinder_TelegramAlertNotifier
#	Script Version 3

# apt-get install jq is required #

# Set variables #

# Camera ID is passed from zm_telegram_alert.pl #
# Don't Edit #
camera_id=$1 

# Get the current date #
# Don't Edit #
current_date=`date '+%Y-%m-%d'`

# Uses the system default path and appends the camera id and date #
# Only change if your default path is different #
path=/var/cache/zoneminder/events/$camera_id/$current_date/ #

# Get the latest alert directory in the above path #
# Don't Edit #
latest=$(ls $path | sort -V | tail -n 1)

# Sets the alert path #
# Don't Edit #
alarmpath=$path$latest

# Set the Person Detection Percentage if using zmeventnotification #
# https://github.com/pliablepixels/zmeventnotification #
# Set this value to whatever works best. Night time detection will require a lower value #
person_detection_percentage="30"

# Set the interval in which you get notifications during an alarm in seconds #
sleep_time=5

# Check if script is already running for the camera #
# The perl script will run every second, so we want to make sure we aren't sending duplicate messages to telegram #
if [ ! -f "$alarmpath/telegram_notify_running.txt" ];
then
	# Script has is not running on this directory, add a file to no other process runs it #
	touch "$alarmpath/telegram_notify_running.txt"
else
	# Script file exists, so a process is already running. Exit #
	exit
fi

# Lets loop until the alarm clears #
while true; do
	file_count=$(ls -1 $alarmpath | wc -l) # Get the file count. We will use to to check if files are being written later #
	latestfile=$(ls $alarmpath/*-capture.jpg | tail -n 1) # Get the latest -capture.jpg file to send #
	alarm=$latestfile
	current_time=`date '+%H:%M:%S'` # Get the current time for the log #
	echo "$current_time - Motion detected!!!!" >>  "$alarmpath/telegram_notify_running.txt"
		# Send the telegram message for motion detection #
		# You can pass extra parameters if needed such as --text with a message or --silent to disable sound on a notification. See ./send-message for all parameters #
		/root/telegram-notify/send-message --photo $alarm # Send the message with the latest image #
		sleep $sleep_time
	
	# This rest of this script only applies if you are using zmeventnotification #
	current_time=`date '+%H:%M:%S'` # Get the current time for the log #
	echo "$current_time - Check for objdetect.jpg" >>  "$alarmpath/telegram_notify_running.txt"
	# Check if objdetect.jpg exists #
	if test -f $alarmpath/objdetect.jpg; then
		objectdetection=$alarmpath/objdetect.jpg # Object Detection Image File #
		objectdetection_json=$alarmpath/objects.json # Object Detection JSON File #
		person_detection=$(grep -w "person" $alarmpath/objects.json) # Search for person in the JSON file #
		detection=$(echo $person_detection)
		current_time=`date '+%H:%M:%S'` # Get the current time for the log #
		echo "$current_time - Check for person detection and enter loop if found" >>  "$alarmpath/telegram_notify_running.txt"
		echo $detection | jq '.detections[] | select(.label=="person") |.confidence ' | while IFS= read confidence;
		do
			name=$(echo "$confidence");
			tmp_value=$(echo "${name%??}") ;
			string_value=$(echo "${tmp_value:1}") ;
			current_time=`date '+%H:%M:%S'` # Get the current time for the log #
			echo "$current_time - Checking for person detection percentage" >>  "$alarmpath/telegram_notify_running.txt"
		   	if [[ "int=${string_value%.*}" -gt "$person_detection_percentage" ]];
			then
				echo $string_value;
				current_time=`date '+%H:%M:%S'` # Get the current time for the log #
				echo "$current_time - Person detected!!!" >>  "$alarmpath/telegram_notify_running.txt"
				# You can send the Person Detection alert to a different channel using the --user "CHANNEL ID" parameter at the end" #
				# Edit line 124 as well #
				/root/telegram-notify/send-message --photo $objectdetection #--user "-#########"
				break 2 # We sent an alert, we don't want to keep sending if multiple people detected in the photo. Break out of the while loop #
			fi
		done
		current_time=`date '+%H:%M:%S'` # Get the current time for the log #
		echo "$current_time - Renaming the objectdetection file" >>  "$alarmpath/telegram_notify_running.txt"
		mv $objectdetection $alarmpath/objdetect_$current_time.jpg # Rename the objdetect.jpg file to something else in case we get another tag #
		mv $objectdetection_json $alarmpath/objects_$current_time.json # Rename the objects.json file to something else in case we get another tag #
		sleep $sleep_time
	fi

	current_time=`date '+%H:%M:%S'` # Get the current time for the log #
	echo "$current_time - Checking the file count to see if alarm is still recording" >>  "$alarmpath/telegram_notify_running.txt"
	file_count_recheck=$(ls -1 $alarmpath | wc -l) # Get latest count of files to compare to start of while loop #
	if [ "$file_count" == "$file_count_recheck" ]; 
	then
		# Alarm is no longer triggered. Sleep 15 seconds. See if person detection file is created and send. Exit Script #
		current_time=`date '+%H:%M:%S'` # Get the current time for the log #`
		echo "$current_time - Video is done writting. Processing exit script" >>  "$alarmpath/telegram_notify_running.txt"
		sleep 15 # Sleep 15 seconds and wait for final object detection if it was found #
		objectdetection=$alarmpath/objdetect.jpg
		person_detection=$(grep -w "person" $alarmpath/objects.json)
		detection=$(echo $person_detection)
		current_time=`date '+%H:%M:%S'` # Get the current time for the log #
		echo "$current_time - Checking for final person detection" >>  "$alarmpath/telegram_notify_running.txt"
		echo $detection | jq '.detections[] | select(.label=="person") |.confidence ' | while IFS= read confidence;
		do
			name=$(echo "$confidence");
			tmp_value=$(echo "${name%??}") ;
			string_value=$(echo "${tmp_value:1}") ;
			current_time=`date '+%H:%M:%S'` # Get the current time for the log #
			echo "$current_time - Checking person detection percentage" >>  "$alarmpath/telegram_notify_running.txt"
			if [[ "int=${string_value%.*}" -gt "$person_detection_percentage" ]];
			then
				echo $string_value;
				echo "Person detected. Sending message" >>  "$alarmpath/telegram_notify_running.txt"
				# You can send the Person Detection alert to a different channel using the --user "CHANNEL ID" parameter at the end" #
				/root/telegram-notify/send-message --photo $objectdetection #--user "-#########"
			fi
		done
		current_time=`date '+%H:%M:%S'` # Get the current time for the log #
		echo "$current_time - Check if objdetect.jpg exists, otherwise rename the objectdetect_$current_time.jpg file back" >>  "$alarmpath/telegram_notify_running.txt"
		# if we don't have a new objdetect, then we will rename the one from earlier so we can view the detection in the admin page #
		if [ ! -f $alarmpath/objdetect.jpg ]; then
			last_objectdetect=$(ls /$alarmpath/objdetect*.jpg | sort -V | tail -n 1) 
			last_objectdetect_json=$(ls /$alarmpath/objects*.json | sort -V | tail -n 1)
			current_time=`date '+%H%M%S'`
			echo "$current_time - Renaming the file back to objdetect.jpg" >>  "$alarmpath/telegram_notify_running.txt"
			mv $last_objectdetect $alarmpath/objdetect.jpg 
			mv $last_objectdetect_json $alarmpath/objects.json
		fi
		current_time=`date '+%H:%M:%S'` # Get the current time for the log #
		echo "$current_time - Exiting the script" >>  "$alarmpath/telegram_notify_running.txt"
		exit 1
	fi
done
current_time=`date '+%H:%M:%S'` # Get the current time for the log #
echo "$current_time - Exiting the while loop, which shouldnt happen" >>  "$alarmpath/telegram_notify_running.txt"
