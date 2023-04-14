#!/bin/bash
echo "请用root用户名登录使用"
mysql -e "use phpcoin;"
mysql -e "drop database phpcoin;"
mysql -e "CREATE DATABASE phpcoin;"
mysql -e "grant all privileges on phpcoin.* to 'phpcoin'@'localhost';"
mysql -e "FLUSH PRIVILEGES;"

read -rp "请输入数字选项并按回车键: "
cd
wget https://phpcoin.net/download/blockchain.sql.zip -O blockchain.sql.zip
unzip -o blockchain.sql.zip
cd /var/www/phpcoin

php cli/util.php importdb /root/blockchain.sql



