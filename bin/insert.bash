#!/bin/bash

# parametri necessari alla esecuzione
# $1 nome applicazione (es FAM, Q19, etc)
# $2 nome della tabella
# $3 Nome ENGINE
# $4 CPU ENGINE


# chec da implementare: valore delle CPU 
# gestire erori update per record non trovati o campi non validi

. /home/ee51732/unicredit/etc/orchestrator.conf
# logging conf
B_LOG --file $LOG/scheduler.log #scrivo sullo stesso file del chiamante ma possiamo volendo isolarlo
B_LOG -o false #altrimenti spara anche in stdout
LOG_LEVEL_INFO


if [ "$#" -ne "5" ]; then
	ERROR "chiamato insert con numero di parametri sbagliati: $@ - richiesti 5"
	#echo "devi passare 4 parametri: (A)application, (D)tabella, ENGINE, CPU e idcoda"
	exit 1
fi



# Preparazione dei campi valore per CPU 
# A nome della applicazione
# D nome della tabella
# T timestamp - proviamo in epoc allo inizio se non è poi onerosa la gesstione ma è piu comodo e preciso
# S status - i possibili valori saranno valutati una volta testato lo status di un job su dephix
# I possibile nuovo valore contenente l'id del job su delphix - al momento non usato


A=$1
D=$2
T=$(date +%s)
S="JUST_INSERTED"
ENGINE=$3
CPU=$4
IDCODA=$5

$CMD "update ENGINES set VALORE='A: $A' where NOME='$ENGINE' and chiave='$CPU' and valore like 'A:%'"
$CMD "update ENGINES set VALORE='D: $D' where NOME='$ENGINE' and chiave='$CPU' and valore like 'D:%'"
$CMD "update ENGINES set VALORE='T: $T' where NOME='$ENGINE' and chiave='$CPU' and valore like 'T:%'"
$CMD "update ENGINES set VALORE='S: $S' where NOME='$ENGINE' and chiave='$CPU' and valore like 'S:%'"
$CMD "update ENGINES set VALORE='I: $IDCODA' where NOME='$ENGINE' and chiave='$CPU' and valore like 'I:%'"


INFO "$T- aggiunto job $IDCODA alla CPU $CPU - ENGINE $ENGINE - ($A - $D)"
