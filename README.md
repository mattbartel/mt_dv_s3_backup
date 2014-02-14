LAMP Server Backup to S3
========================

These scripts will back up a LAMP server to Amazon S3 using [S3 Tools](http://s3tools.org/s3cmd).  They were tested on a Media Temple DV running CentOS 5.8.  mysql_backup.sh will export all your mysql databases via mysql dump, then compress them in individual .tar.gz files.  vhosts_backup.sh will individually back up each directory inside your virtual hosts folder.  

To avoid transfer and download issues, files larger than 1GB are split.  Local backup directories get cleaned every few days, but S3 backups aren't touched after the backups get uploaded.  

Usage
---------------------

- Install S3 command line tools from [s3tools.org](http://s3tools.org/s3cmd).  Check out this post from [the able few](http://theablefew.com/lots-of-pain-for-a-little-gain-installing-amazon-s3-command-line-tools-on-centos-5-x) for a more detailed walkthrough and an explanation of some issues you might run into. 
- Save mysql_backup.sh and vhosts_backup.sh into a directory on your server like `/backups`.  
- Inside `/backups`, create subdirectories `/backups/mysql/` and `/backups/vhosts/`
- Create a read-only MySQL user to perform the database dumps:

```
CREATE USER 'backupuser'@'localhost' IDENTIFIED BY '<password>';
GRANT SELECT , RELOAD , FILE , SUPER , LOCK TABLES , SHOW VIEW ON * . * TO  'backupuser'@'localhost' IDENTIFIED BY '<password>' WITH MAX_QUERIES_PER_HOUR 0 MAX_CONNECTIONS_PER_HOUR 0 MAX_UPDATES_PER_HOUR 0 MAX_USER_CONNECTIONS 0;
flush privileges;
```

- Configure the variables in the script.  Everything you'll need to update should be near the top of the scripts under `# Variables` or `# Server Folders`. You can also change the length of time the local copies are kept by changing the value after `-mtime` near the end of the scripts. 
- Test by running them from the command line e.g. `bash mysql_backup.sh`
- Setup a cron job to run the script on the schedule you prefer. 

**WARNING:** The variables in this script contain sensitive information, take care to secure your script accordingly.  At minimum, secure your script's directory and the script itself to root:

```
chown root:root /backups/mysql_backup.sh
chmod 0700 /backups/mysql_backup.sh
chown root:root /backups/vhosts_backup.sh
chmod 0700 /backups/vhosts_backup.sh
```

Credits
-------

These scripts are loosely based on [Alex Stockwell's LAMP Server Backups to S3 with Duplicity](https://github.com/astockwell/server-backups-duplicity-s3) script, so thanks to him. (I had trouble getting Duplicity to run properly on my CentOS build, but if you're looking for a more incremental backup solution, his solution may suit you well.) 