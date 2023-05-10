#!/bin/bash
siltestDir="$1"
rm -rf  ${siltestDir}/cache/dockerovcache-dev/.nvidia-omniverse/logs/Kit/omni.drivesim.e2e/23.1/*
rm -rf  ${siltestDir}/rrLog/*
rm -rf  ${siltestDir}/silEvaluationInput/*

echo "=======================cache & rrLog directory has deleted.======================="