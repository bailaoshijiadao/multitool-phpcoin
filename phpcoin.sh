#!/bin/bash
echo "PHPCoin main-node Installation"
apt update
apt install apache2 php libapache2-mod-php php-mysql php-gmp php-bcmath php-curl unzip -y
apt install mysql-server git screen htop -y

mysql -e "create database phpcoin;"
mysql -e "create user 'phpcoin'@'localhost' identified by 'phpcoin';"
mysql -e "grant all privileges on phpcoin.* to 'phpcoin'@'localhost';"
mysql -e "FLUSH PRIVILEGES;"

mkdir /var/www/phpcoin
cd /var/www/phpcoin
git clone https://github.com/phpcoinn/node .

cat << "EOF" > /etc/apache2/sites-available/phpcoin.conf
<VirtualHost *:80>
        ServerAdmin webmaster@localhost
        DocumentRoot /var/www/phpcoin/web
        ErrorLog ${APACHE_LOG_DIR}/phpcoin.error.log
        RewriteEngine on
        RewriteRule ^/dapps/(.*)$ /dapps.php?url=$1
</VirtualHost>
EOF

a2dissite 000-default
a2ensite phpcoin
a2enmod rewrite
service apache2 restart


sed -i "s/# max_connections/max_connections/g" /etc/mysql/mysql.conf.d/mysqld.cnf
sed -i "s/151/999999/g" /etc/mysql/mysql.conf.d/mysqld.cnf
service mysql restart


CONFIG_FILE=config/config.inc.php
if [ ! -f "$CONFIGFILE" ]; then
  cp config/config-sample.inc.php config/config.inc.php
  sed -i "s/ENTER-DB-NAME/phpcoin/g" config/config.inc.php
  sed -i "s/ENTER-DB-USER/phpcoin/g" config/config.inc.php
  sed -i "s/ENTER-DB-PASS/phpcoin/g" config/config.inc.php
fi

echo "PHPCoin: configure node"
cd /var/www/phpcoin
mkdir tmp
mkdir web/apps
chown -R www-data:www-data tmp
chown -R www-data:www-data web/apps
mkdir dapps
chown -R www-data:www-data dapps
php cli/util.php download-apps
cd /var/www/phpcoin/scripts
chmod +x install_update.sh
./install_update.sh

cd
wget https://phpcoin.net/download/blockchain.sql.zip -O blockchain.sql.zip
read -rp "请在浏览器输入IP地址，打开网页，看到页面显示内容后再回车继续"
unzip -o blockchain.sql.zip
cd /var/www/phpcoin
php cli/util.php importdb /root/blockchain.sql


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

CRON_LINE="mysql -e \"RESET MASTER\""
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
