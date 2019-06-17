# redisexec
A simple worker queue for R functions using redis as database

Redisexec can be used in single node mode (default) or in MPI mode (used if 'nodespertask'>1 or 'forcempi'=1). In MPI-mode, redisexec will automatically split up the load leveler host file to create MPI groups of size 'nodespertask' (one of redisexec's arguments). Currently, only Intel-MPI is supported.

Please note that redisexec will use one node for the scheduling manager. Thus, in MPI-mode, the number of nodes N (#@ node) has to be specified in the load leveler script so that (N-1) is divisible by 'nodespertask'.

# arguments

    Redisexec's arguments are the following (-short_form|--long_form):

    (all arguments except 'taskfile' and 'redispwd' are optional)

    -t|--taskfile: path to the file specifying the tasks (one task per line); no default

    -r|--redispwd: password of your redis-server; no default

-i|--initfile: either NONE or the path file containing command lines that are run before 
execution of each task or NONE (if not needed), defaults to NONE.
 Please note that the file will be collapsed to to a single line while separating all 
scriptlines by ';'

-n|--nodespertask: non-negative integer, specifying the number of nodes that are used for 
each task specified in 'taskfile'. If set to a value >1 redisexec
 will try to execute the tasks in $TASKFILE as MPI programmes by building mpi hostfiles 
with 'nodespertask' hosts in each host file, defaults to 1

-p|--procspernode: integer, specifying the number of processes used on each node; 
defaults to 16 and will be ignored in non-mpi-mode

-f|--forcempi: force mpi-mode. redisexec will run the tasks in 'taskfile' using mpi 
even if 'nodespertask'=1. defaults to 0 (not forced)

-d|--depsfile: path to a file specifying dependencies among the tasks in 'taskfile', 
defaults to NONE (no dependencies). This file has the specifies dependencies as 
edges INTEGER;INTEGER,one dependency per line. The integers correspond to the line numbers 
in the taskfile

-s|--showdeps:integer, indicating whether a graph illustrating the dependencies in 
'depsfile' shall be illustrated in a pdf, defaults to 0.
 The pdf will be placed in $HOME/.redis/dependencies/depsgraph.pdf. Possible values are:
 0: do not illustrate dependencies
 1: illustrate dependencies but do not run the actual computations
 2: illustrate dependencies in additional to running the actual computations

-a|--analyze:integer, indicating whether a graph illustrating the dependencies, defaults 
to 0. Possible values are:
 0: analyze the run times of the tasks in 'taskfile'and create a plot 
in $HOME/.redis/runtimes/runtimes.pdf
 1: do not analyze the runtimes of the tasks in 'taskfile'

# taskfile

The only obligatory input file in redisexec is the task file containing the tasks to be run by the workers.

The path to this file is passed to redisexec via the argument 'taskfile'. The file has to contain one task (usually a one-line bash commando) per line as illustrated in the following picture:

If necessary, you may refer to the task number via the environment variable ${TID}.
In our example, the expression '>> $HOME/namdres/out${TID}.txt 2>&1${TID}' is used
to redirect both standard output and standard error into a separate file for each task.

You can find the actual example file for downloading below.
initfile

Another input file is called 'initfile' and can optionally be passed to redisexec (argument 'initfile'). It is basically a bash-script which will be run just before the execution of each task on the workers. This is useful for example if the tasks require applications from LRZ's module system as in the following example:

During task processing, redisexec will collapse this file to a single line while separating the original lines by ';'.
The expression '> /dev/null 2>&1' avoids that log-files get cluttered up with messages from the module system.

You can find the actual example file for downloading below.

# depsfile

The last input file can optionally be passed in order to describe dependencies among tasks (argument 'depsfile'). In the current version redisexec accepts only a single file format for the dependency file which can cover any dependence structure.
However, future versions will provide more convenient ways for specifying task dependencies.

Currently, each task dependency has to be specified as an edge in a directed graph (as depicted in the flow diagram in the following box:

# dependency graph

If the argument 'showdeps' of redisexec is set 1 (show dependency but do not run the tasks) or 2 (show dependencies and run the tasks), redisexec will
create a pdf illustrating the task dependencies as a graph. In the graph, the tasks are represented as nodes whereby the dependencies are represented by directed edges originating from the required task and heading to the dependent task.

If there are unresolvable dependencies, redisexec will throw a warning and specify tasks that cannot be run in the pdf on the second page.

Below you can find an example graph.

The edges are simply represented by a pair of numbers X;Y that the task X is a requirement of task Y where the numbers refer to the line numbers in the 'taskfile'. The file may only contain a single edge per line.

Here is an example which corresponds to the graph in the box

The expression '1;2' in the first line means that Task 1 in the 'tasksfile' is required for running Task 2. In the graph mentioned above this is represented by the arrow from T1 to T2. By passing the argument 'showdeps 1' you can make redisexec illustrate your dependencies in a graph (in $HOME/.redis/dependencies/dependencies.pdf) and check your 'depsfile' for unresolvable dependencies.

You can fin the actual example file for downloading below.


# examples

In the following example, we will use redisex to perform 20 simulations using the application NAMD.

The necessary files can be found below. The archive needs to be extracted to $HOME/redisexample if the example shall run without modifications (apart from adapting the redis password in the command lines below).

## Example 1: Single-Node-Mode without dependencies

Example running the tasks in 'tasks.txt' with initfile 'pre.txt' in mpi-mode using 2 nodes (with 16 mpi-processes) for each task:

redisexec --taskfile $HOME/redisexample/tasks.txt --redispwd pwd --initfile $HOME/redisexample/init.txt

## Example 2: MPI-Mode with dependencies

Example running the tasks in 'tasks.txt' with initfile 'pre.txt' in mpi-mode using 2 nodes (with 16 mpi-processes) for each task:

redisexec --taskfile $HOME/redisexample/tasks.txt --redispwd pwd 
--initfile $HOME/redisexample/init.txt --nodespertask 2 --procspernode 16 
--depsfile $HOME/redisexample/dependencies.txt

# installation

The newest version of redisexec can be found in '/lrz/sys/applications/redis/redislrz'.

For first use, it is recommended to copy the complete folder '/lrz/sys/applications/redis/redislrz' to '$HOME/.redis' since redisexec assumes a certain directory hierarchy inside $HOME/.redis.

cp -r /lrz/sys/applications/redis/redislrz $HOME/.redis

As a next step, you should replace the password in $HOME/.redis/redis.conf (search for 'requirepass') by a password of your choice.

For convenience, you can add the redisexec-folder (which can be found in your $HOME/.redis) to your $PATH by including the following line in your $HOME/.bashrc:
export PATH=$PATH:$HOME/.redis/redisexec

Now, you can invoke redisexec directly by the command 'redisexec' instead of '$HOME/.redis/redisexec'.

This is it.

# Updating redisexec

If you want to update your redisexec to the newest version, it is enough to simply copy the folder 'redisexec' in '/lrz/sys/applications/redis/redislrz' using:

 cp -r /lrz/sys/applications/redis/redislrz/redisexec $HOME/.redis/redisexec

# Runtime Analysis

If redisexec's argument 'analyze' is set to 1, redisexec will create a pdf at $HOME/.redisexec/runtimes/runtimes.pdf which show the runtimes of the different tasks and their order of termination:

Here is an example output:

In the top row on the left side, you can see a plot illustrating the order of execution or rather the order in which the different tasks terminated.
The ID (y-axis) corresponds to the line in the taskfile whereas the x-axis corresponds to the rank of the corresponding task, i.e. whether it reported its results sooner or later than other tasks to the task scheduler. The plot corresponds to the example shown in the dependency example. We can see for example that the task that came in seventeenth had the ID 2. This is because Task to was one of the four tasks which had a dependency (task 1). Thus it was scheduled only when the required task was already finished. In the meanwhile, however, all the other tasks without dependencies had already been scheduled and consequently Task 2 finished later these tasks (considering that in this case all tasks had almost the same runtime as can be seen from the other plots).

The second plot in the first column shows the distribution of the runtimes. In this case, we can see all tasks had almost the same runtime (33 seconds) which makes sense since all tasks computed exactly the same thing.

The plot in the upper right corner shows the distribution of the tasks among the worker. In this case, there were 4 worker groups with 2 MPI nodes each. Due to the dependence structure, the distribution is not perfectly uniform, because there were not always for tasks available for scheduling. Thus, the last worker group had already completed its task when the dependencies of the next task became available (i.e. the results of its dependencies were reported in). If several workers are available at the scheduling of a task, it is more or less random which worker the task will be sent to.

Finally, in the lower right plot, we can see the distribution of the runtimes grouped by the worker groups. In this case, differences among worker groups are really neglibile. However, if certain worker groups needed clearly more time for the same computations, this would indicate a problem on those hosts.


# REDISDIR

The folder $REDISDIR contains all data created by the redisexec framework within a specific run.

This includes logfiles ($REDISDIR/logs), dependency graphs ($REDISDIR/dependencies), hostfiles ($REDISDIR/subhostfiles) and information on the run times of the individual tasks ($REDISDIR/runtimes).

The value of $REDISDIR is determined during the job and is composed in the following way:
$HOME/redis_$JID
whereby $JID is the $LOADL_STEP_ID (basically the loadleveler job identifier) with '.' and '-' removed.

(author Ch. Bernau)
