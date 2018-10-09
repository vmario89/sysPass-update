# sysPass-Update

A simple bash script to update a sysPass Installation

Usage:

```
cd /opt
git clone https://leyghis.fablabchemnitz.de:8444/MarioVoigt/sysPass-Update.git
chmod +x /opt/sysPass-Update/update.sh

#Update to latest commit of branch devel-3.0
COMMIT=$(git ls-remote https://github.com/nuxsmin/sysPass.git refs/heads/devel-3.0|cut -c-40)
/opt/sysPass-Update/update.sh -ci=$COMMIT -su=syspass -p=/var/www/vhosts/pw.thedomain.de
```

Ideas:
* automate frontend upgrade by using headless CLI tools like cURL