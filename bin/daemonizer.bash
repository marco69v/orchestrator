#!/bin/bash

# da lanciare da riga di comando nohup ./daemonizer.bash & 
# al posto di mettere checkstatus in cron
# si dovrebbe risparmiare parecchio tempo per i job che ci mettono meno di un minuto

. ../etc/orchestrator.conf
#questo script deve loopare sulle cpu ipegnate selezionate da engines e ne verifico lo stato su delphix

# logging conf
B_LOG --file $LOG/daemonizer.log #scrivo sullo stesso file del chiamante ma possiamo volendo isolarlo
B_LOG -o false #altrimenti spara anche in stdout
LOG_LEVEL_ALL


while true; do

	if [ $( ps -ef | grep -v grep | grep $CSN) ]; then
		DEBUG "Un altro processo di $CSN è già running"
		exit 1
	else
		$OHOME/bin/checkstatus.bash
		DEBUG "eseguo $CSN"
	fi

	# uso un default di 5 secondi se non settato
	sleep ${SLEEP:-5} 

done
