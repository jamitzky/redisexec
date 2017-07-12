#e.g. on rvs8


#important parameters
#pwd<-'foobared'

#packages
.libPaths(c('/lrz/sys/applications/redis/Rdeps2',.libPaths()))
library(futuRes)
myind<-as.numeric(Sys.getenv('MYIND'))


#prereqs##
args<-commandArgs(trailingOnly=TRUE)
redishost<-args[1]
print(redishost)
pwd<-args[2]
redisdir<-args[4]
#print(pwd)
print(myind)
done<-FALSE
count<-1

while(done==FALSE){
	print(paste('Worker',myind,'started.',sep=' '))
	connection<-redisConnect(host=redishost,password=pwd,returnRef=TRUE)
	futureExecuteR(host=redishost,connection=connection)
	print('FAILURE on worker ',myind,' in round ',count,'.',sep='')
	count<-count+1
	Sys.sleep(30)
}
