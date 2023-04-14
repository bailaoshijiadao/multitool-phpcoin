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

CONFIG_FILE=config/config.inc.php
if [ ! -f "$CONFIGFILE" ]; then
  cp config/config-sample.inc.php config/config.inc.php
  sed -i "s/ENTER-DB-NAME/phpcoin/g" config/config.inc.php
  sed -i "s/ENTER-DB-USER/phpcoin/g" config/config.inc.php
  sed -i "s/ENTER-DB-PASS/phpcoin/g" config/config.inc.php
fi

cd
wget https://phpcoin.net/download/blockchain.sql.zip -O blockchain.sql.zip
read -rp "请在浏览器输入IP地址，打开网页，看到页面显示内容后再回车继续"
unzip -o blockchain.sql.zip
echo "PHPCoin: configure node"
mkdir tmp
mkdir web/apps
chown -R www-data:www-data tmp
chown -R www-data:www-data web/apps
mkdir dapps
chown -R www-data:www-data dapps
cd /var/www/phpcoin
php cli/util.php importdb /root/blockchain.sql
php cli/util.php download-apps

cd /var/www/phpcoin/scripts
chmod +x install_update.sh
./install_update.sh
