# ZoneMinder_TelegramAlertNotifier

- I am not a developer. There may be better ways to implement this and if so, let me know.
- My files are all running from /root. Adjust accordingly. Edit files with your editor of choice, I use nano.
- [telegram-notify](https://github.com/samsulmaarif/telegram-notify) install instructions are linked but also detailed below
- I modified [zm-alarm.pl](https://github.com/ZoneMinder/zoneminder/blob/master/utils/zm-alarm.pl) and renamed it to keep naming consistent with my scripts.
- This will notify every 5 seconds while there is an alarm. Modify to your needs. If you want just a single notification, you can send the alarm.jpg file over instead of the -capture.jpg and set the time to be something extremely high.
- I couldn't get my script running from crontab, so I had to go the service route.
- Person detection notifications requires [zmeventnotification](https://github.com/pliablepixels/zmeventnotification). 
- jq is required to process the json for person detection

### Go to /root directory
```
cd /root
```

### Install requirements if you don't have them
```
$ apt-get install curl git jq
```

### Clone telegram-notify repository
```
$ git clone https://github.com/samsulmaarif/telegram-notify.git
```

### Edit `send-message` file, change the value line 25 `FILE_CONF` with the path of file `telegam-notify.conf`
```
$ nano /root/telegram-notify/send-message
FILE_CONF="/etc/telegram-notify.conf"
```

### Edit telegram-notify.conf and set your api-key (Bot ID) and user-id (Group or Channel ID)
```
$ nano /etc/telegram-notify.conf
```

### Create the symbolic link
```
$ ln -s /root/telegram-notify/send-message /usr/bin/telegram-notify
```

### Make send-message executable
```
$ chmod +x /root/telegram-notify/send-message
```

### You should be able to send a test message to your channel
```
$ telegram-notify --text "test"
```

### Place zm_telegram_alert.pl, zm_telegram_alert.sh, and zm_telegram_service.sh in /root
```
$ git clone https://github.com/TheDave1022/ZoneMinder_TelegramAlertNotifier.git
$ mv ZoneMinder_TelegramAlertNotifier/* /root
```

### Make shell scripts executable
```
$ chmod +x zm_telegram_alert.sh
$ chmod +x zm_telegram_service.sh
```

### Setup zm_telegram.service as a service
```
$ systemctl daemon-reload
$ systemctl enable zm_telegram.service
$ systemctl start zm_telegram.service
```

### Edit script variables - zm_telegram_alert.sh
- path - Default is "/var/cache/zoneminder/events/$camera_id/$current_date/". Only replace "/var/cache/zoneminder/events/" if you use a different location
- person_detection_percentage - Default 30%. Lower is better if you are using IR on your cameras
- sleep_time - Default is 5 seconds. Amount of time between alarm messages

### Setup a different Group/Channel message for person notifications
I mute my alarm group to avoid my telegram going off constantly. If you want to be notified on a notified group/channel you can set a different ID.
Edit lines 87 and 124 and add --user "-#########" (Replace the # with your channel/group id)

### Trigger an alert and you now should have notifications. 
You can force them through ZM or go stand in front of your camera

### You can view the service status by running
```
$ systemctl status zm_telegram.service
```

### To test triggering an alert. ex: $ ./root/zm_telegram_alert.sh 1
```
$ ./zm_telegram_alert.sh CAMERA_ID
```
