#!/bin/bash

# questo script è quello che viene richiamato dai JCL 
# deve inserire il job in coda e rimanere in attesa che il ob sia finito per sganciare il JCL

trapped(){

JCL=$1
APP=$(echo $1| cut -d\. -f 1)         #qualcosa con $JCL es: FAM0ASSI.TSFAMAN1.UL come deciso che verra passato... FAM0ASSI
TAB=$(echo $1| cut -d\. -f 2)         #qualosaltro con $JCL. quindi questo diventa TSFAMAN1


FATAL "errore sconosciuto mentre ero in esecuzione di $1"
test -e ../var/tmp/$APP/$TAB/${JCL}.wait && rm /home/ee51732/unicredit/var/tmp/$APP/$TAB/$JCL.wait
INFO "rimosso ../var/tmp/$APP/$TAB/${JCL}.wait da catch di segnale di kill"

}

#da verificare il return code buono per errore per JCL
trap "trapped $1; exit 20" SIGINT SIGABRT SIGKILL SIGQUIT

. ../etc/orchestrator.conf

# logging conf
B_LOG --file ../log/orchestrator.log
B_LOG -o false #altrimenti spara anche in stdout
LOG_LEVEL_DEBUG


if [ "$#" -ne "1" ]; then
        echo "devi passare 1 parametro"
        exit 1
fi

#echo "lanciato $(date +%U) $1 " > ../log/orchestrator.log
INFO "lanciato $(date +%U) $1" 


JCL=$1
# sara da parserizaare per estrarre il nome applicazione ed il nome tabella, utile per il resto degli script 


APP=$(echo $1| cut -d\. -f 1)         #qualcosa con $JCL es: FAM0ASSI.TSFAMAN1.UL come deciso che verra passato... FAM0ASSI
TAB=$(echo $1| cut -d\. -f 2)         #qualosaltro con $JCL. quindi questo diventa TSFAMAN1

$CMD "insert into CODA (applicazione, tabella, stato) values ('$APP', '$TAB', 'QUEUED');"
DEBUG "aggiunto record in CODA"
idcoda=$($CMD "select idcoda from CODA where applicazione='$APP' and tabella='$TAB' and stato='QUEUED';")
DEBUG "estratto idcoda"
$CMD "insert into CODA_ENGINE (idcoda, jcl) values ($idcoda, '$JCL');"
DEBUG "inserito record in CODA_ENGINE"


#test -e $TL/$APP/$TAB || mkdir -p $TL/$APP/$TAB
test -e ../var/tmp/$APP/$TAB || mkdir -p ../var/tmp/$APP/$TAB

#touch  /home/ee51732/unicredit/var/tmp/$APP/$TAB/$JCL.wait
echo $$ >  ../var/tmp/$APP/$TAB/$JCL.wait
DEBUG "creato file semaforo ../var/tmp/$APP/$TAB/$JCL.wait"

# restituiamo un exit code diverso da 0 per inidicare al chiamante - mainframe - che qualcosa è andato storto 
# anche se in questo punto è un po difficile riuscire a capire cosa
RC=1

while true
do
	if [ -e $TL/$APP/$TAB/$JCL.wait ]; then
		: #do nothing o aumenta o aggiorna qualche contatore
	else
		# il file è stato cancellato perche l'elaborazione è finita
		# possibilmente qualche altra attivita
		INFO "il file ../var/tmp/$APP/$TAB/$JCL.wait è stato cancellato"
		RC=0
		break
	fi
	TRACE "in polling su file ../var/tmp/$APP/$TAB/$JCL.wait"
	sleep 2
done

exit $RC
