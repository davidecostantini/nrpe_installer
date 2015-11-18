#!/bin/sh

# Make sure only root can run our script
if [ "$(id -u)" != "0" ]; then
   echo "This script must be run as root" 1>&2
   exit 1
fi

echo "Do you really wish to install NRPE (y/n)?"
read answ
if [ "${answ,,}" != "y" ]; then
    echo "Exiting....."
    exit
fi

now="$(date +'%d-%m-%Y')"
logfile="/etc/infomentum/logs/nrpe/$now.log"

echo "START INSTALLATION  - $(date) "

echo "Installing epel"
#rpm -Uvh http://download.fedoraproject.org/pub/epel/6/x86_64/epel-release-6-8.noarch.rpm
rpm -i /tmp/epel-release-6-8.noarch.rpm
echo "-->DONE - $(date) "

echo "Installing NRPE and NAGIOS-PLUGINS - $(date) "
yum --enablerepo=epel -y install nrpe nagios-plugins
echo "-->DONE - $(date) "

echo "Set-up NAGIOS Server - $(date) "
cp /etc/nagios/nrpe.cfg /etc/nagios/nrpe.cfg_backup
sed 's/allowed_hosts=127.0.0.1/allowed_hosts=127.0.0.1, 172.16.16.209/g' /etc/nagios/nrpe.cfg_backup > /etc/nagios/nrpe.cfg
sed 's/dont_blame_nrpe=0/dont_blame_nrpe=1/g' /etc/nagios/nrpe.cfg > /etc/nagios/nrpe.cfg_backup
cp /etc/nagios/nrpe.cfg_backup /etc/nagios/nrpe.cfg
echo "-->DONE - $(date) "

#wget http://54.228.203.230:800/check.tar -O /usr/lib64/nagios/plugins/check.tar
mv /tmp/check.tar /usr/lib64/nagios/plugins/check.tar
cd /usr/lib64/nagios/plugins/ ; tar -xvf check.tar ; chmod 755 check_*  ; rm -f check.tar ; restorecon -R /usr/lib64/nagios/plugins/ ; service nrpe restart
mv /tmp/check_cpu_perf.sh /usr/lib64/nagios/plugins/

#wget http://54.228.203.230:800/nrpe.cfg -O /etc/infomentum/config/nagios/nrpe.cfg ; service nrpe restart
mv /tmp/nrpe.cfg /etc/infomentum/config/nagios/nrpe.cfg ; service nrpe restart

chmod 755 /usr/lib64/nagios/plugins/check_* ; restorecon -R /usr/lib64/nagios/plugins/  ; service nrpe restart

echo "Check SELinux and open port 5666 - $(date) "
selinux=sed -n -e 's/^.*: //p' | tr -d '[[:space:]]'
if [ $selinux -ne 'disabled' ]; then
	echo "SELinux is ENABLE, check if NRPE is working with this configuration!"
fi
echo "-->DONE - $(date) "

echo "Set NRPE to autostart at boot - $(date) "
chkconfig nrpe on
echo "-->DONE - $(date) "

echo "Reset SELinux - $(date) "
restorecon -R /usr/lib64/nagios/plugins/
echo "-->DONE - $(date) "

echo "Start NRPE - $(date) "
service nrpe restart
echo "********INSTALLATION DONE - $(date)**************"


echo "Check NRPE"
service nrpe status
