#!/bin/bash

# parametri necessari alla esecuzione
# $1 nome applicazione (es FAM, Q19, etc)
# $2 nome della tabella
# $3 Nome ENGINE
# $4 CPU ENGINE


# chec da implementare: valore delle CPU 
# gestire erori update per record non trovati o campi non validi

. ../etc/orchestrator.conf
# logging conf
B_LOG --file $LOG/checkstatus.log #scrivo sullo stesso file del chiamante ma possiamo volendo isolarlo
B_LOG -o false #altrimenti spara anche in stdout
LOG_LEVEL_INFO


if [ "$#" -ne "5" ]; then
	ERROR "updatejob.bash - chiamato insert con numero di parametri sbagliati: $@ - richiesti 5"
	# echo "devi passare 5 parametri: (A)application, (D)tabella, ENGINE, CPU e idcoda"
	exit 1
fi


# Preparazione dei campi valore per CPU 


ENGINE=$1
CPU=$2
X=$3
S=$4
T=$5

$CMD "update ENGINES set VALORE='X: $X' where NOME='$ENGINE' and chiave='$CPU' and valore like 'X:%'"
$CMD "update ENGINES set VALORE='S: $S' where NOME='$ENGINE' and chiave='$CPU' and valore like 'S:%'"
$CMD "update ENGINES set VALORE='T: $T' where NOME='$ENGINE' and chiave='$CPU' and valore like 'T:%'"


INFO "updatejob.bash - aggiornato stato e executionid  alla CPU $CPU - ENGINE $ENGINE - ($X - $S)"
