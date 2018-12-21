#!/bin/bash
. $HOME/orchestrator/etc/orchestrator.conf
while IFS=\: read eng cpu
do
        for c in $(seq 1 $cpu)
        do
                $CMD "insert into ENGINES (nome, chiave, valore) values ('$eng','$c','A:';"
                $CMD "insert into ENGINES (nome, chiave, valore) values ('$eng','$c','D:';"
                $CMD "insert into ENGINES (nome, chiave, valore) values ('$eng','$c','T:';"
                $CMD "insert into ENGINES (nome, chiave, valore) values ('$eng','$c','S:';"
                $CMD "insert into ENGINES (nome, chiave, valore) values ('$eng','$c','X:';"
                $CMD "insert into ENGINES (nome, chiave, valore) values ('$eng','$c','I:';"
        done
done <<< "$(cat engines| grep -v ^#)"
