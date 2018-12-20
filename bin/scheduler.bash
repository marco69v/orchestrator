#!/bin/bash

. ../etc/orchestrator.conf

# logging conf
B_LOG --file $LOG/scheduler.log
B_LOG -o false #altrimenti spara anche in stdout
LOG_LEVEL_ALL


LASTENGINEUSED=$(cat $TL/lastengine_cpu_used)
LASTENGINEUSED=${LASTENGINEUSED:="0"}

# rendo l'elenco degli engine
#ENGINES=$($CMD "select distinct(NOME) from ENGINES")
ENG_NUM=$($CMD "select count(distinct(nome)) from ENGINES")
echo numero engine trovato: $ENG_NUM
BASEENGNAME=some_name_of_an_engine_00 #parte del nome di uno degli engine, nel nostro caso erano del tipo engine001, engine002 e via cosi

# prendo l'elenco dei job da schedulare
JOBS=$($CMD "select * from CODA where STATO='QUEUED';")

EMPTY=$(echo "$JOBS" | wc -w)
if [ $EMPTY -eq 0 ]; then
	INFO "Nessun record in coda in stato QUEUED"
	exit
fi
INFO "trovati $EMPTY record in coda in stato QUEUED - in realta non sono record ma numero di parole risultanti dalla selezione"

if [ $LASTENGINEUSED -gt $ENG_NUM ]; then
	ERROR "l'ultimo engine usato era oltre al limite degli engine attuali"
	ERROR "controllare ed eventualmente sistemare LASTENGINEUSED o aggiungere engine e cpu al DB"
	exit 1
fi

FL=0 #first loop. mi serve per portare il contatore all ultimo engine usato

# ora bisogna  looppare su quelli selezionati per aggiornare lo stato a 'SCHEDULING'
# nel usiamo la stessa selezione perche nel frattempo potr<F3>ebbero esserne arrivati altr+i


SCHED=1
echo "$JOBS" | while IFS=\| read idcoda app tab stato ts
do
	$CMD "update coda set stato='SCHEDULING' where idcoda=$idcoda;"

	#cerco le cpu libere
	#ancora non so esattamente come fare o cosa fare

	#while [ "$SCHED" -le "$ENG_NUM" ]
	#do
	if [ $FL -eq 0 ]; then
		while [ $SCHED -lt $LASTENGINEUSED ]; do
			SCHED=$(($SCHED+1))
			if [ $SCHED -gt $ENG_NUM ]; then
				DEBUG "in rotazione ho superato il numero massimo di engine presenti. resetto i counter ed esco dal loop di pareggio"
				SCHED=1
                                LASTENGINEUSED=0
				break
			fi
		done
		FL=1
	fi

		#else
			# popolo i file degli engine con le cpu libere
			cpu=$($CMD "select distinct(chiave) from engines where nome='$BASEENGNAME$SCHED' and valore ='A:' limit 1;")
			if [ "${cpu}z" = "z" ]; then
				#non ci sono cpu libere
				#rimettere a queued tutta la selezione
				#e vedere se necessario altro
				WARN "non ci sono CPU libere secondo la tabella ENGINES"
				$CMD "update CODA set stato = 'QUEUED' where stato = 'SCHEDULING';"
				DEBUG "resettato lo stato dei job selezionati che da SCHEDULING tornano a QUEUED"
				RC=99
				break
			fi

			# CURL - chiamata inizio lavori a delphix
	 		$CMD "update coda set stato='SCHEDULED' where idcoda='$idcoda';" #questa potrebbe e dovrebbe essere una delete
			DEBUG "aggiornato stato a SCHEDULED al job in CODA con id $idcoda"
			$OHOME/bin/insert.bash $app $tab $BASEENGNAME$SCHED $cpu $idcoda
			DEBUG "chiamato insert.bash app:$app tab:$tab cpu:$cpu idcoda:$idcoda per preparare il checkstatus al lancio"
			$CMD "update coda_engine set nome='$BASEENGNAME$SCHED', cpu='$cpu' where idcoda=$idcoda;"
			DEBUG "associato su CODA_ENGINE l'idcoda $idcoda con $nome  e $cpu"
			LASTENGINEUSED=$SCHED
			SCHED=$(($SCHED+1))
			if [ $SCHED -gt $ENG_NUM ]; then #abbiamo fatto un  giro completo di engine, ricominciamo
				SCHED=1
				LASTENGINEUSED=0
			fi
		#fi
	#done
	#fi
	# aggiornaimo lo stato in coda ad SCHEDULED o cancelliamo il file 
	# se non lo cancelliamo adesso andra fatto probabilmente con piu fatica con il cleaup richiamato da status
	echo $LASTENGINEUSED > $TL/lastengine_cpu_used
	DEBUG "scritto numero ultimo engine usato:$LASTENGINEUSED"
	#export LASTENGINEUSED
done
#echo $LASTENGINEUSED > $TL/lastengine_cpu_used 
#echo aggiornato last su file $LASTENGINEUSED
if [ ${RC:="0"} -eq 99 ]; then 
	#dobbiamo fare qualcosa ? 
	exit $RC
fi

