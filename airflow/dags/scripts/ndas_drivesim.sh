#!/bin/bash

ndas_image="artifact.swf.daimler.com/adasndas-docker/sil3/r5_containers/ndas:ndas_22_11_4b"
omiverse="10.229.0.223"
drivesim_image="artifact.swf.daimler.com/adasndas-docker/sil3/r5_containers/ds:ds13_r5_1_final"
test_case_path="/drivesim-ov/testcase_assets/scenarios/autonomous_emergency_braking_aeb/aeb_china/ivista/aeb_ccrm_day_100_impact_70_gvt_20_3521574.xebtb"
docker_host="127.0.0.1"
export siltest_dir="/lake_taihu/data/siltest"


sudo apt-get install -y linux-modules-extra-$(uname -r)
docker -H tcp://${docker_host}:2375  run -itd --name ndas --user nvidia --net host --ipc shareable --sysctl fs.mqueue.msg_max=4096 --gpus all -e DISPLAY=:1 --privileged --rm -v /etc/timezone:/etc/timezone -v /etc/localtime:/etc/localtime -v /tmp/.X11-unix:/tmp/.X11-unix -v ${siltest_dir}/script/run_ndas.sh:/home/run_ndas.sh  -v  ${siltest_dir}/rrLog:/home/rrLog  -w /usr/local/driveworks/apps/roadrunner-2.0/config ${ndas_image}  /home/entry.sh


export CACHE_DIR=${siltest_dir}/cache/dockerovcache-dev
mkdir -p $CACHE_DIR/.local
mkdir -p $CACHE_DIR/.nv
mkdir -p $CACHE_DIR/.cache
mkdir -p $CACHE_DIR/.nvidia-omniverse
sudo chmod ugo+rwx -R $CACHE_DIR
docker -H tcp://${docker_host}:2375  run \
		--name=drivesim-ov \
		--network=host \
		--cap-add=SYS_PTRACE \
		--security-opt \
		seccomp=unconfined \
		--privileged \
		--rm \
		-itd \
		--ulimit \
		memlock=-1:-1 \
		--gpus=all \
		--env CUDA_VISIBLE_DEVICES=1,2,3,4,5,6,7 \
		--ipc=container:ndas \
		--ulimit \
		nofile=65535:65535 \
		--env \
		OMNI_USER=omniverse \
		--env \
		OMNI_PASS=123456 \
		--add-host \
		drivesim2-rel.ov.nvidia.com:${omiverse} \
		-v \
		/etc/timezone:/etc/timezone \
		-v \
		/etc/localtime:/etc/localtime \
		-v $CACHE_DIR/.cache:/drivesim-ov/.cache \
		-v $CACHE_DIR/.local:/drivesim-ov/.local \
		-v $CACHE_DIR/.nv:/drivesim-ov/.nv \
		-v $CACHE_DIR/.nvidia-omniverse:/drivesim-ov/.nvidia-omniverse \
		-v \
		/tmp/.X11-unix:/tmp/.X11-unix \
		-v ${siltest_dir}/digital-testing-product/testcase_assets:/drivesim-ov/testcase_assets \
		-v ${siltest_dir}/script/run_sim_airflow.sh:/drivesim-ov/run_sim_airflow.sh \
		--env \
		DISPLAY \
		--env \
		ACCEPT_EULA=Y \
		${drivesim_image} \
		"bash /drivesim-ov/run_sim_airflow.sh ${test_case_path}"

