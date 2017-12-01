#!/bin/bash


SSHKEY=""   		#put your SSH key here for setting your ssh key and DISABLING SSH Password login
SNAPSERVERIP=""   	#IP address of the snapcast server - warning hostname will currently not work! Leave empty for not installing snapclient


#for DEWBUG


####### don't edit below here !
#for easy debugging
DEVMAC="3243f74ae10c26cacde569c06bddd1552f47ec5e1cf8cac29de4c055"		#sha224 of the eth mac adress for automatic enabling of dev functions
THISMAC="$(ifconfig eth0|grep HWaddr|cut -d " " -f 11- |sha224sum|cut -d " " -f 1)"
if [ "$THISMAC" == "$DEVMAC" ]; then
 SSHKEY="ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEAuNOYUNmYk6HU/ooU7Lz3oun+26LLfqIv//0JjrwhFDMC3RXkQxB62KfQMIVnsto2Gmo4WPZs0U5EG4ywH6tv+I7jcmMt5HlV6ggle2Sqty4hbEpfMb6fuCt5Gt91//ahZ5YGb6MYZp5rf8vkXTZubZT2hud2pGDMKTzBa1iNRyF4hzDgBp0735Ui0nFW/nrjcYYGTRIy7Q3wbhF+USoO6gmr8041SJ6Gc3yOJEW6WZl6HDxuZJ45zxRkDANYy3T8J+jivhtqu/EXhFOT1NlOdGz3cDgjSozaeDM4PmT2tUcwvMfi4nbx/lVxfv/r40emrealVnVtg8pWrXRTF1CZOw== me@mycomputer"
 SNAPSERVERIP="192.168.0.126"
fi 

function PREP_SSH {
	if [ "$SSHKEY" != "" ]; then
		echo ""
		echo "Setup ssh keybased login"
		#for easy debugging
		mkdir -p $HOME/.ssh
		echo "$SSHKEY" >>$HOME/.ssh/authorized_keys

		#disable password login of dropbear
		cat /etc/default/dropbear | sed 's/DROPBEAR_EXTRA_ARGS=/DROPBEAR_EXTRA_ARGS="-g "/g' >/tmp/dropbear.tmp
		cat /tmp/dropbear.tmp >/etc/default/dropbear
		rm /tmp/dropbear.tmp

		#restart dropbear for imediate effect
		service dropbear restart
	fi
}


function INSTALL_NEEDED_PACKAGES {
	apt-get update
	apt-get install -y mpc	festival		#mpc: command line client for mpd
											#festival: tts
}

function UPDATE_SYSTEM {
	apt-get update
	apt-get -y upgrade
}

function INSTALL_SNAPCLIENT {
if [ "$SNAPSERVERIP" != "" ]; then
	echo ""
	echo "Installing Snapclient"
	TMPFILE="/tmp/snapclient_conf.tmp"

	cd /tmp
	wget https://github.com/badaix/snapcast/releases/download/v0.12.0/snapclient_0.12.0_armhf.deb
	dpkg -i snapclient_0.12.0_armhf.deb && rm snapclient_0.12.0_armhf.deb
	cat /etc/default/snapclient |grep -v "SNAPCLIENT_OPTS=" >$TMPFILE
	echo "" >>$TMPFILE
	echo "SNAPCLIENT_OPTS=\"-d -h $SNAPSERVERIP\"" >>$TMPFILE
	cat $TMPFILE >/etc/default/snapclient
fi
}


function FIRST_BOOT {
	echo ""
	echo "Patching /etc/rc.local original backup in /etc/rc.local.org"
	cp -a /etc/rc.local /etc/rc.local.org
	cat /etc/rc.local |grep -v "exit 0" >/tmp/rc.local 

	cat << 'EOF' >> /tmp/rc.local

echo "The IP Adress is $(sed -n 4p /DietPi/dietpi/.network)"|festival --tts

LOCKFILE="/etc/audioslave_firstboot_done"
if [ ! -f $LOCKFILE ]; then
   echo "Installation complete"|festival --tts
   echo "Making this system now read only and performing the final reboot"|festival --tts
   echo "Have great fun with your system"|festival --tts
   touch $LOCKFILE
   /root/system_readonly_prep.sh scripted
fi 

exit 0 
EOF

cat /tmp/rc.local >/etc/rc.local
rm /tmp/rc.local
}


function DOWNLOAD_READONLY_PREP {
	#this downloads the script for making the system readonly - this has to be executed by the user later
	cd $HOME
	wget https://raw.githubusercontent.com/bdynamic/raspberry_tools/release/readonly/system_readonly_prep.sh
	chmod +x system_readonly_prep.sh
}



function PREP_PRIVAT_TOOLS {
	#for easy debugging
	apt-get update
	apt-get install -y joe htop rsync
}



#
###########################################
#
#				MAIN
#
###########################################
#
#first the secruity relevant changes
PREP_SSH

#debug section
if [ "$THISMAC" == "$DEVMAC" ]; then
	echo ""
	echo "Running development scripts"
	PREP_PRIVAT_TOOLS
fi


#productive section
UPDATE_SYSTEM
INSTALL_NEEDED_PACKAGES
DOWNLOAD_READONLY_PREP
INSTALL_SNAPCLIENT
FIRST_BOOT








