#!/bin/bash

dockerHost="10.229.0.223"

ndasImage=Variable.get("ndas_image")

drivesimImage=Variable.get("drivesim_image")

# define basic directory and cache directory
siltestDir=/data/siltest

cacheDir="$siltestDir/cache/dockerovcache-dev"
testCasePath=""
airflowDagPath=/data/airflow/dags/scripts

rrLogPath=${siltestDir}/rrLog"
ncdPath="${siltestDir}/cache/dockerovcache-dev/.nvidia-omniverse/logs/Kit/omni.drivesim.e2e/23.1"



# container_name=drivesim-ov

func watch_scenario {
while true
    do  
        log_info=`docker exec -i drivesim-ov  bash  -c "tail -n 50 ds2_run.log"`
        echo ${log_info}
        if echo  ${log_info}  | grep -q "Scenario Start/Resume is waiting on Control, client must indicate progression"; then
        
            echo "Scenario Start/Resume is waiting on Control. Starting run ndas script."
            sleep 5
            break
        fi
done
}

# container_name=drivesim-ov

func watch_scenario_completed {
while true
    do
        log_info=`docker exec -i drivesim-ov  bash  -c "tail -n 50 ds2_run.log"`
        echo ${log_info}
        if echo  ${log_info}  | grep -q "ScenarioStateChange to eStopping broadcast completed"; then
        
            echo "ScenarioStateChange to eStopping broadcast completed"
            sleep 5
            break
        fi
done
}


func cleanup_nano_osi_roadcast_file {

ls -al   ${ncdPath}/*
ls -al   ${rrLogPath}/*
}



func run_ndas_drivesim_container {

cat  > /tmp/run_ndas_drivesim_container.py <<EOF

import docker
import time
from docker.types import Mount
#client = docker.from_env()  # 创建一个docker客户端
client = docker.DockerClient(base_url="tcp://${dockerHost}:2375",version="auto")  # 创建一个docker客户端


containerDict=dict()

def run_ndas_container():

    ndas= client.containers.run(
            image=$ndasImage,
            name="ndas",
            user="nvidia",
            privileged=True,
            ipc_mode="shareable",
            sysctls={"fs.mqueue.msg_max":4096},
            network_mode="host",
            device_requests=[docker.types.DeviceRequest(count=-1, capabilities=[['gpu']])],
            auto_remove=True,
            tty=True,
            detach=True,
            environment={"DISPLAY":"-1"},
            working_dir="/usr/local/driveworks/apps/roadrunner-2.0/config",
            entrypoint="/home/entry.sh",
            mounts=[
                Mount(target="/tmp/.X11-unix",source="/tmp/.X11-unix",type="bind"),
                Mount(target="/home/rrLog",source="${siltestDir}/rrLog",type="bind"),
                Mount(target="/etc/timezone",source="/etc/timezone",type="bind"),
                Mount(target="/etc/localtime",source="/etc/localtime",type="bind"),
                Mount(source=${airflowDagPath}+"/run_ndas.sh",target="/home/run_ndas.sh",type="bind"),
                ]
            )

    print(ndas)

def run_drivesim_container():
    
    drivesim =  client.containers.run(
            image=$drivesimImage,
            command = [
                "bash /drivesim-ov/run_sim_airflow.sh  ${testCasePath}" 
            ],
            name="drivesim-ov",
            network_mode="host",
            cap_add=["SYS_PTRACE"],
            security_opt=["seccomp=unconfined"],
            privileged=True,
            auto_remove=True,
            tty=True,
            detach=True,
            ipc_mode="container:ndas",
            ulimits=[docker.types.Ulimit(name='memlock', hard=-1,soft=-1),
            docker.types.Ulimit(name='nofile', hard=65535,Soft=65535)],
            device_requests=[docker.types.DeviceRequest(count=-1, capabilities=[['gpu']])],
            environment={
            "CUDA_VISIBLE_DEVICES":"1,2,3,4,5,6,7",
            "OMNI_USER":"omniverse",
            "OMNI_PASS":"123456",
            "DISPLAY": ":0",
            "ACCEPT_EULA":"Y"},
            extra_hosts={"drivesim2-rel.ov.nvidia.com":"10.229.0.223"},

            mounts=[
                Mount(target="/tmp/.X11-unix",source="/tmp/.X11-unix",type="bind"),
                Mount(target="/etc/timezone",source="/etc/timezone",type="bind"),
                Mount(target="/etc/localtime",source="/etc/localtime",type="bind"),
                Mount(source=$cacheDir+"/.cache",target="/drivesim-ov/.cache",type="bind"),
                Mount(source=$cacheDir+"/.local",target="/drivesim-ov/.local",type="bind"),
                Mount(source=$cacheDir+"/.nv",target="/drivesim-ov/.nv",type="bind"),
                Mount(source=$cacheDir+"/.nvidia-omniverse",target="/drivesim-ov/.nvidia-omniverse",type="bind"),
                Mount(source=$siltestDir+"/digital-testing-product/testcase_assets",target="/drivesim-ov/testcase_assets",type="bind"),
                Mount(source=$airflowDagPath+"/run_sim_airflow.sh",target="/drivesim-ov/run_sim_airflow.sh",type="bind"),
                ]
            )
    print(drivesim)

run_ndas_container()
time.sleep(10)
run_drivesim_container()

EOF

python /tmp/run_ndas_drivesim_container.py

}


func run_ndas_scripts {

cat > /tmp/run_ndas_script.py <<EOF 
import docker
from docker.types import Mount
client = docker.DockerClient(base_url="tcp://${dockerHost}:2375",version="auto")  # 创建一个docker客户端
def run_ndas_script():

    ndas = client.containers.get("ndas")

    ndas.exec_run(cmd="./run_ndas.sh",workdir="/home",detach=True)

run_ndas_script()
EOF
python /tmp/run_ndas_script.py

}


func stop_ndas_drivesim_container {

cat > /tmp/stop_ndas_drivesim_container.py << EOF
import docker
from docker.types import Mount
client = docker.DockerClient(base_url="tcp://${dockerHost}:2375",version="auto")  # 创建一个docker客户端
def stop_ndas_drivesim_container():
    try:

        ndas = client.containers.get("ndas")
        ndas.kill()
    except docker.errors.NotFound:
        print("docker container not exist")

    try:
        ds = client.containers.get("drivesim-ov")
        ds.kill()
    except docker.errors.NotFound:
        print("docker container not exist")

stop_ndas_drivesim_container()
EOF

python /tmp/stop_ndas_drivesim_container.py

}



func backup_nano_osi_roadcast_file {

testCaseName=`echo ${testCasePath##*/} |cut -d "." -f 1 `
/bin/bash $airflowDagPath/backup_nano_osi_roadcast.sh $siltestDir  $testCaseName $ncdPath  $rrLogPath

}

func evaluations_report {

/bin/bash $airflowDagPath/evaluations.sh $siltestDir  $testCasePath

}




run_ndas_drivesim_container
watch_scenario
run_ndas_scripts
watch_scenario_completed
backup_nano_osi_roadcast_file
evaluations_report
stop_ndas_drivesim_container
