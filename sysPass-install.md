# sysPass Installation draft - Ubuntu 
This gist is just a quick draft on how to install the current syspass beta. Maybe i have forgotten something...

## Hints
* used web server: apache2
* uses revery proxy template
* uses php7.2
* used database: MariaDB

Get root user
```
sudo su
```

Create a syspass user which will own the files and run php composer
```
adduser --gecos "" --disabled-password syspass
``` 

Update
```
apt-get update && apt-get upgrade
```  
  
Install required packages
```
apt-get install apache2 apache2-utils mariadb-server
```  
  
Install php things
```
add-apt-repository ppa:ondrej/php
apt-get update
apt-get install libapache2-mod-php7.2 libsodium23 php7.2 php7.2-cli php7.2-common php7.2-json php7.2-opcache php7.2-readline php7.2-curl php7.2-mysql php7.2-curl php7.2-gd php7.2-json php7.2-ldap php7.2-mbstring php7.2-xml php-xdebug gettext
```

Make an apache web server configuration file
```
vim /etc/apache2/sites-available/pw.yourdomain.de.conf
```

Enter the following details:
```
<IfModule mod_ssl.c>
<VirtualHost *:443>
    ServerAdmin  webmaster@yourdomain.de
    ServerName   hiddensubdomain.yourdomain.de
    DocumentRoot "/var/www/vhosts/pw.yourdomain.de"
 
    ErrorLog  /var/log/apache2/error-pw.yourdomain.de.log
    CustomLog /var/log/apache2/access-pw.yourdomain.de.log combined
 
    ServerSignature On
 
    SSLEngine on
    SSLCertificateFile /etc/ssl/yourdomain.de.pem
 
        Header set Access-Control-Allow-Origin "https://pw.yourdomain.de"
 
        Alias "/inc" "/app/modules/web"
 
        <Directory "/var/www/vhosts/pw.yourdomain.de/*">
                Require all denied
                <Files "index.php">
                        Require all granted
                </Files>
                <Files "api.php">
                        Require all granted
                </Files>
        </Directory>
 
        <Directory "/var/www/vhosts/pw.yourdomain.de/public/">
                Require all granted
        </Directory>
 
        <Directory "/var/www/vhosts/pw.yourdomain.de/app/modules/web/themes/">
                Options FollowSymLinks
                AllowOverride None
                Require all granted
        </Directory>
 
        RewriteEngine on
        RewriteRule ^/$ https://leyghis.yourdomain.de:8446/index.php$1 [L,QSA]
 
</VirtualHost>
</IfModule>
```

Enable the site
```  
a2ensite pw.yourdomain.de.conf
```  
  
Copy ssl cert files to /etc/ssl
```
No command here. Please install your cert or generate one (with letsencrypt for example)
```

  
Get sysPass from repository #choose a version from release channel (https://github.com/nuxsmin/sysPass/releases)
```  
mkdir -p /var/www/vhosts/pw.yourdomain.de
mkdir -p /var/www/vhosts/pw.yourdomain.de/temp
wget https://github.com/nuxsmin/sysPass/archive/3.0.0.18073101-beta.tar.gz -O - | tar -xz
cd sysPass-3.0.0.18073101-beta
rsync -a ./ /var/www/vhosts/pw.yourdomain.de/
cd ..
rm -rf sysPass-3.0.0.18073101-beta
```
 
Install composer - https://getcomposer.org/download
```
cd /var/www/vhosts/pw.yourdomain.de/
EXPECTED_SIGNATURE="$(wget -q -O - https://composer.github.io/installer.sig)"
php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
ACTUAL_SIGNATURE="$(php -r "echo hash_file('SHA384', 'composer-setup.php');")"
if [ "$EXPECTED_SIGNATURE" != "$ACTUAL_SIGNATURE" ]
then
    >&2 echo 'ERROR: Invalid installer signature'
    rm composer-setup.php
    exit 1
fi
  
php composer-setup.php
rm composer-setup.php
 
sudo -iu syspass
php composer.phar install
exit #leave syspass user shell
```

Adjust file permissions
```  
cd /var/www/vhosts/
chown -R www-data:syspass pw.yourdomain.de/
chmod -R 750 pw.yourdomain.de/
``` 
 
Generate locale
```
sudo locale-gen en_US.UTF-8
```

Edit standard locale file
```
vim /etc/default/locale
```

Set en_US and save
```
LANG=en_US.UTF-8
```

Enable some apache modules
```
for mod in alias auth_basic auth_digest authn_core authn_file authz_core authz_groupfile authz_host authz_user autoindex deflate dir env headers mime mpm_prefork proxy_ajp proxy proxy_http rewrite socache_shmcb ssl; do a2enmod $mod; done
```

Enable php 7.2
```   
a2enmod php7.2
```

Create MariaDB admin user
```
mysql -u root
```

Create database
```
CREATE USER 'admin'@'localhost' IDENTIFIED BY 'yourPassword';GRANT ALL PRIVILES ON *.* TO 'admin'@'localhost' REQUIRE NONE WITH GRANT OPTION MAX_QUERIES_PER_HOUR 0 MAX_CONNECTIONS_PER_HOUR 0 MAX_UPDATES_PER_HOUR 0 MAX_USER_CONNECTIONS 0;
\q
```
 
Add log rotation for syspass.log - there is no apache2 reload required
```
vim /etc/logrotate.d/syspass
``` 

Enter the following details: 
```
/var/www/vhosts/pw.yourdomain.de/app/config/syspass.log
{
  rotate 10
  daily
  compress
  missingok
  notifempty
}
```

Restart apache2
```
service apache2 restart
```
 
Visit URL to install sysPass from Frontend now
https://pw.yourdomain.de/index.php?r=install/index 
