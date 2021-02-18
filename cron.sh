#!/usr/bin/env bash

if [ ! -f /ark/config/crontab ]; then
	echo "Creating crontab..."
	cat << EOF >> /ark/config/crontab
# Example of job definition:
# .---------------- minute (0 - 59)
# |  .------------- hour (0 - 23)
# |  |  .---------- day of month (1 - 31)
# |  |  |  .------- month (1 - 12) OR jan,feb,mar,apr ...
# |  |  |  |  .---- day of week (0 - 6) (Sunday=0 or 7) OR sun,mon,tue,wed,thu,fri,sat
# |  |  |  |  |
# *  *  *  *  * user-name  command to be executed
# Examples for Ark:
# 0 * * * * arkmanager update				# update every hour
# */15 * * * * arkmanager backup			# backup every 15min
# 0 0 * * * arkmanager backup				# backup every day at midnight
*/30 * * * * arkmanager update --update-mods --warn --saveworld
10 */8 * * * arkmanager saveworld && arkmanager backup
15 10 * * * arkmanager restart --warn --saveworld
EOF
fi

# If there is uncommented line in the file
CRONNUMBER=`grep -v "^#" /ark/config/crontab | wc -l`
if [ $CRONNUMBER -gt 0 ]; then
	echo "Starting cron service..."
	systemctl start cron
	
	echo "Loading crontab..."
	# We load the crontab file if it exist.
	crontab /ark/config/crontab
else
	echo "No crontab set."
fi
