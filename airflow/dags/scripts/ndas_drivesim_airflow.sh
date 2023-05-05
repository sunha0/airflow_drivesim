#!/bin/bash
export siltest_dir=$1
omiverse_ip=$2
ndas_image=$3
drivesim_image=$4
test_case_path=$5
docker_host=$6


func run_ndas {

mkdir -p $siltest_dir/rrLog
sudo apt-get install -y linux-modules-extra-$(uname -r)
docker -H tcp://${docker_host}:2375  run -itd --name ndas --user nvidia \
--net host --ipc shareable --sysctl fs.mqueue.msg_max=4096 --gpus all -e DISPLAY=:1 --privileged \
--rm -v /etc/timezone:/etc/timezone -v /etc/localtime:/etc/localtime -v /tmp/.X11-unix:/tmp/.X11-unix \
-v ${siltest_dir}/script/run_ndas.sh:/home/run_ndas.sh  -v ${siltest_dir}/rrLog:/home/rrLog \
-w /home  ${ndas_image}  /home/entry.sh

}


func run_drivesim {

export CACHE_DIR=${siltest_dir}/cache/dockerovcache-dev
mkdir -p $CACHE_DIR/.local
mkdir -p $CACHE_DIR/.nv
mkdir -p $CACHE_DIR/.cache
mkdir -p $CACHE_DIR/.nvidia-omniverse
mkdir -p $CACHE_DIR/logs
touch $CACHE_DIR/logs/ds2_run.log
sudo chmod ugo+rwx -R $CACHE_DIR

docker -H tcp://${docker_host}:2375 run \
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
		drivesim2-rel.ov.nvidia.com:${omiverse_ip} \
		-v \
		/etc/timezone:/etc/timezone \
		-v \
		/etc/localtime:/etc/localtime \
		-v $CACHE_DIR/.cache:/drivesim-ov/.cache \
		-v $CACHE_DIR/.local:/drivesim-ov/.local \
		-v $CACHE_DIR/.nv:/drivesim-ov/.nv \
		-v $CACHE_DIR/.nvidia-omniverse:/drivesim-ov/.nvidia-omniverse \
		-v $CACHE_DIR/logs/ds2_run.log:/drivesim-ov/ds2_run.log \ 
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


}

func watch_scenario_control_info {

	while true
    do
        log_info=`tail -n 100 $CACHE_DIR/logs/ds2_run.log`
        echo ${log_info}
        if echo  ${log_info}  | grep -q "Scenario Start/Resume is waiting on Control, client must indicate progression"; then
        
            echo "Scenario Start/Resume is waiting on Control. Starting run ndas script."
            sleep 1
            break
        fi
done
}


func  run_ndas_script {

	docker -H tcp://${docker_host}:2375  exec -i bash  -c "./run_ndas.sh"

}




run_ndas
run_drivesim
watch_scenario_control_info

