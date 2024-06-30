#!/bin/bash

# Check if the script is running as root
if [ "$EUID" -ne 0 ]
  then echo "Please run as root"
  exit
fi


# Request website domain
read -p "Enter your website domain (if not, a certificate will not be obtained): " domain

# Request MySQL root user password
read -s -p "Enter a password for the MySQL root user: " mysql_root_password
echo

# Request MySQL user password
read -s -p "Enter a password for the MySQL user: " mysql_user_password
echo

# Request password for the pullpush module
read -s -p "Enter a password for the pullpush module: " pullpush_password
echo

# Update and install necessary packages
echo "Updating and installing necessary packages..."
apt update
apt install -y lsb-release ca-certificates apt-transport-https software-properties-common gnupg2 curl rsync

update_or_add() {
    local param="$1"
    local value="$2"
    local file="$3"

    if grep -q "^${param}=" "$file"; then
        sed -i "s|^${param}=.*|${param}=${value}|" "$file"
    else
        echo "${param}=${value}" >> "$file"
    fi
}

# Add PHP repository and install PHP
echo "Adding PHP repository and installing PHP..."
apt install -y apt-transport-https
curl -sSLo /usr/share/keyrings/deb.sury.org-php.gpg https://packages.sury.org/php/apt.gpg
sh -c 'echo "deb [signed-by=/usr/share/keyrings/deb.sury.org-php.gpg] https://packages.sury.org/php/ $(lsb_release -sc) main" > /etc/apt/sources.list.d/php.list'
apt update
apt install php8.3 php8.3-cli php8.3-common php8.3-gd php8.3-ldap php8.3-mbstring php8.3-mysql php8.3-opcache php-pear php8.3-apcu php-geoip php8.3-mcrypt php8.3-memcache php8.3-zip php8.3-pspell php8.3-xml -y

# Install Nginx
echo "Installing Nginx..."
apt install nginx -y

# Install MC
echo "Installing MC..."
apt install mc -y

# Install MariaDB
echo "Installing MariaDB..."
apt -y install mariadb-server mariadb-common

#install nodejs
echo "Installing NodeJS..."
apt install nodejs npm -y

# install Redis
echo "Installing Redis..."
apt install redis -y

# Make a directory for the website
echo "Making a directory for the website..."
mkdir /var/www/html/bx-site

# Set permissions for the website directory
echo "Setting permissions for the website directory..."
chown -R www-data:www-data /var/www/html/bx-site

# Create a new Nginx configuration file
echo "Creating a new Nginx configuration file..."
rsync -av config/nginx/ /etc/nginx/

echo "127.0.0.1 push httpd" >> /etc/hosts

systemctl stop apache2
# Start and enable Nginx
systemctl --now enable nginx

# setup php
echo "Setting up PHP..."
#chech php 8.3 install
if [ -d /etc/php/8.3 ]; then
    echo "PHP 8.3 is installed"
else
    echo "PHP 8.3 is not installed"
    exit
fi
rsync -av config/php/ /etc/php/8.3/

#Configure apache

echo "Configuring Apache..."
rsync -av config/apache/ /etc/apache2/
a2dismod --force autoindex
a2enmod rewrite
systemctl --now enable apache2

# Configure MariaDB

echo "Configuring MariaDB..."
rsync -av config/mysql/ /etc/mysql/
systemctl --now enable mariadb
systemctl restart mariadb

mysql_secure_installation

#configure redis
echo "Configuring Redis..."
rsync -av config/redis/ /etc/redis/
systemctl enable redis-server.service
systemctl restart redis-server.service

# Configure pullpush

echo "Configuring pullpush..."
cd /opt
wget https://repo.bitrix.info/vm/push-server-0.3.0.tgz
npm install --production ./push-server-0.3.0.tgz

ln -sf /opt/node_modules/push-server/etc/push-server /etc/push-server
cd /opt/node_modules/push-server
cp etc/init.d/push-server-multi /usr/local/bin/push-server-multi
mkdir /etc/sysconfig
cp etc/sysconfig/push-server-multi  /etc/sysconfig/push-server-multi
cp etc/push-server/push-server.service  /etc/systemd/system/
ln -sf /opt/node_modules/push-server /opt/push-server

CONFIG_FILE="/etc/sysconfig/push-server-multi"

NEW_GROUP="www-data"
NEW_SECURITY_KEY="${pullpush_password}"
NEW_RUN_DIR="/tmp/push-server"
NEW_REDIS_SOCK="/var/run/redis/redis.sock"

update_or_add "GROUP" "$NEW_GROUP" "$CONFIG_FILE"
update_or_add "SECURITY_KEY" "$NEW_SECURITY_KEY" "$CONFIG_FILE"
update_or_add "RUN_DIR" "$NEW_RUN_DIR" "$CONFIG_FILE"
update_or_add "REDIS_SOCK" "$NEW_REDIS_SOCK" "$CONFIG_FILE"

echo "File" $CONFIG_FILE "has been configured"

useradd -g www-data bitrix

/usr/local/bin/push-server-multi configs pub
/usr/local/bin/push-server-multi configs sub

echo 'd /tmp/push-server 0770 bitrix www-data -' > /etc/tmpfiles.d/push-server.conf
systemd-tmpfiles --remove --create

[[ ! -d /var/log/push-server ]] && mkdir /var/log/push-server
chown bitrix:www-data /var/log/push-server

SERVICE_FILE="/etc/systemd/system/push-server.service"

NEW_USER="bitrix"
NEW_GROUP="www-data"
NEW_EXECSTART="/usr/local/bin/push-server-multi systemd_start"
NEW_EXECSTOP="/usr/local/bin/push-server-multi stop"

update_or_add "User" "$NEW_USER" "$SERVICE_FILE"
update_or_add "Group" "$NEW_GROUP" "$SERVICE_FILE"
update_or_add "ExecStart" "$NEW_EXECSTART" "$SERVICE_FILE"
update_or_add "ExecStop" "$NEW_EXECSTOP" "$SERVICE_FILE"

echo "File" $SERVICE_FILE "has been configured"

systemctl daemon-reload

systemctl --now enable push-server

# install portal
echo "Installing Bitrix24..."
cd /var/www/html/bx-site
wget https://www.bitrixsoft.com/download/portal/en_bitrix24_encode.zip
unzip en_bitrix24_encode.zip -d /var/www/html/bx-site
rm en_bitrix24_encode.zip
chown -R www-data:www-data /var/www/html/bx-site