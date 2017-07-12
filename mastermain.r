print('#####-#####   mastermain start   #####-#####')
print(date())


#get arguments
args<-commandArgs(trailingOnly=TRUE)
redishost<-args[1]
#print(redishost)
pwd<-args[2]
#print(pwd)
prerunfile<-args[3]
taskfile<-args[4]

print(prerunfile)
print(taskfile)

mpipre<-as.numeric(args[5])
print(mpipre)
nodespertask<-as.numeric(args[6])
print(nodespertask)
depsfile<-args[7]
print(depsfile)
showdeps<-as.numeric(args[8])
print(showdeps)
rpdir<-args[9]
redisdir<-args[10]
ownmpipre<-as.numeric(args[11])

#load futures-package
.libPaths(c(rpdir,.libPaths()))
library('parallel')
library('futuRes')

#check whether previous steps of startup succeded 
homed<-Sys.getenv('HOME')
failfile<-paste(redisdir,'/fail.RData',sep='')
if(file.exists(failfile)){
	load(failfile)
} else {
	FAILURE<-FALSE }

failureenv<-as.numeric(Sys.getenv('FAILURE'))
if(FAILURE==TRUE | failureenv==1)
	stop("Startup failed") 


print(paste('FAILURE pre:',FAILURE,':',failureenv))

if(mpipre==1 | nodespertask > 1 ){
	mpiforce<-TRUE} else {
	mpiforce<-FALSE
}

if(ownmpipre==1){
	ownmpi<-TRUE
} else {
	ownmpi<-FALSE
}

if(prerunfile=='NONE'){
	prerun<-paste('unset env LOADLBATCH;export LOADL_HOSTFILE=',redisdir,'/hostfile; export MYHOSTFILE=',redisdir,'/subhostfiles/hostf${MYIND};',sep='') #needs to be run before execution of tasks
} else {
	prerunfileC<-file(prerunfile,'r')
	prerun<-paste(readLines(prerunfileC,warn=F),collapse=';')
	prerun<-paste('unset env LOADLBATCH;export LOADL_HOSTFILE=',redisdir,'/hostfile; export MYHOSTFILE=',redisdir,'/subhostfiles/hostf${MYIND};',prerun,';',sep='')
#print(prerun)
	close(prerunfileC)
}





#start redis-server and connect to it

connection<-redisConnect(host=redishost,password=pwd,returnRef=TRUE)
connection2<-redisConnect(host=redishost,password=pwd,returnRef=TRUE)
redisSetContext(e=connection)
#read in tasks
taskfileC<-file(taskfile,'r')
tasks<-readLines(taskfileC)
close(taskfileC)

ntasks<-length(tasks)


###get dependencies
if(depsfile!='NONE'){
	load(paste(redisdir,'/dependencies/dependencies.RData',sep=''))
	print('dependence structure')
	print(deps)
	print("dependencies")
	print(arcs)
	print('invalid dependencies')
	print(imparcs)
	print('solvedarcs')
	print(solvedarcs)
	starters<-deps[[1]]
	print('starters')
	print(starters)
} else {
	starters<-1:ntasks
}


#function to be run in parallel
parafun<-function(id,task,prerun,mpiforce,ownmpi){
	homed<-Sys.getenv('HOME')
	myind<-Sys.getenv('MYIND')
	print('MYIND')
	print(myind)
	Sys.setenv('TID'=id)
	pretime<-proc.time()[3]
#print(date())
	if(mpiforce==FALSE | ownmpi==TRUE){
		taskrun<-paste(prerun,task)
	} else {
		taskrun<-paste(prerun,' mpiexec.hydra -f ',redisdir,'/subhostfiles/hostf',myind,' ',task,sep='')
	}
	print(taskrun)
	out<-system(taskrun,wait=TRUE,intern=FALSE)
	posttime<-proc.time()[3]
	diff<-posttime-pretime
	workername<-Sys.info()[4]
	res<-list(id=id,difftime=diff,output=out,workername=workername)
	return(res)
}

#submit tasks that do not have dependencies
add.args<-list(prerun=prerun,mpiforce=mpiforce,ownmpi=ownmpi)
arg.list<-list()
lcc<-1
for(i in 1:ntasks){
	if(i %in% starters){
		arg.list[[lcc]]<-list(id=i,task=tasks[i])
		lcc<-lcc+1   
	}
}

