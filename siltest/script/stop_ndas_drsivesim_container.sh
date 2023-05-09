#!/bin/bash

if [ ! -z $(docker ps -q -f "name=ndas")  ];then
docker kill ndas
fi

if [ ! -z $(docker ps -q -f "name=drivesim-ov") ];then
docker kill drivesim-ov
fi

