#!/bin/bash
ndas_image="artifact.swf.daimler.com/adasndas-docker/sil3/r5_containers/ndas:ndas_22_11_4b"
sudo apt-get install -y linux-modules-extra-$(uname -r)
docker run -itd --name ndas --user nvidia --net host --ipc shareable --sysctl fs.mqueue.msg_max=4096 --gpus all -e DISPLAY=:1 --privileged --rm -v /etc/timezone:/etc/timezone -v /etc/localtime:/etc/localtime -v /tmp/.X11-unix:/tmp/.X11-unix -v /data/siltest/script/run_ndas.sh:/home/run_ndas.sh  -v /data/siltest/rrLog:/home/rrLog  -w /usr/local/driveworks/apps/roadrunner-2.0/config ${ndas_image}  /home/entry.sh
