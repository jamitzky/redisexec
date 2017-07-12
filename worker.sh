#!/bin/bash
unset env LOADLBATCH
. /etc/profile.d/modules.sh
module load R/3.0
R --quiet -f $HOME/.redis/redisexec/worker.r --args $1 $2 $3 $4 >> $4/logs/worker.log 2>&1
