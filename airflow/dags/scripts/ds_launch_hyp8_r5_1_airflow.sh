#!/bin/bash
omiverse="10.229.0.223"
drivesim_image="artifact.swf.daimler.com/adasndas-docker/sil3/r5_containers/ds:ds13_r5_1_final"
test_case_path="/drivesim-ov/testcase_assets/scenarios/autonomous_emergency_braking_aeb/aeb_china/ivista/aeb_ccrm_day_100_impact_70_gvt_20_3521574.xebtb"

export siltest_dir="/lake_taihu/data/siltest"
export CACHE_DIR=${siltest_dir}/cache/dockerovcache-dev
mkdir -p $CACHE_DIR/.local
mkdir -p $CACHE_DIR/.nv
mkdir -p $CACHE_DIR/.cache
mkdir -p $CACHE_DIR/.nvidia-omniverse
sudo chmod ugo+rwx -R $CACHE_DIR
docker run \
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
