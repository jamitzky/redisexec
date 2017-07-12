####analyze dependencies
print('#####-#####   checkdeps start   #####-#####')
print(date())
time<-proc.time()[3]



###
args<-commandArgs(trailingOnly=TRUE)
taskfile<-args[1]
depsfile<-args[2]
rpdir<-args[4]
print(rpdir)
.libPaths(c(rpdir,.libPaths()))
library(dagR)


if(depsfile=='NONE'){
	warning ("No 'depsfile' specified. Complete independence of tasks assumed.")
} else {
	
	
	print(depsfile)
	showdeps<-as.numeric(args[3])
	redisdir<-args[5]
	
	
#check whether previous steps of startup succeded 
	homed<-Sys.getenv('HOME')
	failureenv<-as.numeric(Sys.getenv('FAILURE'))
	if(failureenv==1){
		stop("Startup failed")
	} else {
		FAILURE<-FALSE
	}
	
#read in tasks
	taskfileC<-file(taskfile,'r')
	tasks<-readLines(taskfileC)
	close(taskfileC)
	ntasks<-length(tasks)
	
#read deps
	arcs<-read.csv(depsfile,header=F,sep=';')
	
	
	###check dependencies
#initial values
	deps<-remarcs<-remnodes<-solvedarcs<-list()
	lc<-1
	solvedarcs[[lc]]<-NA
	remarcs[[1]]<-arcs #all arcs
	remnodes[[1]]<-1:ntasks #all nodes
#round one  (get the ones without deps)
	depsc<-setdiff(remnodes[[lc]],remarcs[[lc]][,2])
	deps[[lc]]<-depsc
	remnodes[[lc+1]]<-setdiff(remnodes[[lc]],depsc)
	inds<-which(remarcs[[lc]][,1]%in%deps[[lc]])
	posarcs<-remarcs[[lc]][inds,,drop=FALSE]
	solvedarcs[[lc+1]]<-posarcs
	imparcs<-remarcs[[lc]][-inds,,drop=FALSE]
	remarcs[[lc+1]]<-remarcs[[lc]][-inds,,drop=FALSE]
	lc<-lc+1
	
#remaining rounds (get the ones with possible arcs )
	while(length(remnodes[[lc]])!=0 &  nrow(posarcs)!=0 ){
		depsc<-setdiff(remnodes[[lc]],imparcs[,2])
		deps[[lc]]<-depsc
		remnodes[[lc+1]]<-setdiff(remnodes[[lc]],depsc)
		inds<-which(remarcs[[lc]][,1]%in%deps[[lc]])
		posarcs<-imparcs[inds,,drop=FALSE]
		solvedarcs[[lc+1]]<-posarcs
		if(length(inds)!=0){
			imparcs<-imparcs[-inds,,drop=FALSE]
			remarcs[[lc+1]]<-remarcs[[lc]][-inds,,drop=FALSE]
		}
		lc<-lc+1
	}
	
	
	if(nrow(posarcs)==0 & nrow(imparcs)!=0){
		warning('Invalid dependence structure.')
		FAILURE<-TRUE
		mainmain<-'There were unresolved dependencies.'
	} else{
		imparcs<-0
		mainmain<-'No unresolved dependencies.'
	}
	
	
	if(showdeps==1 | showdeps==2){
#create graph    
		dag<-dag.init(covs=rep(1,ntasks),arcs=arcs)
		dag$names<-paste('T',1:ntasks,sep='')
		dag$symbols<-paste('T',1:ntasks,sep='')
#x- and y-positions of nodes + type of arcs
		x<-numeric(ntasks)
		dag$arc.type<-rep(0,times=nrow(arcs))
		dag$arc<-arcs
		y<-numeric(ntasks)
		
		for(k in 1:length(deps)){
			y[deps[[k]]]<-(-1.5)*k+10
			x[deps[[k]]]<-(1:length(deps[[k]]))-mean(1:length(deps[[k]]))
		}
		
		dag$y<-y
		dag$x<-x
		
#some additional graphics parameters 
		dag$len<-0.06
		dag$ygab<-1
		dag$xgab<-0
#plot
		pdf(paste(redisdir,'/dependencies/dependencies.pdf',sep=''))
		dg<-dag.draw(dag,legend=F,paths=F,noxy=1,main=mainmain)
		plot(c(0,1),c(0,1),col='white',main=mainmain,axes=F,xlab='',ylab='')
		text(0.2,0.5,labels=paste('Tasks that cannot be run: ',paste(unique(unlist(imparcs)),collapse=','),'.',sep=''))
		dev.off()
		
	}
	print('save and shutdown')
	save(arcs,deps,imparcs,solvedarcs,file=paste(redisdir,'/dependencies/dependencies.RData',sep=''))
	
}


save(FAILURE,file=paste(redisdir,'/fail.RData',sep=''))
print(proc.time()[3]-time)
print(date())
print('#####-#####   checkdeps end  #####-#####')
