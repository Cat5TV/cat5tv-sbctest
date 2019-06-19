#!/bin/bash
echo "Installing LAMP stack..."

# Update apt repositories
sudo apt update > /dev/null 2>&1

# Install the LAMP base
yes | sudo apt install apache2 php7.3 php7.3-cli php7.3-common php7.3-curl php7.3-gd php7.3-json php7.3-mbstring php7.3-mysql php7.3-opcache php7.3-phpdbg php7.3-readline php7.3-sqlite3 php7.3-xml libapache2-mod-php7.3 libargon2-1 libsodium23 php-curl php-rrd mariadb-server libapache2-mod-security2 modsecurity-crs

# Add a root password to MySQL
sudo mysql_secure_installation

# Enable PHP 7.3
sudo a2dismod mpm_event
sudo a2enmod php7.3
systemctl restart apache2

echo "Done."
