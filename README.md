# orchestrator
Well, this is my first project in git so not so familiar yet.

what orchestrator does:
it enqueue request for masking jobs and manages a sort of load balancing against a list of engines available
Each engines may have different number of cpu so, is up to you to fill engines or to leave at least one cpu 
free not inserting this one into the engines table.

why it was written in bash:
because where I had to implement it was a must

what you have to do in order to run:
populate the engines table with row of kind
	engine1	CPU1	
	

a lot of thing has to be finalized, described and set in a nicer look but this is why I 
decided to put in Git ;) 
if you want to help me on this youo are welcome :)

even this README has to be "betterized" :D


how it works
it works with a little database, in our situation we had to use sqlite, no other way, but it resulted a good friend.
in the database there are 2 main tables: QUEUE and ENGINES

each time orchestrato.bash is called, it writes a new record into QUEUE and a trafficlight file 
(it was needed to keep the caller busy until the end where, then, the caller continues on its way with other stuff) and 
loops on the presence of the file just created.
if the file disappears, should means that everything worked fine.
otherwise it should receive a SIGQUIT signal that is trapped and managed to exit with a different return code to the caller

the other 2 main scripts that are to be placed in cron at */1 are:
scheduler: it looks on the QUEUE table and select the QUEUED row, it set to SCHEDULING and it try to distribute to the engines. 
if no "cpu" are available return the not addressed to QUEUED, the ones scheduled instead are SCHEDULED in QUEUE and JUST_INSERTED to ENGINE cpu

checkstatus: it looks for the JUST_INSERTED and calls delphix to start them. The RUNNING one are monitored and updated. The SUCCEEDED are cleaned
from the ENGINE and the FINISHED in the QUEUE. the FAILED are cleat them too but FAILED on QUEUE. in this last case we send the kill signal. in both case we clean the file that orchestrator monitor