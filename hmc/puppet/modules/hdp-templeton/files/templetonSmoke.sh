#!/bin/sh

export ttonhost=$1
export smoke_test_user=$2
export ttonurl="http://${ttonhost}:50111/templeton/v1"


cmd="curl -s -w 'http_code <%{http_code}>'    $ttonurl/status 2>&1"
retVal=`su - ${smoke_test_user} -c "$cmd"`
httpExitCode=`echo $retVal |sed 's/.*http_code <\([0-9]*\)>.*/\1/'`

if [[ "$httpExitCode" -ne "200" ]] ; then
  echo "Templeton Smoke Test (status cmd): Failed. : $retVal"
  export TEMPLETON_EXIT_CODE=1
  exit 1
fi

exit 0

#try hcat ddl command
echo "user.name=${smoke_test_user}&exec=show databases;" /tmp/show_db.post.txt
cmd="curl -s -w 'http_code <%{http_code}>' -d  \@${destdir}/show_db.post.txt  $ttonurl/ddl 2>&1"
retVal=`su - ${smoke_test_user} -c "$cmd"`
httpExitCode=`echo $retVal |sed 's/.*http_code <\([0-9]*\)>.*/\1/'`

if [[ "$httpExitCode" -ne "200" ]] ; then
  echo "Templeton Smoke Test (ddl cmd): Failed. : $retVal"
  export TEMPLETON_EXIT_CODE=1
  exit  1
fi

#try pig query
outname=${smoke_test_user}.`date +"%M%d%y"`.$$;
ttonTestOutput="/tmp/idtest.${outname}.out";
ttonTestInput="/tmp/idtest.${outname}.in";
ttonTestScript="idtest.${outname}.pig"

echo "A = load '$ttonTestInput' using PigStorage(':');"  > /tmp/$ttonTestScript
echo "B = foreach A generate \$0 as id; " >> /tmp/$ttonTestScript
echo "store B into '$ttonTestOutput';" >> /tmp/$ttonTestScript

#copy pig script to hdfs
su - ${smoke_test_user} -c "hadoop dfs -copyFromLocal /tmp/$ttonTestScript /tmp/$ttonTestScript"

#copy input file to hdfs
su - ${smoke_test_user} -c "hadoop dfs -copyFromLocal /etc/passwd $ttonTestInput"

#create, copy post args file
echo -n "user.name=${smoke_test_user}&file=/tmp/$ttonTestScript" > /tmp/pig_post.txt

#submit pig query
cmd="curl -s -w 'http_code <%{http_code}>' -d  \@${destdir}/pig_post.txt  $ttonurl/pig 2>&1"
retVal=`su - ${smoke_test_user} -c "$cmd"`
httpExitCode=`echo $retVal |sed 's/.*http_code <\([0-9]*\)>.*/\1/'`
if [[ "$httpExitCode" -ne "200" ]] ; then
  echo "Templeton Smoke Test (pig cmd): Failed. : $retVal"
  export TEMPLETON_EXIT_CODE=1
  exit 1
fi

exit 0
