#!/bin/bash

# ./backupTYPO3.sh
#################################
#
# SCRIPT DE SAUVEGARDE DE TYPO3
#
# auteurs: Olivier Pommaret, Yann Bogdanovic
#
#################################

## DO NOT CHANGE, JUST PUT RIGHT VALUES IN config.cfg
# cp ./config.cfg.base ./config.cfg
source /etc/default/locale
CONFIG_FILE=config.cfg
if [ -f $CONFIG_FILE ]
	then
		source $CONFIG_FILE
	else
		echo 'No conf file !!' >> $LOGFILE
		exit 1
fi

# First of all, install dependencies
INSTALL_PKGS="curl rsync grep sed date mysql mysqldump tar rm awk"
for pkgname in $INSTALL_PKGS; do
#	dpkg -s ${pkgname} 2>/dev/null >/dev/null || sudo apt-get -y --ignore-missings install ${pkgname}
echo ${pkgname}
done



# Functions
send_to_mattermost()
{
	/usr/bin/curl -i -k -X POST -d "$(generate_post_data $1)" ${MATTERMOST_HOST}${MATTERMOST_CHANNEL}
}

generate_post_data()
{
	case $1 in
		ok)
			color="#00ff00"
			text=":thumbsup: la sauvegarde a réussie :thumbsup:."
			;;
		dump)
			color="#00ff00"
			text=":thumbsup: la sauvegarde locale a réussie :thumbsup:."
			;;
		error)
			color="#ff0000"
			text=":thumbsdown: la sauvegarde n'a pas été transferée, rsync ne c'est pas bien déroulé... :thumbsdown:."
			;;
		local)
			color="#ff0000"
			text=":thumbsdown: le répertoire pour les sauvegardes locales n'existe pas... :thumbsdown:."
			;;
		*)
			color="#ff0000"
			text=":thumbsdown: le serveur de sauvegarde n'est pas disponible :thumbsdown:."
			;;
	esac

	cat <<EOF
payload={
	"attachments":[
		{
			"color":       "$color",
			"author_name": "$AUTHOR_NAME",
			"author_link": "$AUTHOR_LINK",
			"title":       "Sauvegarde TYPO3",
			"text":        "$text"
		}
	]
}
EOF
}
####################################################################################################################
## Run it !!

# Does Local folder exists ?
if [ ! -d $LOCAL_TARGET ]; then
		echo 'No local target for backup !!' >> $LOGFILE
		send_to_mattermost "local"
		exit 1
fi

# Does the backuphost is up ?
if [ "$(ping -c 3  ${BACKUP_HOST} | grep '0 received')" ]
	then
		echo 'No backup host up !!' >> $LOGFILE
		send_to_mattermost
		exit 1
fi

# typo3-backup from Apen script
ACTUALSCRIPTPATH=$(pwd)
cd ${WEB_ROOT}
/bin/bash $ACTUALSCRIPTPATH/TYPO3-backup/save-typo3.sh -f -p "${WEB_ROOT}" -o "${LOCAL_TARGET}typo3-$(date +%Y%m%d).tar.gz"
cd $ACTUALSCRIPTPATH
send_to_mattermost 'dump'

# RSYNC
rsync -avz --remove-source-files ${LOCAL_TARGET} ${BACKUP_USER}@${BACKUP_HOST}:${BACKUP_TARGET}/$(date +%Y%m%d)/ --log-file="${LOGFILE}"
if [ "$?" -eq "0" ]
then
	send_to_mattermost "ok"
else
	send_to_mattermost "error"
fi
# That's all folks !!
