#!/bin/bash


airflowDagPath=$1
siltestDir=$2
testCasePath=$3

$airflowDagPath/evaluations.sh $siltestDir $testCasePath