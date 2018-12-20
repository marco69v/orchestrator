#!/bin/bash



function logIN {

engine=$1
DEBUG "login.bash - chiamato me con engine: $engine"

LOGIN=$(curl -s -X POST --header "Content-Type: application/json" --header "Accept: application/json" -d "{  \"username\": \"$delphix_username\",  \"password\":  \"$delphix_password\" }"  "http://${engine}${SUFFIX}:8282/masking/api/login")
DEBUG "login.bash - risposta alla LOGIN: $LOGIN"

#AUTHKEY=$(echo -e "$LOGIN" | jq --raw-output '.Authorization')
AUTHKEY=$(echo -e "$LOGIN" | awk -F\" '{print $4}')
DEBUG "login.bash - selezionato dalla LOGIN l'hash: $AUTHKEY"

# se funziona l upsert ...
$CMD "insert or replace into API_SESSION (ENGINE, AUTHKEY, TS) values ('$engine', '$AUTHKEY', '$(date +%s)');"
INFO "login.bash - fatto refresh dell'hash per engine: $engine, authkey: $AUTHKEY"

}

. ../etc/orchestrator.conf

# logging conf
B_LOG --file $LOG/checkstatus.log #scrivo sullo stesso file del chiamante ma possiamo volendo isolarlo
B_LOG -o false #altrimenti spara anche in stdout
LOG_LEVEL_DEBUG



if [ "$#" -gt "0" ]; then

	#sono stato chiamato per fare una login sola
	engine=$1
	logIN $engine
	exit 
fi


#questa curl fa la login a delphix . risponde con una key da usare per le sessioni successive fino alla logout
# loop su tutti gli engine per recuperare tutte le authkey 


echo $ENGINES | while read engine
do
	logIN $engine

done
exit
