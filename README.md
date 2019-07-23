# sysPass-Update

A simple bash script to update a sysPass v3 Installation

## Hints
* tested on Ubuntu systems only!
* at the moment the script does uses developer mode. If you want to force a real world production env please modify the script to
```
php composer.phar install --no-dev
```

## Installation of sysPass
The installation could be automated too most users set it up individually. So i provided some basic docs in sysPass-install.md

## Update of sysPass - Usage update.sh

```
cd /opt
git clone https://github.com/vmario89/sysPass-update.git
chmod +x /opt/sysPass-update/update.sh

#Update to latest commit of branch 3.0
COMMIT=$(git ls-remote https://github.com/nuxsmin/sysPass.git refs/heads/v3.0|cut -c-40)

#if you use some dedicated user
/opt/sysPass-update/update.sh -ci=$COMMIT -su=syspass -p=/var/www/vhosts/pw.yourdomain.de

#in case of regular www-data user
/opt/sysPass-update/update.sh -ci=$COMMIT -su=www-data -p=/var/www/vhosts/pw.yourdomain.de
```

You can also use fixed commit id from a release. For example: the version "3.0.0.18111901-rc3" has commit id=afdfa80 (shortened form)

Belonging to the version you are upgrading from you may delete old files due to refactoring:
```
cd /var/www/vhosts/pw.yourdomain.de/app/config
rm actions.xml
rm strings.js.inc
```

## Ideas
* automate frontend upgrade by using headless CLI tools like cURL
* check if the release version of syspass was correctly applied to config and database
* check if update worked properly by checking if sql schemes were applied
