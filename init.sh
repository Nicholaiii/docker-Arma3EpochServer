#!/bin/bash

echo "Arma 3 Docker init.sh ## You are: "
id -u -n

ARMASVRPATH=/arma3
ARMAAPPID=107410

RCONPASSWORD=${RCONPASSWORD:-changemen0w}

STEAM_USERNAME=${STEAM_USERNAME:-anonymous}
STEAM_PASSWORD=${STEAM_PASSWORD:-}

# Base mods
mods[450814997]='@cba'
mods[964646083]='@acelgc'
mods[774201744]='@overthrow'
# CUP mods
mods[497660133]='@cupweapons'
mods[497661914]='@cupunits'
mods[541888371]='@cupvehicles'
# RHS mods
mods[843425103]='@rhsafrf'
mods[843577117]='@rhsusaf'
mods[843593391]='@rhsgref'
# ACE COMPAT
mods[549676314]='@ace3compatcup'
mods[773131200]='@ace3compatrhsafrf'
mods[884966711]='@ace3compatrhsgref'
mods[773125288]='@ace3compatrhsusaf'

servermods[713709341]='@advancedrappelling'
servermods[730310357]='@urbanrappelling'
servermods[891938535]='@advancedtrainsimulator'
servermods[615007497]='@advancedslingloading'

#make redis config save server database to exposed /data folder to persist data on host
# if [ -d "/data" ]; then
# 	sed -i 's@dir /var/lib/redis@dir /data@g' /etc/redis/redis.conf
# fi

#start redis
# service redis-server start

mkdir /steam
cd /steam
# install steamcmd
wget https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz
tar -zxvf steamcmd_linux.tar.gz
rm -f steamcmd_linux.tar.gz
cd ..

# build mod list
MODLIST=""
ARMASERVERMODS=""
for i in "${!servermods[@]}"
do
   MODLIST+="+workshop_download_item $ARMAAPPID $i "
   ARMASERVERMODS+="${servermods[$i]};"
done
ARMAMODS=""
for i in "${!mods[@]}"
do
   MODLIST+="+workshop_download_item $ARMAAPPID $i "
   ARMAMODS+="${mods[$i]};"
done

# install arma 3
/steam/steamcmd.sh +login $STEAM_USERNAME $STEAM_PASSWORD +force_install_dir /arma3 "+app_update 233780" $MODLIST validate +quit

# move into arma3 folder
cd $ARMASVRPATH
# try to support 64 bit...
FILE=arma3server_x64
ARCH="_x64"
if [ ! -f "$FILE" ]; then
   FILE=arma3server
   ARCH=""
fi

#link common folders
ln -s $ARMASVRPATH"/mpmissions"  $ARMASVRPATH"/MPMissions"
ln -s $ARMASVRPATH"/keys"  $ARMASVRPATH"/Keys"

# perform install of mods
for i in "${!mods[@]}"
do
	MODFILE=$ARMASVRPATH"/steamapps/workshop/content/107410/$i"
	if [ -d "$MODFILE" ]; then
		# convert to mod to lowercase
		cd $MODFILE
		ls | while read upName; do loName=`echo "${upName}" | tr '[:upper:]' '[:lower:]'`; mv "$upName" "$loName"; done
   		# install client mods
		ln -s $MODFILE $ARMASVRPATH"/"${mods[$i]}
		# copy latest key to server
		cp -a -v $ARMASVRPATH"/"${mods[$i]}"/keys/." $ARMASVRPATH"/keys"
	else
	   echo "INIT ERROR: Mod files not found for $i (${mods[$i]})"
	fi
done


for i in "${!servermods[@]}"
do
	MODFILE=$ARMASVRPATH"/steamapps/workshop/content/107410/$i"
	if [ -d "$MODFILE" ]; then
		# convert to mod to lowercase
		cd $MODFILE
		ls | while read upName; do loName=`echo "${upName}" | tr '[:upper:]' '[:lower:]'`; mv "$upName" "$loName"; done
		#install server mods
    ln -s $MODFILE $ARMASVRPATH"/"${servermods[$i]}
	else
	   echo "INIT ERROR: Mod files not found for $i"
	fi
done

# move back into arma3 folder
cd $ARMASVRPATH
#
cat << EOF > /arma3/server.cfg
hostname = "Starlight Gaming";
password = "";
passwordAdmin ="ShubNiggurath";
serverCommandPassword = "ShubNiggurath";
onUserConnected = "";
onUserDisconnected = "";
doubleIdDetected = "";
EOF


if [ -f "$FILE" ]; then
  echo "Trying"
  # echo "./$FILE -port=2302 -profiles=/sc -mod="$ARMAMODS" -serverMod="$ARMASERVERMODS" -config="/arma3/server.cfg" -name=Starlight -world=empty"
  # ./$FILE -port=2302 -profiles=/sc -mod="$ARMAMODS" -serverMod="$ARMASERVERMODS" -config="/arma3/server.cfg" -name=Starlight -world=empty #  -cfg="/arma3/sc/basic.cfg" -autoinit
    ./arma3server -port=2302 -profiles=/sc -mod=@cba;@acelgc;@cupweapons;@cupunits;@cupvehicles;@ace3compatcup;@ace3compatrhsusaf;@ace3compatrhsafrf;@overthrow;@rhsafrf;@rhsusaf;@rhsgref;@ace3compatrhsgref -serverMod=@advancedslingloading;@advancedrappelling;@urbanrappelling;@advancedtrainsimulator; -config=/arma3/server.cfg -name=Starlight -world=empty -autoinit
else
   echo "Cannot find $FILE"
fi
