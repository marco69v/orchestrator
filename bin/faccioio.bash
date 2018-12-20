#!/bin/bash

. /home/ee51732/unicredit/etc/orchestrator.conf

idcoda=$1
nome=$2
AUTHKEY=$3
cpu=$4

#Logging conf
B_LOG --file $LOG/checkstatus.log #scrivo sullo stesso file del chiamante ma possiamo volendo isolarlo
B_LOG -o false #altrimenti spara anche in stdout
LOG_LEVEL_ALL

DEBUG "chiamato faccioio.bash con paramentri $@"

JCL=$($CMD "select lower(jcl) from coda_engine where idcoda=$idcoda;")
DEBUG "faccioio.bash - blocco ricerca executionID - JCL: $JCL"

FINDJOBID=$(curl -s -X GET --header "Accept: application/json" --header "Authorization: $AUTHKEY" "http://$nome:8282/masking/api/masking-jobs")
DEBUG "faccioio.bash - blocco ricerca executionID - FINDJOBID: $FINDJOBID"

#----------
I=$(echo $FINDJOBID | tr -d \{\}\" | cut -d\[ -f 2 | cut -d\] -f 1 | sed -E 's-,-\n-g' | grep -c jobName)
DEBUG "trovati $I maskinjob su delphix"
K=0
P=0
while IFS=\: read A B
do
	DEBUG "faccioio.bash - nuovo blocco A:$A --- B:$B"
	if [ "$A" = "jobName" ]; then
		jobName[$K]=$B
		DEBUG "faccioio.bash - ${jobName[$K]} assegnato valore $B"
		K=$(($K+1))
	fi
	if [ "$A" = "maskingJobId" ]; then
		maskingJobId[$P]=$B
		DEBUG "faccioio.bash - ${maskingJobId[$P]} assegnato valore $B"
		P=$(($P+1))
	fi
	DEBUG "valore K:$K P:$P"
done <<< "$(echo $FINDJOBID | tr -d \{\}\" | cut -d\[ -f 2 | cut -d\] -f 1 | sed -E 's-,-\n-g')"
DEBUG "valori trovati ${maskingJobId[@]} - ${jobName[@]}"
for Y in $(seq 0 $I)
do
	DEBUG "valore --- Y:$Y"
	if [ "${jobName[$Y]}" = "$JCL" ]; then
		JOBID=${maskingJobId[$Y]}
	fi
done
#-------------------------
DEBUG "faccioio.bash - blocco ricerca executionID - JOBID: $JOBID" 
EXECUTE=$(curl -s -X POST --header "Content-Type: application/json" --header "Accept: application/json" --header "Authorization: $AUTHKEY" -d "{ \"jobId\": $JOBID }" "http://10.248.248.109:8282/masking/api/executions")
DEBUG "faccioio.bash - blocco ricerca executionID - EXECUTE: $EXECUTE"
EXECID=$(echo $EXECUTE | tr -d \{\}\"|cut -d\: -f 2 | cut -d\, -f 1)
DEBUG "faccioio.bash - blocco ricerca executionID - EXECID: $EXECID"
EXESTA=$(echo $EXECUTE | tr -d \{\}\"|cut -d\: -f 4 | cut -d\, -f 1)
DEBUG "faccioio.bash - blocco ricerca executionID - EXESTA: $EXESTA"

if [ "${FINDJOBID}x" = "x" -o "${JOBID}y" = "y" -o "${EXECUTE}z" = "z" -o "${EXECID}h" = "h" -o "${EXESTA}k" = "k" ]; then
	ERROR "faccioio.bash - qualcosa è andato storto nel blocco di ricerca jobid e executionid. controllare engine:$nome idcoda: $idcoda nomejob: $JCL"
	exit 1
else
	INFO "faccioio.bash - chiamo updatejob.bash con i parametri $nome $cpu $EXECID $EXESTA e timestamp"
fi

$OHOME/bin/updatejob.bash $nome $cpu $EXECID $EXESTA $(date +%s)



