#!/bin/bash

for i in "$@"
do
case $i in
    -ci=*|--commit-id=*)
    COMMITID="${i#*=}"
    shift # past argument=value
    ;;
    -p=*|--path=*)
    APP_PATH="${i#*=}"
    shift # past argument=value
    ;;
    -su=*|--syspassuser=*)
    SPUSER="${i#*=}"
    shift # past argument=value
    #--default)
    #--default)
    #DEFAULT=YES
    #shift # past argument with no value
    ;;
    *)
          # unknown option
    ;;
esac
done
#if [[ -n $1 ]]; then
#    echo "Unassignable commandline arguments:"
#    tail -1 $1
#fi

if [ -z "$COMMITID" ]; then
        echo "-ci parameter required! > set a commit id of any branch you like to checkout"
        exit
fi

if [ -z "$APP_PATH" ]; then
        echo "-p parameter required! > target path (for example /var/www/vhosts/yourdomain.de)"
        exit
fi

if [ -z "$SPUSER" ]; then
        echo "-su parameter required! > sysPass Linux OS User (sysPass)"
        exit
fi

printf "Check installed libraries - they are needed for composer module updates and to run sysPass\n"
ALL_LIBRARIES_OKAY=1 #init value
for LIBRARY in libapache2-mod-php7.2 libsodium23 php7.2 php7.2-cli php7.2-common php7.2-json php7.2-opcache php7.2-readline php7.2-curl php7.2-mysql php7.2-curl php7.2-gd php7.2-json php7.2-ldap php7.2-mbstring php7.2-xml php-xdebug gettext; do #gettext is not directly required but used to generate editable language file (POedit)
        printf "Checking existence of '$LIBRARY'\n"
    dpkg -s $LIBRARY > /dev/null 2>&1 #Check if library is installed. If this is the case it should return error code = 0
    if [[ $? != 0 ]]; then
        printf "      > '$LIBRARY' is not installed\n"
        ALL_LIBRARIES_OKAY=0
    fi
done

if [[ $ALL_LIBRARIES_OKAY != 1 ]]; then
        printf "Missing prerequisites. Please install them and re-run the script!\n"
        exit 1
fi

#CURRENTDIR=`pwd`
CURRENTDIR=$(dirname $(readlink -f "$0"))
DATE=$(date +%Y%m%d)
BACKUPDIRNAME="$DATE"_syspass_application_backup

DBNAME=$(grep dbName "$APP_PATH"/app/config/config.xml | sed -e 's/<[^>]*>//g' | tr -d '[:space:]')
DBHOST=$(grep dbHost "$APP_PATH"/app/config/config.xml | sed -e 's/<[^>]*>//g' | tr -d '[:space:]')
DBPORT=$(grep dbPort "$APP_PATH"/app/config/config.xml | sed -e 's/<[^>]*>//g' | tr -d '[:space:]')
DBUSER=$(grep dbUser "$APP_PATH"/app/config/config.xml | sed -e 's/<[^>]*>//g' | tr -d '[:space:]')
DBPASS=$(grep dbPass "$APP_PATH"/app/config/config.xml | sed -e 's/<[^>]*>//g' | tr -d '[:space:]')

#echo $DBUSER@$DBHOST:$DBPORT/$DBNAME

echo "Creating MariaDB backup"
if [[ -f "$CURRENTDIR"/"$DATE"_"$DBNAME"_db_backup.sql ]]; then
        echo "Backup "$CURRENTDIR"/"$DATE"_"$DBNAME"_db_backup.sql already exists! Please rename or remove it ..."
        exit 1
fi
mysqldump --user=$DBUSER --password=$DBPASS --host=$DBHOST --port=$DBPORT $DBNAME > "$CURRENTDIR"/"$DATE"_"$DBNAME"_db_backup.sql
if [[ ! -f "$CURRENTDIR"/"$DATE"_"$DBNAME"_db_backup.sql ]]; then
        echo "Creation of MariaDB backup failed ..."
        exit 1
fi

echo "Making copy of application files ..."
if [[ -d "$CURRENTDIR"/"$BACKUPDIRNAME" ]]; then
        echo "Backup "$CURRENTDIR"/"$BACKUPDIRNAME" already exists! Please rename or remove it ..."
        exit 1
fi
cp -R "$APP_PATH" "$CURRENTDIR"/"$BACKUPDIRNAME"
if [[ ! -d "$CURRENTDIR"/"$BACKUPDIRNAME" ]]; then
        echo "Backup of application files failed ..."
        exit 1
