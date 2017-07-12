# worker startup


print('#####-#####   workerstartup start  #####-#####')
print(date())
#process
args<-commandArgs(trailingOnly=TRUE)
redishost<-args[1]
pwd<-args[2]
nodespertask<-as.numeric(args[3])
procspernode<-as.numeric(args[4])
rpdir<-args[5]
redisdir<-args[6]
ownmpipre<-as.numeric(args[7])

if(ownmpipre==1){
	ownmpi<-TRUE
} else {
	ownmpi<-FALSE
}

print(args)

#check whether previous steps of startup succeded 
homed<-Sys.getenv('HOME')
#source(paste(homed,'.redis/redisexec/internal.r',sep=''))


failfile<-paste(redisdir,'/fail.RData',sep='')

if(file.exists(failfile)){
	load(failfile)
} else {
	FAILURE<-FALSE }

failureenv<-as.numeric(Sys.getenv('FAILURE'))
if(FAILURE==TRUE | failureenv==1)
	stop("Startup failed")

print(paste('FAILURE pre:',FAILURE,':',failureenv))

###get hostname (= host of redis-server)
if(redishost=='localhost'){
	lrzsegment<-Sys.getenv('LRZ_SYSTEM_SEGMENT')
	if(lrzsegment=='Medium_Node'){
		redishost<-paste(Sys.info()[4],'ib',sep='')
	} else {
		redishost<-paste(Sys.info()[4],'-ib',sep='')
	}  
} else {
	stop("Using a host other than 'localhost' for the redis-server is currently not implemented.")
}


#print(redishost)

###read job hosts
homed<-Sys.getenv('HOME')
hostcon <- file(paste(redisdir,"/hostfile",sep=''), "r", blocking = FALSE)
hosts<- readLines(hostcon) 
hostsU<-unique(hosts)
#print(hostsU)

if(nodespertask==1 & ownmpi==FALSE){
#start one worker on each node 
	loopcounter<-1
	for(i in 1:length(hostsU)){
		system(paste("llspawn.stdio ",hostsU[loopcounter]," 'export MYIND=",i,";echo $MYIND;. $HOME/.redis/redisexec/worker.sh ",redishost," ",pwd," ",rpdir," ",redisdir,"' >> ",redisdir,"/logs/spawn.log 2>&1",sep=""),wait=F)
		loopcounter<-loopcounter+1 
	}
	
	#hostsU2<-setdiff(hostsU,redishost)
	
	nodek<-1
	while(nodek<=length(hostsU)){
		hostf<-file(paste(redisdir,'/subhostfiles/hostf',nodek,sep=''),'w')
		lines<-c()
		for(jj in 1:procspernode)
			lines<-c(lines,hostsU[nodek])
		writeLines(lines,con=hostf)
		close(hostf)
		nodek<-nodek+1
	}
	
} else if(ownmpi==TRUE){
	if(nodespertask<=0)
		stop('Invalid value for NODESPERTASK (<=0)')
	nodek<-1
	loopcounter<-1
	while(nodek<length(hostsU)){
		hostf<-file(paste(redisdir,'/subhostfiles/hostf',loopcounter,sep=''),'w')
		lines<-c()
		for(ii in nodek:(nodek+nodespertask-1))
			for(jj in 1:procspernode)
				lines<-c(lines,hostsU[ii])
		
		writeLines(lines,con=hostf)
		close(hostf)
		system(paste("llspawn.stdio ",hostsU[nodek]," 'export MYIND=",loopcounter,";echo $MYIND;. $HOME/.redis/redisexec/worker.sh ",redishost," ",pwd," ",rpdir," ",redisdir,"' >> ",redisdir,"/logs/spawn.log 2>&1",sep=""),wait=F)
		nodek<-nodek+nodespertask
		loopcounter<-loopcounter+1
	}
	
} else {
	
	if((length(hostsU)-1)%%nodespertask!=0)
		stop('After removal of masternode, the number of requested nodes is not divisible by NODESPERTASK.')
	
	if(nodespertask<=0)
		stop('Invalid value for NODESPERTASK (<=0)')
	
	print(redishost)
	print(hostsU)
	
	hostsU2<-setdiff(hostsU,redishost)
	print(hostsU2)
	nodek<-1
	loopcounter<-1
	while(nodek<length(hostsU2)){
		hostf<-file(paste(redisdir,'/subhostfiles/hostf',loopcounter,sep=''),'w')
		lines<-c()
		for(ii in nodek:(nodek+nodespertask-1))
			for(jj in 1:procspernode)
				lines<-c(lines,hostsU2[ii])
		
		writeLines(lines,con=hostf)
		close(hostf)
		system(paste("llspawn.stdio ",hostsU2[nodek]," 'export MYIND=",loopcounter,";echo $MYIND;. $HOME/.redis/redisexec/worker.sh ",redishost," ",pwd," ",rpdir," ",redisdir,"' >> ",redisdir,"/logs/spawn.log 2>&1",sep=""),wait=F)
		nodek<-nodek+nodespertask
		loopcounter<-loopcounter+1
	}
}

FAILURE<-FALSE
save(FAILURE,file=paste(redisdir,'/fail.RData',sep=''))



print('#####-#####   workerstartup end   #####-#####')
print(date())
