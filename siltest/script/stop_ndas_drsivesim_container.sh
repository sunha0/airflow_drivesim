#!/bin/bash

if [ ! -z $(docker ps -q -f "name=ndas")  ];then
docker kill ndas
echo  "======================= ndas has been killed ======================="
fi

if [ ! -z $(docker ps -q -f "name=drivesim-ov") ];then
docker kill drivesim-ov
echo  "======================= drivesim-ov has been killed ======================="
fi

