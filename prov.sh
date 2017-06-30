#!/bin/bash

# ---------------------------------------
#          General Machine Setup
# ---------------------------------------

read -p "New username:" username
read -s -p "Password:" password

apt-get update
apt-get install software-properties-common python-software-properties
apt-add-repository multiverse
apt-get update
apt-get dist-upgrade -y
apt-get install -y sudo
apt-get install -y git
useradd $username
usermod -aG sudo $username
mkdir /home/$username

# Setting up VIM
git clone https://github.com/locpeople/vimrc /home/$username/.vim
ln -s /home/$username/.vim/vimrc /home/$username/.vimrc

chown -R $username:$username /home/$username
echo $username":"$password | chpasswd

# Updating packages
sudo apt-get update

# ---------------------------------------
#          Apache Setup
# ---------------------------------------

# Installing Packages
sudo apt-get install -y apache2 libapache2-mod-fastcgi apache2-mpm-worker

# Add ServerName to httpd.conf
sudo sh -c "echo "ServerName localhost" > /etc/apache2/httpd.conf"
# Setup hosts file
VHOST=$(cat <<EOF
<VirtualHost *:80>
  DocumentRoot "/var/www/public"
  <Directory "/var/www/public">
    AllowOverride All
  </Directory>
</VirtualHost>
EOF
)
sudo sh -c 'echo "${VHOST}" > /etc/apache2/sites-enabled/000-default.conf'

# Loading needed modules to make apache work
sudo a2enmod actions fastcgi rewrite
sudo service apache2 reload

# ---------------------------------------
#          PHP Setup
# ---------------------------------------

# Installing packages
sudo apt-get install -y php5 php5-cli php5-fpm curl libapache2-mod-php5 php5-curl php5-mcrypt php5-xdebug

#Enabling xdebug
sudo bash -c "cat > /etc/php5/apache2/php.ini" << EOL
	zend_extension='/usr/lib/php5/20121212/xdebug.so'
    xdebug.remote_enable=on
EOL

# Creating the configurations inside Apache
sudo sh -c "cat > /etc/apache2/conf-available/php5-fpm.conf" << EOL
<IfModule mod_fastcgi.c>
    AddHandler php5-fcgi .php
    Action php5-fcgi /php5-fcgi
    Alias /php5-fcgi /usr/lib/cgi-bin/php5-fcgi
    FastCgiExternalServer /usr/lib/cgi-bin/php5-fcgi -socket /var/run/php5-fpm.sock -pass-header Authorization

    # NOTE: using '/usr/lib/cgi-bin/php5-cgi' here does not work,
    #   it doesn't exist in the filesystem!
    <Directory /usr/lib/cgi-bin>
        Require all granted
    </Directory>

</IfModule>
EOL

# Enabling php modules
sudo php5enmod mcrypt

# Triggering changes in apache
sudo a2enconf php5-fpm
sudo service apache2 reload

# ---------------------------------------
#          MySQL Setup
# ---------------------------------------

# Setting MySQL root user password root/root
sudo debconf-set-selections <<< 'mysql-server mysql-server/root_password password root'
sudo debconf-set-selections <<< 'mysql-server mysql-server/root_password_again password root'

# Installing packages
sudo apt-get install -y mysql-server mysql-client php5-mysql
