#!/bin/bash
SNAPSERVER="labmusic"				#this is the master server
DEFAULTPLAYLIST="defaultwebradio"	#defauf playplist to play if we don't use snapcast
MPDHOST="localhost"					#the host to play webradio (e.g localhost)

ERRORCOUNTER=10
#---------------------------------------------------------------------------------
MPDCALL="/usr/bin/mpc -h $MPDHOST"	#the default mpc call



mpc -h "$SNAPSERVER" |grep "playing"
if [ "$?" == 0 ]; then
  echo "Remote Snapserver is playing - starting snapclient"
  /etc/init.d/snapclient start
else
	echo "Starting local webradio"
	$MPDCALL clear
	$MPDCALL load $DEFAULTPLAYLIST
	$MPDCALL play

	$MPDCALL |grep "playing" >/dev/null
	EXCODE="$?"

	i=0
	while [ $EXCODE -ne 0 ]
	do
		sleep 0.5
		#echo "Retry to send play"
		$MPDCALL play
		i=$[$i+1]


		if [ "$i" -gt "$ERRORCOUNTER" ]; then
			echo "could not play after $i retries - giving up"
			exit 1
		fi

		$MPDCALL |grep "playing" >/dev/null
		EXCODE="$?"

	done
fi

