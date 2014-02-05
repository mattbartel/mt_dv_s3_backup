#!/bin/bash

# Variables
S3FILESYSLOCATION="s3://YOUR_S3_BUCKET/"
mysqlfolder="databases/"

MUSER="YOUR_DB_USER"
MPASS="YOUR_DB_PASS"
MHOST="YOUR_DB_HOST"
MYSQL="$(which mysql)"
MYSQLDUMP="$(which mysqldump)"
GZIP="$(which gzip)"

# Server Folders
MYSQLTMPDIR="/backups/mysql"

# Dump MySQL Databases
BACKUPMYSQL=1
if [[ -n "$BACKUPMYSQL" && "$BACKUPMYSQL" -gt 0 ]]; then

	# Error handling
	if [[ -n "$BACKUPMYSQL" && "$BACKUPMYSQL" -gt 0 ]]; then
		if [[ -z "$MYSQL" || -z "$MYSQLTMPDIR" || -z "$MYSQLDUMP" || -z "$GZIP" ]]; then
			echo "Not all MySQL commands found."
			exit 2
		fi
	fi

	# Get all database names
	DBS="$($MYSQL -u$MUSER -p$MPASS -h$MHOST -Bse 'show databases')"
	# Dump databases
	for db in $DBS
	do
		if [ "$db" != "information_schema" ]; then
			echo mysqldump $db
			$MYSQLDUMP --single-transaction --opt --net_buffer_length=75000 -u$MUSER -p$MPASS -h$MHOST $db | $GZIP -9 > $MYSQLTMPDIR/$(date +"%Y.%m.%d_%H.%M")--$db.sql.gz
		fi
	done

	# Backup databases
	
	echo $MYSQLTMPDIR $S3FILESYSLOCATION/$mysqlfolder

	# Sync the file to amazon
	s3cmd sync -r $MYSQLTMPDIR/ $S3FILESYSLOCATION/$mysqlfolder

	# Cleanup local MySQL dump folder, delete all files older than 3 days
	echo "Cleaning up old MySQL Dumps"
	find $MYSQLTMPDIR -type f -mtime +3 -delete
fi