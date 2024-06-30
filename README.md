#Bitrix24 Debian 11 Installation (based on Bitrix24 Debian Installation Guide)
https://dev.1c-bitrix.ru/learning/course/index.php?COURSE_ID=32&LESSON_ID=5363&LESSON_PATH=3903.4862.20866.5360.5363
Plus email and letsencrypt installation

## Install git
apt-get update
apt-get install git

## Clone this repository
git clone https://github.com/aaparin/Bitrix_Debian11.git

## Start sh script
chmod u+x install.sh
./install.sh

## After installation

Root directory: /var/www/bx-site

Database settings:
```
table name: sitemanager
user: bitrix
password: 'your password when you wrote it during installation'
host: localhost
port: 3306
```    
If you want to install new Bitrix24 Business trial, you can run install_bx24.sh script
```
chmod u+x install_bx24.sh
./install_bx24.sh
```

### SMTP server setup:

Go to /etc/msmtprc and set your SMTP server settings

Now I use example for Gmail. You can use your own SMTP server settings.

### Letsencrypt setup:

```
chmod u+x install_ssl.sh
./install_ssl.sh
```

### Configure pull push
```
chmod u+x install_pullpush.sh
./install_pullpush.sh
```
This script return array for config. You need to copy it and paste to /var/www/bx-site/bitrix/.settings.php


## Check ports
ss -tuln | grep -E ':22|:80|:443|:8890|:8891|:8893|:8894|:5222|:5223'
