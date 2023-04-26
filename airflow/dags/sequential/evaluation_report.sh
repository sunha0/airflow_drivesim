#!/bin/bash


airflowDagPath=$1
siltestDir=$2
testCaseName=$3

$airflowDagPath/evaluations.sh $siltestDir $testCaseName