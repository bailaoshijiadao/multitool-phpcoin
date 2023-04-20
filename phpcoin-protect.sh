#!/bin/sh

CRON_LINE="cat /dev/null >  /var/www/phpcoin/tmp/phpcoin.log"
CRON_EXISTS=$(crontab -l | grep "$CRON_LINE" | wc -l)
if [ $CRON_EXISTS -eq 0 ]
then
	crontab -l | { cat; echo "*/3600 * * * * $CRON_LINE"; } | crontab -
	echo "定时清除日志任务创建成功"
else
	echo "定时清除日志任务已有"
fi

CRON_LINE="cd /var/www/phpcoin && php cli/util.php update"
CRON_EXISTS=$(crontab -l | grep "$CRON_LINE" | wc -l)

if [ $CRON_EXISTS -eq 0 ]
then
	crontab -l | { cat; echo "*/5 * * * * $CRON_LINE"; } | crontab -
	echo "定时升级创建成功"
else
	echo "定时升级已有"
fi

CRON_LINE="mysql -e \"RESET MASTER;\""
CRON_EXISTS=$(crontab -l | grep "$CRON_LINE" | wc -l)

if [ $CRON_EXISTS -eq 0 ]
then
	crontab -l | { cat; echo "*/3600 * * * * $CRON_LINE"; } | crontab -
	echo "定时清除mysql日志创建成功"
else
	echo "定时清除mysql日志已有"
fi

cat << "EOF" > /root/mysqlstart.sh
#!/bin/sh
pidof mysqld >/dev/null
if ! pidof mysqld >/dev/null 2>&1; then
    echo "At date MySQL Server was stopped"
    service mysql start
else
	echo "It is running."
fi

EOF

chmod 777 /root/mysqlstart.sh

CRON_LINE="/root/mysqlstart.sh"
CRON_EXISTS=$(crontab -l | grep "$CRON_LINE" | wc -l)

if [ $CRON_EXISTS -eq 0 ]
then
	crontab -l | { cat; echo "*/5 * * * * $CRON_LINE"; } | crontab -
	echo "定时检测mysql创建成功"
else
	echo "定时检测mysql已有"
fi

