#!/usr/bin/env bash

echo "###########################################################################"
echo "# Ark Server - " `date`
echo "###########################################################################"

# Change the UID if needed
[ ! "$(id -u steam)" -eq "$UID" ] && echo "Changing steam uid to $UID." && usermod -o -u "$UID" steam ;
# Change gid if needed
[ ! "$(id -g steam)" -eq "$GID" ] && echo "Changing steam gid to $GID." && groupmod -o -g "$GID" steam ;

# Put steam owner of directories (if the uid changed, then it's needed)
echo "Ensuring correct permissions..."
chown -R steam:steam /ark /home/steam /etc/arkmanager /arkserver

# Add Ark Manager to Path
export PATH=$PATH://etc/arkmanager/://etc/arkmanager/

# avoid error message when su -p (we need to read the /root/.bash_rc )
chmod -R 777 /root/

# Launch run.sh with user steam (-p allow to keep env variables)
su -p - steam -c /arkserver/run.sh
