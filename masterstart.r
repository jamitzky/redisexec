#startup

print('#####-#####   masterstartup start   #####-#####')
print(date())


#important args
args<-commandArgs(trailingOnly=TRUE)
redishost<-args[1]
#print(redishost)
pwd<-args[2]
rpdir<-args[3]
redisdir<-args[4]
#print(pwd)


#check for FAILURES
homed<-Sys.getenv('HOME')
failfile<-paste(redisdir,'/fail.RData',sep='')


if(file.exists(failfile)){
	load(failfile)
} else {
	FAILURE<-FALSE }

failureenv<-as.numeric(Sys.getenv('FAILURE'))
if(FAILURE==TRUE | failureenv==1){
	stop("Startup failed") 
} 


print(paste('Failure pre:',FAILURE))

preflush<-TRUE #logical, indicating whether redis-db should be flushed at startup?

#load futures-package
.libPaths(c(rpdir,.libPaths()))

library('futuRes')

#start redis-server and connect to it
hostname<-startRedisServerSingle(size=1,port=6379)
Sys.sleep(3)
print(hostname)
connection<-redisConnect(password=pwd,returnRef=TRUE)
if(preflush==TRUE)
	redisFlushAll()


#msg<-NA

#if(class(hostname)=='try-error' | class(connection)=='try-error'){
#FAILURE<-TRUE
#msg<-'redis data base did not start up properly.'
#}


save(FAILURE,file=paste(failfile,sep=''))

print('#####-#####   masterstartup end  #####-#####')
print(date())
