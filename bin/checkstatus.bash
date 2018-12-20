#!/bin/bash


function checklogin {

# $1 nome engine
nome=$1

LINE=$($CMD "select * from api_session" | grep $nome)
DEBUG "trovata linea con engine: $nome in api_session: $LINE"
AUTHKEY=$( echo $LINE | awk -F\| '{ print $2}' )
DEBUG "chiave risultante appena chiamata la funzione checklogin: $AUTHKEY"
if [ "${AUTHKEY}z" = "z" ]; then
	WARN "non c era un hash salvato per $nome.cerco di recuperarlo"
	DEBUG "chiamo login.bash con nome: $nome"
	$OHOME/bin/login.bash $nome
	AUTHKEY=$($CMD "select * from api_session" | grep $nome | cut -d\| -f 2)
	DEBUG "nuova chiave: $AUTHKEY"
else
	DEBUG "trovata chiave: $AUTHKEY per engine: $nome, la provo"
	ck=$(curl -X GET --header "Accept: application/json" --header "Authorization: $AUTHKEY" "http://$1:8282/masking/api/system-information"|grep -o errorMessage)
	DEBUG "ck valorizzato solo se riesco a greppare errorMessage altrimenti è vuoto ck: $ck"
	if [ "${ck}" = "errorMessage" ]; then
		WARN "hash per accesso api su $nome scaduto. cerco di rigenerarlo"
		$OHOME/bin/login.bash $1
		AUTHKEY=$($CMD "select * from api_session" | grep $nome | cut -d\| -f 2)
	fi
fi

echo $AUTHKEY
}


. ../etc/orchestrator.conf
#questo script deve loopare sulle cpu ipegnate selezionate da engines e ne verifico lo stato su delphix

# logging conf
B_LOG --file $LOG/checkstatus.log #scrivo sullo stesso file del chiamante ma possiamo volendo isolarlo
B_LOG -o false #altrimenti spara anche in stdout
LOG_LEVEL_ALL



# va gestita la selezione vuota
SELECTION=$($CMD "select nome, chiave, valore  from engines where valore = 'S: JUST_INSERTED';")
NUM=$(echo $SELECTION | wc -w)
if [ $NUM -gt 0 ]; then
	INFO "trovati $NUM record in stato JUST_INSERTED - be non proprio record. numero di parole risultanti dalla selezione"
	while  IFS=\| read nome cpu valore
	do

		SUBSEL=$(sqlite3 -separator ';' $DB "select * from engines where nome='$nome' and chiave='$cpu';")
		#echo "$SUBSEL" | while read line
		while read line
		do
			DEBUG "sto elaborando la linea $line dei JUST_INSERTED"
			IND=$(echo $line|cut -d\; -f 4|cut -d\: -f 1)
			case $IND in 
	
				A)
					APP=$(echo $line|cut -d\; -f 4|cut -d\: -f 2|tr -d [:space:] ) 	
					;;
				T)
					TS=$(echo $line|cut -d\; -f 4|cut -d\: -f 2 |tr -d [:space:])
					;;
				D)
					TAB=$(echo $line|cut -d\; -f 4|cut -d\: -f 2 |tr -d [:space:])	
					;;
				S)
					STA=$(echo $line|cut -d\; -f 4|cut -d\: -f 2 |tr -d [:space:])
					;;
				I)
					idcoda=$(echo $line|cut -d\; -f 4|cut -d\: -f 2 |tr -d [:space:])
					;;
				X)
					#in teoria e vuota
					execID=$(echo $line|cut -d\; -f 4|cut -d\: -f 2 |tr -d [:space:])
					;;
			esac
		done <<< "$(echo -e "$SUBSEL")"

		#gestione sessione - controllo se presente authkey che non sia scaduta
                #AUTHKEY=$($CMD "select * from api_session" | grep $nome | cut -d\| -f 2)
 		AUTHKEY=$(checklogin $nome) #controlliamo che la chiave che abbiamo non sia scaduta
		
		if [ "${AUTHKEY}z" = "z" ]; then
			FATAL "non sono riuscito a recuperare un hash. sono costretto a bloccarmi"
			exit 1
		fi
		DEBUG "chiamo faccioio.bash"
		$OHOME/bin/faccioio.bash $idcoda $nome $AUTHKEY $cpu

			
		# abbiamo aggiornato il campo X con executionid che ci tornera utile per fare gli status dei running
		# abbiamo aggiornato lo stato portandolo da just_inserted in qualcosa altro, probabilmente running
		# il terzo update non so se tenere quello che gia c e per calcolare in qualche modo un elapsed o aggiornarlo 
			# per indicare quando e stato l ultimo poll su delphix

	done <<< "$(echo "$SELECTION")"
