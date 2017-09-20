# typo3-save
TYPO3's backup trough ssh script 

## config file
```cp ./config.cfg.base ./config.cfg```
Modify the file to fit your needs

## cron task
```
crontab -e
* 6 * * * /bin/sh __/typo3-save/backups.sh 2>&1
```
