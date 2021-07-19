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
cronexists=$(ls /etc/cron.d/ | grep automation | wc -l)
fileexist=$(ls /var/www/html/ | grep inventory.html | wc -l)
filesize=$(du -sh /tmp/$filename | awk '{print $1}')
if [ $fileexist -eq 0 ]
then
touch /var/www/html/inventory.html
echo "<!DOCTYPE html>" >> /var/www/html/inventory.html
echo "<html>" >> /var/www/html/inventory.html
echo "<head>" >> /var/www/html/inventory.html
echo "<title>Page Title</title>" >> /var/www/html/inventory.html
echo "</head>" >> /var/www/html/inventory.html
echo "<body>" >> /var/www/html/inventory.html
echo "<h1>Log Type&emsp;Date Created&emsp;Type&emsp;Size</h1>" >> /var/www/html/inventory.html
echo "<p style="font-size:33px">httpd-logs&emsp;$tardate&emsp;tar&emsp;$filesize</p>" >> /var/www/html/inventory.html
echo "</body>" >> /var/www/html/inventory.html
echo "</html>" >> /var/www/html/inventory.html
else
line=$(cat /var/www/html/inventory.html | wc -l)
insertline=`expr $line - 1`
sed -i "$insertline i <p style="font-size:33px">httpd-logs&emsp;$tardate&emsp;tar&emsp;$filesize</p>" /var/www/html/inventory.html
fi
if [ $cronexists -eq 0 ]
then
sudo touch /etc/cron.d/automation
echo "0 0 * * * root /root/Automation_Project/automation.sh" > /etc/cron.d/automation
fi
