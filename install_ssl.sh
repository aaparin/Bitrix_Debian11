#!/bin/bash

# Check if the script is running as root
if [ "$EUID" -ne 0 ]
  then echo "Please run as root"
  exit
fi

# Request website domain
read -p "Enter your website domain (if not, a certificate will not be obtained): " domain

# ChecK letsencrypt INSTALL
if [ -f /usr/bin/letsencrypt ]; then
    echo "Letsencrypt is installed"
else
    echo "Letsencrypt is not installed"
    echo "Installing Letsencrypt..."
    apt install certbot python3-certbot-nginx -y
fi

# Check if the domain is set
# Проверка и обновление конфигурации Nginx
nginx_conf="/etc/nginx/sites-available/$domain"
if [ ! -f "$nginx_conf" ]; then
    echo "Creating Nginx configuration for $domain..."
    cat > "$nginx_conf" <<EOL
server {
    listen 80;
    server_name $domain www.$domain;

    location / {
        proxy_pass http://localhost:8080; # измените это на нужный вам backend
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}
EOL

    ln -s "$nginx_conf" /etc/nginx/sites-enabled/
    nginx -t && systemctl reload nginx
fi

echo 'Creating SSL certificate...'
certbot --nginx -d $domain


