#!/bin/bash

airflowDagPath=$1
siltestDir=$2
ncdPath=$3
testCasePath=$4
rrLogPath=$5

# $testCasePath.split("/")[-1].split(".")[0]
OLD_IFS=$IFS
IFS="/"
read -a strarr <<< "$testCasePath"
len=${#strarr[@]}
#echo "$len"
last_str="${strarr[$len - 1]}"

IFS="."
read -a arr <<< "$last_str"
len=${#arr[@]}
testCaseName="${arr[0]}"
IFS=$OLD_IFS
#echo "testCaseName:"$testCaseName

$airflowDagPath/backup_nano_osi_roadcast.sh $siltestDir  $testCaseName  $ncdPath $rrLogPath