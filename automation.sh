#!/bin/sh
sudo apt update -y
myname="Sujith"
s3_bucket="upgrad-sujith"
apache_Val_1=$(dpkg --get-selections | grep apache | wc -l)
apache_Val_2=$(apt list --installed | grep apache | wc -l )
tardate=$(date "+%d%m%Y-%H%M%S")
filename="$myname-httpd-logs-$tardate.tar"
if [ $apache_Val_1 -ge 1 ] && [ $apache_Val_2 -ge 1 ]
then
echo "Apache is installed"
else
sudo apt --assume-yes install apache2
fi
service_status=$(service apache2 status | grep inactive | wc -l)
if [ $service_status = 1 ]
then
service apache2 start
echo "service was in stopped state starting now"
else
echo "Service is Running"
fi
service_state=$(systemctl is-enabled apache2)
if [ $service_state = "enabled" ]
then
echo "Service is in enabled state"
else
echo "Service was disabled and enabling now"
systemctl enable apache2
fi
tar -cvf /tmp/$filename /var/log/apache2/*.log
aws s3 cp /tmp/$filename s3://$s3_bucket/
