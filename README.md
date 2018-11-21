# sysPass-Update

A simple bash script to update a sysPass Installation

Usage:

```
cd /opt
git clone https://github.com/vmario89/sysPass-update.git
chmod +x /opt/sysPass-Update/update.sh

#Update to latest commit of branch 3.0
COMMIT=$(git ls-remote https://github.com/nuxsmin/sysPass.git refs/heads/3.0|cut -c-40)
/opt/sysPass-Update/update.sh -ci=$COMMIT -su=syspass -p=/var/www/vhosts/pw.yourdomain.de
```

You can also use fixed commit id from a release. For example: the version "3.0.0.18111901-rc3" has commit id=afdfa80 (shortened form)

Ideas:
* automate frontend upgrade by using headless CLI tools like cURL
