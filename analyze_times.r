####analyze runtimes
#get arguments
args<-commandArgs(trailingOnly=TRUE)
redisdir<-args[1]

#check whether previous steps of startup succeded 
homed<-Sys.getenv('HOME')
load(paste(redisdir,'/fail.RData',sep=''))
failureenv<-as.numeric(Sys.getenv('FAILURE'))
if(FAILURE==TRUE | failureenv==1)
	stop("Startup failed")

###get runtime data
setwd(paste(redisdir,'/runtimes',sep=''))

dd<-dir()
for(j in 1:length(dd)){
	if(paste(strsplit(x=dd[j],split='')[[1]][1:8],collapse='')=='runtimes'){
		dd1<-dd[j]}}

load(dd1)
ids<-c()
workers<-c()
times<-c()
for(i in 1:length(results)){
	if(results[[i]][1]!='Not finished yet.'){
		ids<-c(ids,results[[i]]$id)
		workers<-c(workers,results[[i]]$workername)
		times<-c(times,results[[i]]$difftime)}
}


###create plots and save them
cexmain=0.9
pdf(paste(redisdir,'/runtimes/runtimes.pdf',sep=''))
par(mfrow=c(2,2))
plot(ids,main=paste('Order of receipt (number of rec. tasks: ',length(ids),' )',sep=''),col='blue',cex.main=cexmain,ylab='ID',xlab='receipt')
barplot(table(factor(workers)),main=paste('Worker dist. (number of worker: ',length(unique(workers)),' )',sep=''),col=2:(1+length(unique(workers))),cex.main=cexmain,ylab='Frequency',xlab='Worker')
hist(times,col='blue',main='Distribution of runtimes',cex.main=cexmain,xlab='Runtime')
boxplot(times~factor(workers),col=2:(length(unique(workers))+1),main='Distribution of runtimes',cex.main=cexmain,ylab='Runtime',xlab='Worker')
par(mfrow=c(1,1))
dev.off()
