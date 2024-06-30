#!/bin/bash

# Check if the script is running as root
if [ "$EUID" -ne 0 ]; then
    echo "Please run as root"
    exit
fi

# Request website domain
read -p "Enter your website domain (if not, a certificate will not be obtained): " domain

# Check if Certbot is installed
if [ -f /usr/bin/letsencrypt ]; then
    echo "Letsencrypt is installed"
else
    echo "Letsencrypt is not installed"
    echo "Installing Letsencrypt..."
    apt update
    apt install certbot python3-certbot-nginx -y
fi

# Paths to configuration files
template_conf="config/nginx_config.conf"
nginx_conf="/etc/nginx/sites-available/$domain"

# Check if the Nginx configuration for the domain exists
if [ ! -f "$nginx_conf" ]; then
    echo "Creating Nginx configuration for $domain..."
    # Copy the template configuration file to the Nginx sites-available directory
    cp "$template_conf" "$nginx_conf"
    # Replace placeholders with the actual domain name
    sed -i "s/{{user_domain}}/$domain/g" "$nginx_conf"
    # Create a symbolic link in the sites-enabled directory
    ln -s "$nginx_conf" /etc/nginx/sites-enabled/
    # Test Nginx configuration and reload if successful
    nginx -t && systemctl reload nginx
fi

echo 'Creating SSL certificate...'
# Obtain an SSL certificate for the domain and www.domain
certbot --nginx -d $domain -d www.$domain
