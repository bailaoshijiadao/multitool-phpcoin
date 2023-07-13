#!/bin/bash

if ! docker -v > /dev/null 2>&1; then
	echo "安装 dockerl 中...."
	curl -fsSL https://get.docker.com | bash -s docker --mirror Aliyun
fi

echo "拉取镜像 phpcoin/node-test 中...."
docker pull phpcoin/node-test

if [[ $(docker pa -a) =~ "phpcoin/node-test" ]]; then
	echo "已有容器 phpcoin-test"
else
	echo "开始创建容器 phpcoin-test"
	docker create --name=phpcoin-test -p 8888:80 -m 500M --memory-swap=500M --restart=always phpcoin/node-test /bin/sh -c /docker_start.sh
fi

if [[ ! -f /root/phpcoin-test.inc.php ]]; then
	docker cp phpcoin-test:/var/www/phpcoin/config/config.inc.php /root/phpcoin-test.inc.php
	
fi

docker rm phpcoin-test
docker create --name=phpcoin-test -p 8888:80 -m 500M --memory-swap=500M  --cpus 1 --restart=always -v /root/phpcoin-test.inc.php:/var/www/phpcoin/config/config.inc.php phpcoin/node-test /bin/sh -c /docker_start.sh
docker start phpcoin-test


# 创建清理容器日志任务
CRON_LINE="truncate -s 0 /var/lib/docker/containers/*/*-json.log"
CRON_EXISTS=$(crontab -l | grep "$CRON_LINE" | wc -l)
if [ $CRON_EXISTS -eq 0 ]
then
	crontab -l | { cat; echo "*/3600 * * * * $CRON_LINE"; } | crontab -
	echo "定时定时清除容器日志任务完成........."
else
	echo "已有定时容器日志清除任务........."
fi

cat /dev/null > /root/phpcoin-log.txt
mns=$(find /var/lib/docker/overlay2 -name "phpcoin" | grep "/merged/var/www/phpcoin")
echo "${mns}" >> /root/phpcoin-log.txt

cat /root/phpcoin-log.txt | while read line
do
	CRON_LINE="cat /dev/null >  ${line}/tmp/phpcoin.log"
	echo $CRON_LINE
	CRON_EXISTS=$(crontab -l | grep "$CRON_LINE" | wc -l)
	if [ $CRON_EXISTS -eq 0 ]
	then
		crontab -l | { cat; echo "*/3600 * * * * $CRON_LINE"; } | crontab -
		echo "定时定时清除容器日志任务完成........."
	else
		echo "已有定时容器日志清除任务........."
	fi
done < /root/phpcoin-log.txt

export IP=$(curl -s http://whatismyip.akamai.com/)
echo "http://$IP:8888 打开你的节点"
echo "/root/phpcoin-test.inc.php 修改配置节点文件"