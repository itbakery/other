#! /bin/bash

FREEPBX=http://mirror.freepbx.org/freepbx-2.10.0.tar.gz
PASSWORD=p4ssw0rd

echo -e ""
echo -e "\e[1;31m  -  CentOS 6.X FreePBX AutoInstall Script  -  \e[0m"
echo -e ""

echo -e "\e[1;31m  -  Disable Selinux Runtime  -  \e[0m"
sed -i 's/SELINUX=.*/SELINUX=disabled/' /etc/selinux/config


echo -e "\e[1;31m  -  Installing Linux Tools  -  \e[0m"
yum -y htop vim-enhanced


echo -e "\e[1;31m  -  Installing  Asterisk Packages  -  \e[0m"
yum -y install  asterisk  asterisk-sounds-core-en-ulaw asterisk-sqlite  asterisk-voicemail

echo -e "\e[1;31m  -  Installing Database Server  -  \e[0m"
yum install mysql-server
service mysqld start
chkconfig mysqld on

echo -e "\e[1;31m  -  FreePBX Dependencies  -  \e[0m"
yum -y install bison perl perl-CPAN audiofile-devel sox svn  sendmail sendmail-cf caching-nameserver  tftp-server  libtiff-devel  gtk2-devel 
yum -y install httpd php php-mysql php-pear  php-process php-mbstring php-mcrypt
chkconfig httpd on
service httpd start
pear install DB
pear install MDB2

echo -e "\e[1;31m  -  Installing Lame  -  \e[0m"
cd /usr/local/src
wget http://downloads.sourceforge.net/project/lame/lame/3.99/lame-3.99.5.tar.gz  
tar zxvf lame-3.99.5.tar.gz
cd lame-3.99.5
./configure
make
make install


echo -e "\e[1;31m  -  Installing FreePBX  -  \e[0m"
wget ${FREEPBX}
tar xvfz freepbx*
rm -rf *.tar.gz
cd freepbx*

echo -e "\e[1;31m  -  Setting Up Database Server  -  \e[0m"
echo "bind-address=0.0.0.0" >> /etc/my.cnf
mysql -e " DROP DATABASE test "
mysql -e " CREATE DATABASE asteriskcdrdb "
mysql -e " CREATE DATABASE asterisk "
mysql asterisk < SQL/newinstall.sql 
mysql asteriskcdrdb < SQL/cdr_mysql_table.sql 
mysql -e " GRANT ALL ON *.*  TO 'root'@'%'  IDENTIFIED BY '${PASSWORD}';"
mysql -e " GRANT ALL ON *.*  TO 'root'@'localhost'  IDENTIFIED BY '${PASSWORD}';"


echo -e "\e[1;31m  -  Installing FreePBX  -  \e[0m"
./start_asterisk start
./install_amp --username=root --password=${PASSWORD}
cd ..
rm -rf freepbx*

echo -e "\e[1;31m  -  Setting FreePBX Perms  -  \e[0m"
adduser asterisk -M -c "Asterisk User"
chown asterisk /var/run/asterisk
chown -R asterisk /etc/asterisk
chown -R asterisk /var/{lib,log,spool}/asterisk
chown -R asterisk /var/www/

echo -e "\e[1;31m  -  Setting in Apache  -  \e[0m"
sed -i 's/upload_max_filesize =.*/upload_max_filesize = 120M/' /etc/php.ini
sed -i 's/User apache/User asterisk/'  /etc/httpd/conf/httpd.conf
sed -i 's/Group apache/Group asterisk/'  /etc/httpd/conf/httpd.conf
service httpd restart


echo -e "\e[1;31m  -  Enter to your FreePBX at http://YourIP  -  \e[0m"
init 6
