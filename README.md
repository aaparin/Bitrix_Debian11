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

## Check ports
ss -tuln | grep -E ':22|:80|:443|:8890|:8891|:8893|:8894|:5222|:5223'