fi

SELECTION=$($CMD "select nome, chiave, valore  from engines where valore like 'S:%RUNNING%' or valore like  'S:%SUCCEEDED%';") 
NUM=$(echo $SELECTION | wc -w)
if [ $NUM -gt 0 ]; then
	
	INFO "trovati $NUM record in stato RUNNING o SUCCEEDED"

	while IFS=\| read  nome cpu valore
	do
		SUBSEL=$($CMD "select * from engines where nome='$nome' and chiave='$cpu';")
        	while read line
        	do
			DEBUG "sto elaborando la linea $line dei RUNN o SUCC"
                	IND=$(echo $line|cut -d\| -f 4|cut -d\: -f 1)
                	case $IND in

                       		A)
                                	APP=$(echo $line|cut -d\| -f 4|cut -d\: -f 2 |tr -d [:space:])
                                	;;
                        	T)
                                	TIMP=$(echo $line|cut -d\| -f 4|cut -d\: -f 2 |tr -d [:space:])
                                	;;

                        	D)
                                	TAB=$(echo $line|cut -d\| -f 4|cut -d\: -f 2 |tr -d [:space:])
                                	;;

                        	S)
                                	STA=$(echo $line|cut -d\| -f 4|cut -d\: -f 2 |tr -d [:space:])
                                	;;

                        	X)
                                	execID=$(echo $line|cut -d\| -f 4|cut -d\: -f 2 |tr -d [:space:])
                                	;;
                        	I)
                                	idcoda=$(echo $line|cut -d\| -f 4|cut -d\: -f 2 |tr -d [:space:])
                                	;;
                	esac
		done <<< "$(echo "$SUBSEL")"

		DEBUG "App: $APP, TS: $TIMP, TAB:$TAB, STA: $STA, EXECID:$execID, idcoda:$idcoda"

 		AUTHKEY=$(checklogin $nome) #controlliamo che la chiave che abbiamo non sia scaduta
		if [ "${AUTHKEY}z" = "z" ]; then
			FATAL "non sono riuscito a recuperare un hash. sono costretto a bloccarmi"
			exit 1
		fi

                RISPOSTA=$(curl -s -X GET --header "Accept:application/json" --header "Authorization: ${AUTHKEY}" http://${nome}:8282/masking/api/executions/${execID})
		INFO "chiamo delphix per sapere a che stato è il job con execid $execID"
		DEBUG "risposta per execid: $execID -  $RISPOSTA"

		STATUS=$(echo -e $RISPOSTA | tr -d \{\}\"|cut -d\, -f 3|cut -d\: -f 2)
		DEBUG "Risposta per execid: $execID, stato: $STATUS"
		case $STATUS in
			'SUCCEEDED')
				: 
				# job terminato con successo
				# /home/ee51732/unicredit/var/tmp/$APP/$TAB/$JCL.wait
				INFO "job terminato"
				$OHOME/bin/cleanupcpu.bash $nome $cpu
				JCL=$($CMD "select jcl from coda_engine where idcoda=$idcoda;")
				rm -f $TL/$APP/$TAB/$JCL.wait
				INFO "$TL/$APP/$TAB/$JCL è stato rimosso"
				$CMD "update coda set stato = 'COMPLETED' where idcoda=$idcoda"
				
				;;
			'RUNNING')
				:
				# aggiorno solo il timestamp
            	$CMD "update engines set valore = 'T: $(date +%s)' where nome = '$nome' and chiave ='$cpu' and valore like 'T:%';"
				INFO "job con executionId $execID ancora running, aggiorno T con timestamp del check"
				;;
			'FAILED')
				: # mboooooh
				DEBUG "sono passato da FAILED - il job è fallito su delphix"
				$OHOME/bin/cleanupcpu.bash $nome $cpu
				JCL=$($CMD "select jcl from coda_engine where idcoda=$idcoda;")
				kill -3 $(cat $TL/$APPLICAZIONE/$TABELLA/$JCL.wait)
				$CMD "update coda set stato = 'FAILED' where idcoda=$idcoda"
				;;

			'*')
				: # e mboh 2
				DEBUG "sono passato da *"
				;;
		esac
		
	done <<< "$(echo "$SELECTION")"
fi