#handle dependencies
if(length(starters)!=ntasks){
	deplevels<-length(deps)-1
	levelinds<-((1:deplevels)%%14)+2
	deplevels<-length(deps)-1
	levelinds<-((1:deplevels)%%14)+2
}  else {
	ntasks<-length(starters)
	deplevels<-0
}



#create handle
handle<-list(host=redishost,port=6379,database=0,resultskey='res.list',ntasks=ntasks,connection=connection2)




mcfun<-function(type){
	print(paste('===type:',type,sep=''))
	
	
	if(type==1){
		time<-proc.time()[3]
		print(type)
		print(date())
		handleorg<-futureSubmitR(host=redishost,fun=parafun,arg.list=arg.list,add.args=add.args,wait=FALSE,connection=connection)
		print('submission')
		print(proc.time()[3]-time)
		results<-handleorg
		print(handle)
#print(results)
	}
	if(type==2)
	{
		results<-list()
		done<-FALSE
		lcount<-1
		done_ids<-c()
		redisSetContext(e=connection2)
		while(done==FALSE){
			Sys.sleep(15)
			print(type)
			print(date())
			time<-proc.time()[3]
			newresults<-futureCollect(handle=handle,wait=FALSE)
			handle<-newresults$handle
			
			
			cres<-newresults$results
			print('cres')
			print(cres)
			
			for(iii in length(cres):1){
				if(cres[[iii]][1]!='Not finished yet.'){
					done_ids<-c(done_ids,cres[[iii]]$id)} else {
					cres[[iii]]<-NULL    
				}
			}
			
			redisSet('doneids', done_ids, NX = FALSE)
			print('done_ids')
			print(done_ids)
#print(newresults)
			if(length(cres)!=0)
				results<-c(results,cres)
#print(results)
			if(handle[['ntasks']]==0)
				done<-TRUE
			print(length(cres)) 
			print(paste('collect',lcount))
			print(handle[['ntasks']])
			print(proc.time()[3]-time)
			print(date())
			lcount<-lcount+1
			
#if(lcount>=10)
#    stop('10 rounds are over.')
			
		}
	}
	
	if(type>=3) {
		pid<-type
		print('pid')
		print(pid)
		mycon<-redisConnect(host=redishost,password=pwd,returnRef=TRUE)
		redisSetContext(e=mycon)
		mylevels<-which(levelinds==pid)+1
		print('mylevels')
		print(mylevels)
		
		mytasks<-c()
		for(kkk in mylevels)
			mytasks<-c(mytasks,deps[[kkk]])
		print('mytasks:****')
		print(mytasks)
		print(tasks[mytasks])
		
		Sys.sleep(30)
		
		
		
		while(length(mytasks!=0)){
			doneids<-redisGet('doneids')
			my.arg.list<-list()
			mylcc<-1
			tasksgo<-c()
			
			
			
			
			for(tt in mytasks){
				tdeps<-arcs[which(arcs[,2]==tt),1]
				
				if(!any(tdeps %in% doneids==FALSE)){
					print('mylcc???')
					print(mylcc)
					mymy<-list(id=tt,task=tasks[tt])
					my.arg.list[[mylcc]]<-mymy
					tasksgo<-c(tasksgo,tt)
					mylcc<-mylcc+1
					
				}
			}
			print("doneids")
			print(doneids)
			
			mytasks<-setdiff(mytasks,tasksgo)
			
			if(length( my.arg.list)!=0)
				myhandle<-futureSubmitR(host=redishost,fun=parafun,arg.list=my.arg.list,add.args=add.args,wait=FALSE,connection=mycon)
			
			Sys.sleep(20)
		}
		
		
		
		results<-'done'
	}
	
	
	
	return(results)
}


time<-proc.time()[3]
nprocs<-deplevels+2
print('nprocs:')
print(nprocs)
options('cores'=16)
mcres<-mclapply(1:nprocs,mcfun,mc.cores=10)
print(mcres)
handleorg<-mcres[[1]]
results<-mcres[[2]]
print(proc.time()[3]-time)
print(date())

doneids<-redisGet('doneids')
print('doneids')
print(doneids)

time<-proc.time()[3]
save(results,handle,handleorg,doneids,file=paste(redisdir,'/runtimes/','runtimes',gsub(' ','_',date()),'.RData',sep=''))

if(class(try(redisSelect(0)))!='try-error')
	try(system("killall redis-server",intern=FALSE,wait=FALSE,ignore.stdout = TRUE))

save(FAILURE,file=paste(redisdir,'/fail.RData',sep=''))

print('#####-#####   mastermain end  #####-#####')
print(proc.time()[3]-time)
print(date())