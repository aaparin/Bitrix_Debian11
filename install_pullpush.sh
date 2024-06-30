#!/bin/bash

# Check if the script is running as root
if [ "$EUID" -ne 0 ]; then
    echo "Please run as root"
    exit
fi

# Path to the configuration file
config_file="/etc/sysconfig/push-server-multi"

# Check if the configuration file exists
if [ ! -f "$config_file" ]; then
    echo "Configuration file not found!"
    exit 1
fi

# Extract the SECURITY_KEY parameter
security_key=$(grep "^SECURITY_KEY=" "$config_file" | cut -d'=' -f2- | tr -d '"')

# Check if SECURITY_KEY was found
if [ -z "$security_key" ]; then
    echo "SECURITY_KEY not found in the configuration file!"
    exit 1
fi

echo "Please add the following configuration to the Bitrix24 configuration file (/bitrix/.settings.php):"
cat <<EOL
'pull' => Array(
    'value' =>  array(
        'path_to_listener' => 'http://#DOMAIN#/bitrix/sub/',
        'path_to_listener_secure' => 'https://#DOMAIN#/bitrix/sub/',
        'path_to_modern_listener' => 'http://#DOMAIN#/bitrix/sub/',
        'path_to_modern_listener_secure' => 'https://#DOMAIN#/bitrix/sub/',
        'path_to_mobile_listener' => 'http://#DOMAIN#:8893/bitrix/sub/',
        'path_to_mobile_listener_secure' => 'https://#DOMAIN#:8894/bitrix/sub/',
        'path_to_websocket' => 'ws://#DOMAIN#/bitrix/subws/',
        'path_to_websocket_secure' => 'wss://#DOMAIN#/bitrix/subws/',
        'path_to_publish' => 'http://localhost:8895/bitrix/pub/',
        'path_to_publish_web' => 'http://#DOMAIN#/bitrix/rest/',
        'path_to_publish_web_secure' => 'https://#DOMAIN#/bitrix/rest/',
        'nginx_version' => '4',
        'nginx_command_per_hit' => '100',
        'nginx' => 'Y',
        'nginx_headers' => 'N',
        'push' => 'Y',
        'websocket' => 'Y',
        'signature_key' => '$security_key',
        'signature_algo' => 'sha1',
        'guest' => 'N',
    ),
),
EOL