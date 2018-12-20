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


if [ "$#" -ne "2" ]; then
	ERROR "cleanupcpu.bsh - chiamato cleancpu con numero di parametri sbagliati: $@ - richiesti 2"
	#echo "devi passare 2 parametri: ENGINE e CPU"
	exit 1
fi


# Preparazione dei campi valore per CPU 
# A nome della applicazione
# D nome della tabella
# T timestamp - proviamo in epoc allo inizio se non è poi onerosa la gesstione ma è piu comodo e preciso
# S status - i possibili valori saranno valutati una volta testato lo status di un job su dephix
# X possibile nuovo valore contenente l'id del job su delphix - executionID


ENGINE=$1
CPU=$2

$CMD "update ENGINES set VALORE='A:' where NOME='$ENGINE' and chiave='$CPU' and valore like 'A: %';"
$CMD "update ENGINES set VALORE='D:' where NOME='$ENGINE' and chiave='$CPU' and valore like 'D: %';"
$CMD "update ENGINES set VALORE='T:' where NOME='$ENGINE' and chiave='$CPU' and valore like 'T: %';"
$CMD "update ENGINES set VALORE='S:' where NOME='$ENGINE' and chiave='$CPU' and valore like 'S: %';"
$CMD "update ENGINES set VALORE='X:' where NOME='$ENGINE' and chiave='$CPU' and valore like 'X: %';"
$CMD "update ENGINES set VALORE='I:' where NOME='$ENGINE' and chiave='$CPU' and valore like 'I: %';"


INFO "cleanupcpu.bsh - rimosso job $I alla CPU $CPU - ENGINE $ENGINE "
