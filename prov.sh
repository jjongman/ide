#!/bin/bash

# ---------------------------------------
#          General Machine Setup
# ---------------------------------------

read -p "New username:" username
read -s -p "Password:" password

apt-get update
apt-get install -y software-properties-common python-software-properties
add-apt-repository ppa:ubuntu-toolchain-r/test -y
apt-add-repository multiverse
apt-get update
apt-get dist-upgrade -y
apt-get install -y sudo
apt-get install -y git
apt-get remove -y gcc g++
apt-get install -y gcc-5 g++-5
update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-5 60 --slave /usr/bin/g++ g++ /usr/bin/g++-5

useradd $username
usermod -aG sudo $username
mkdir /home/$username
chsh -s /bin/bash $username

# Setting up VIM
apt-get -y install libncurses5-dev libgnome2-dev libgnomeui-dev libgtk2.0-dev libatk1.0-dev libbonoboui2-dev libcairo2-dev libx11-dev \
	libxpm-dev libxt-dev python-dev python3-dev ruby-dev lua5.1 lua5.1-dev libperl-dev git
apt-get -y remove vim vim-runtime gvim
cd ~
git clone https://github.com/vim/vim.git
cd vim
./configure --with-features=huge \
            --enable-multibyte \
            --enable-rubyinterp=yes \
            --enable-python3interp=yes \
            --with-python3-config-dir=/usr/lib/python3.5/config \
            --enable-perlinterp=yes \
            --enable-luainterp=yes \
            --enable-gui=gtk2 --enable-cscope --prefix=/usr
make VIMRUNTIMEDIR=/usr/share/vim/vim80
cd ~/vim
make install
update-alternatives --install /usr/bin/editor editor /usr/bin/vim 1
update-alternatives --set editor /usr/bin/vim
update-alternatives --install /usr/bin/vi vi /usr/bin/vim 1
update-alternatives --set vi /usr/bin/vim


git clone https://github.com/locpeople/vimrc /home/$username/.vim
ln -s /home/$username/.vim/vimrc /home/$username/.vimrc

chown -R $username:$username /home/$username
echo $username":"$password | chpasswd

# Updating packages
apt-get update

# ---------------------------------------
#          Apache Setup
# ---------------------------------------

# Installing Packages
apt-get install -y apache2 libapache2-mod-fastcgi apache2-mpm-worker

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
a2enmod actions fastcgi rewrite
service apache2 reload

# ---------------------------------------
#          PHP Setup
# ---------------------------------------

# Installing packages
apt-get install -y php5 php5-cli php5-fpm curl libapache2-mod-php5 php5-curl php5-mcrypt php5-xdebug

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
php5enmod mcrypt

# Triggering changes in apache
a2enconf php5-fpm
service apache2 reload

# ---------------------------------------
#          MySQL Setup
# ---------------------------------------

# Setting MySQL root user password root/root
sudo debconf-set-selections <<< 'mysql-server mysql-server/root_password password root'
sudo debconf-set-selections <<< 'mysql-server mysql-server/root_password_again password root'

# Installing packages
apt-get install -y mysql-server mysql-client php5-mysql

# ---------------------------------------
#       Tools Setup.
# ---------------------------------------
# These are some extra tools that you can remove if you will not be using them
# They are just to setup some automation to your tasks.

# Adding NodeJS from Nodesource. This will Install NodeJS Version 6 and npm
curl -sL https://deb.nodesource.com/setup_6.x | sudo -E bash -
apt-get install -y nodejs

# Installing some NPM packages
npm install -g bower gulp webpack typescript

# Install Composer
curl -s https://getcomposer.org/installer | php
mv composer.phar /usr/local/bin/composer