fi

echo "Checking out sysPass repository with provided commit id ..."
if [ ! -d "cd /tmp/sysPass" ]; then
        mkdir -p /tmp/sysPass
        cd /tmp/
        git clone https://github.com/nuxsmin/sysPass.git
fi
cd /tmp/sysPass
git stash drop
git stash
git pull
git reset --hard
git checkout $COMMITID

echo "Syncing new files from /tmp/sysPass to target directory ..."
rsync -a ./ "$APP_PATH"/ --delete-after

echo "Copying back config files from backup directory to target directory ..."
rsync -a "$CURRENTDIR"/"$BACKUPDIRNAME"/app/config/ "$APP_PATH"/app/config/

echo "Re-Overwriting config files from git repo to current syspass instance ..."
#this will maintain log files
rsync -a ./app/config/ "$APP_PATH"/app/config/

cd "$APP_PATH"/
#pwd

#give temporary write rights
#chown -R $SPUSER:$SPUSER "$APP_PATH"/vendor/composer.lock
#chmod -R 770 vendor/

echo "Getting Composer ..."
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

echo "Installing Composer modules ..."
php composer.phar install
php composer.phar update

chown -R www-data:$SPUSER "$APP_PATH"/
chmod -R 750 "$APP_PATH"/

echo "Removing Cache (there should be no cache through rsync!)..."
rm -rf "$APP_PATH"/app/cache/

echo "Restarting apache to remove old gettext translation fragments ..."
service apache2 restart

echo "Generating translation .pot file ..."
#generate current .pot file

cat <<EOT >> "$APP_PATH"/its.its
<?xml version="1.0"?>
<its:rules xmlns:its="http://www.w3.org/2005/11/its" version="1.0">
  <its:translateRule selector="/"                       translate="no"/>
  <its:translateRule selector="/actions"                translate="no"/>
  <its:translateRule selector="/actions/action"         translate="no"/>
  <its:translateRule selector="/actions/action/text"    translate="yes"/>
</its:rules>
EOT

#Make use of xgettext to create language file - this is optional and may be used to translate with poedit (https://poedit.net) or POEditor (https://poeditor.com)
#generate messages_en_US.pot for xml file actions.xml
xgettext --from-code=utf-8 -o "$APP_PATH"/messages_en_US.pot $(find "$APP_PATH"/app/resources/  \( -name "actions.xml" \) )  -F --copyright-holder=cygnux.org --package-name=syspass --package-version=3.0 --its=./its.its

#this will find all PHP Strings
#expand messages_en_US.pot by .php/.inc files, sorted by file with -F flag; key __u means language set by user; key __ means language set by system (global)
xgettext --from-code=utf-8 -o "$APP_PATH"/messages_en_US.pot -j "$APP_PATH"/messages_en_US.pot $(find .  \( -name "*.php" -o -name "*.inc" \) -not -path "./vendor/*" -not -path "./build/*" -not -path "./schemas/*" ) --language=PHP -F --copyright-holder=cygnux.org --package-name=syspass --package-version=3.0 --force-po -k__u -k__

#this will find all JavaScript strings (e.g. strings.js.inc)
xgettext --from-code=utf-8 -o "$APP_PATH"/messages_en_US.pot -j "$APP_PATH"/messages_en_US.pot $(find .  \( -name "*.js.inc" \) -not -path "./vendor/*" -not -path "./build/*" -not -path "./schemas/*" ) --language=JavaScript -F --copyright-holder=cygnux.org --package-name=syspass --package-version=3.0 --force-po -k__u -k__


echo "Version check from MariaDB:"
mysql --user=$DBUSER --password=$DBPASS --host=$DBHOST --port=$DBPORT --database=$DBNAME -e "SELECT value FROM Config WHERE parameter = 'version';"

echo "Version check from config.xml:"
grep "configVersion" "$APP_PATH"/app/config/config.xml
grep "databaseVersion" "$APP_PATH"/app/config/config.xml

echo "Creating and inserting new upgrade key ..."
NEWKEY=$(date|md5sum|cut -c-32)
sed -i "$APP_PATH"/app/config/config.xml -e "s/\(<upgradeKey>\)\(.*\)\\(<\/upgradeKey>\)/<upgradeKey>$NEWKEY<\/upgradeKey>/"

echo "The upgrade key is:"
echo $NEWKEY
echo "Double Check:"
grep "upgradeKey" "$APP_PATH"/app/config/config.xml
