#!/bin/bash
#
# ownCloud
#
# @author Thomas Müller
# @copyright 2014 Thomas Müller thomas.mueller@tmit.eu
#

set -e

# read config
if [ -f ./jenkins.config ]; then
  source ./jenkins.config
  set
  if [ -z "$SLAVE_NAME" ]; then
    echo "Configuration parameter <SLAVE_NAME> is missing."
    exit
  fi
  if [ -z "$SLAVE_SECRET" ]; then
    echo "Configuration parameter <SLAVE_SECRET> is missing."
    exit
  fi
else
  echo "Configuration file <jenkins.config> is missing."
  exit
fi

# update base system
sudo apt-get update && sudo apt-get -y upgrade

# install jenkins dependencies
sudo apt-get -y install default-jre-headless git ant phpunit

# install owncloud dependencies
sudo debconf-set-selections <<< 'mysql-server mysql-server/root_password password your_password'
sudo debconf-set-selections <<< 'mysql-server mysql-server/root_password_again password your_password'
sudo apt-get -y install mysql-server postgresql
sudo apt-get -y install php5 php5-sqlite php5-pgsql php5-mysqlnd php5-gd php5-intl php5-curl php5-ldap
sudo apt-get -y install smbclient

# setup mysql
mysql -u root -pyour_password -e "CREATE DATABASE IF NOT EXISTS oc_autotest0; grant all on oc_autotest0.* to 'oc_autotest0'@'localhost' IDENTIFIED BY 'owncloud';"
mysql -u root -pyour_password -e "CREATE DATABASE IF NOT EXISTS oc_autotest1; grant all on oc_autotest1.* to 'oc_autotest1'@'localhost' IDENTIFIED BY 'owncloud';"

# install nodejs
sudo apt-get -y install curl
curl -sL https://deb.nodesource.com/setup | sudo bash -
sudo apt-get -y install nodejs

# setup work space
sudo mkdir -p /var/jenkins
sudo chown vagrant /var/jenkins

cd /var/jenkins
rm -rf slave.jar
wget --no-check-certificate https://ci.owncloud.org/jnlpJars/slave.jar

#start the slave
java -jar slave.jar -noCertificateCheck -jnlpUrl https://ci.owncloud.org/computer/$SLAVE_NAME/slave-agent.jnlp -secret $SLAVE_SECRET

