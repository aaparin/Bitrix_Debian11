#!/bin/bash

# Check if the script is running as root
if [ "$EUID" -ne 0 ]
  then echo "Please run as root"
  exit
fi


# install portal
echo "Installing Bitrix24..."
cd /var/www/html/bx-site
wget https://www.bitrixsoft.com/download/portal/en_bitrix24_encode.zip
unzip en_bitrix24_encode.zip -d /var/www/html/bx-site
rm en_bitrix24_encode.zip
chown -R www-data:www-data /var/www/html/bx-site