#!/bin/bash

# Variables
S3FILESYSLOCATION="s3://YOUR_S3_BUCKET/"
VHOSTSFOLDER="vhosts/"

# Server Folders
APACHELOCATION="/var/www/vhosts/*/"
VHOSTTMPDIR="/backups/vhosts"

# Backup Files
BACKUPFILES=1
if [[ -n "$BACKUPFILES" && "$BACKUPFILES" -gt 0 ]]; then
    for dir in $APACHELOCATION; do
        prefix=$(basename $dir)

        CURRENT_TIME=$(date +"%Y.%m.%d_%H.%M")

        # TAR the directory (with excludes)
        echo Creating tar.gz of $dir
        # Most of the non-document directories inside the vhost are excluded 
        tar -czf $VHOSTTMPDIR/$CURRENT_TIME--$prefix.tar.gz --exclude=/var/www/vhosts/$prefix/bin --exclude=/var/www/vhosts/$prefix/etc --exclude=/var/www/vhosts/$prefix/lib --exclude=/var/www/vhosts/$prefix/pd --exclude=/var/www/vhosts/$prefix/statistics --exclude=/var/www/vhosts/$prefix/tmp --exclude=/var/www/vhosts/$prefix/var --exclude=/var/www/vhosts/$prefix/anon_ftp --exclude=/var/www/vhosts/$prefix/cgi-bin --exclude=/var/www/vhosts/$prefix/error_docs --exclude=/var/www/vhosts/$prefix/lib64 --exclude=/var/www/vhosts/$prefix/private --exclude=/var/www/vhosts/$prefix/usr --exclude=/var/www/vhosts/$prefix/web_users $dir 

        # If the file is larger than 1024mb
        if [[ $(stat -c%s "$VHOSTTMPDIR/$CURRENT_TIME--$prefix.tar.gz") -ge 1024000000 ]]; then
        	# Split large files into multiple parts
        	echo $CURRENT_TIME--$prefix.tar.gz is too big. Splitting...
        	split -b 1024m $VHOSTTMPDIR/$CURRENT_TIME--$prefix.tar.gz $VHOSTTMPDIR/$CURRENT_TIME--$prefix.tar.gz.part-

        	# Remove original large tar
        	echo Done splitting. Removing $CURRENT_TIME--$prefix.tar.gz 
        	rm --force $VHOSTTMPDIR/$CURRENT_TIME--$prefix.tar.gz
        fi
    done

    # sync the tar file to Amazon
    echo Uploading backup files to $S3FILESYSLOCATION/$VHOSTSFOLDER
    s3cmd sync -r $VHOSTTMPDIR/ $S3FILESYSLOCATION/$VHOSTSFOLDER

    # Clean up the local folder, delete all files older than 6 days
    echo Removing old backups from the $VHOSTTMPDIR directory
	find $VHOSTTMPDIR -type f -mtime +6 -delete
fi