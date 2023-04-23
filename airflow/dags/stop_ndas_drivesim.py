from __future__ import annotations

import datetime
import time
import pendulum
import os
from airflow import DAG
from airflow.operators.bash import BashOperator
from airflow.operators.empty import EmptyOperator
from airflow.operators.python  import PythonOperator
from airflow.models import  Variable
import docker
from docker.types import Mount
#from airflow.providers.docker.operators.docker import DockerOperator
from airflow.operators.docker_operator import DockerOperator

dockerHost = Variable.get("docker_host")

ndasImage = Variable.get("ndas_image")

drivesimImage = Variable.get("drivesim_image")

# define basic directory and cache directory
siltestDir = Variable.get("siltest_dir") 
cacheDir = siltestDir + "/cache/dockerovcache-dev"
testCasePath = Variable.get("test_case_path")


watch_scenario="""
while true
    do
        log_info=`docker exec -i {{params.container_name}}  bash  -c "tail -n 50 ds2_run.log"`
        echo ${log_info}
        if echo  ${log_info}  | grep -q "Scenario Start/Resume is waiting on Control, client must indicate progression"; then
        
            echo "Scenario Start/Resume is waiting on Control. Starting run ndas script."
            sleep 5
            break
        fi
done
"""


#client = docker.from_env()  # 创建一个docker客户端
client = docker.DockerClient(base_url=f"tcp://{dockerHost}:2375",version="auto")  # 创建一个docker客户端


containerInfo={}

def run_ndas_container():

    ndas= client.containers.run(
            image=ndasImage,
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
                Mount(target="/home/rrLog",source=f"{siltestDir}/rrLogs",type="bind"),
                Mount(target="/etc/timezone",source="/etc/timezone",type="bind"),
                Mount(target="/etc/localtime",source="/etc/localtime",type="bind"),
                ]
            )

    print(ndas)
    containerInfo["ndas"] = ndas

def run_ds_container():
    
    drivesim =  client.containers.run(
            image=drivesimImage,
            command = [
                f"bash /drivesim-ov/run_sim_airflow.sh  {testCasePath}" 
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
                Mount(source=cacheDir+"/.cache",target="/drivesim-ov/.cache",type="bind"),
                Mount(source=cacheDir+"/.local",target="/drivesim-ov/.local",type="bind"),
                Mount(source=cacheDir+"/.nv",target="/drivesim-ov/.nv",type="bind"),
                Mount(source=cacheDir+"/.nvidia-omniverse",target="/drivesim-ov/.nvidia-omniverse",type="bind"),
                Mount(source=siltestDir+"/digital-testing-product/testcase_assets",target="/drivesim-ov/testcase_assets",type="bind"),
                Mount(source=siltestDir+"/script/run_sim_airflow.sh",target="/drivesim-ov/run_sim_airflow.sh",type="bind"),
                #Mount(source=siltestDir+"/log/ds2_run.log",target="/drivesim-ov/ds2_run.log",type="bind"),
                #Mount(source=siltestDir+"/log/scenario_run.log",target="/drivesim-ov/scenario_run.log",type="bind"),
                ]
            )
    containerInfo["drivesim"]=drivesim



def run_ndas_script():
    ndas = containerInfo["ndas"]

    ndas.exec_run(cmd="/home/run_ndas.sh")




#获取log文件名
def get_kitLog_name():

    listFiles = os.listdir(kit_log_path)
    kitLog_time = time.strftime("%Y%m%d",time.localtime())
    for file in listFiles:
        if re.search("^kit_.*log$",file):
            return file



def stop_ndas_ds_container():
    ndas = client.containers.get("ndas")
    ds = client.containers.get("drivesim-ov")
    ndas.stop()
    ds.stop()

with DAG(
    dag_id="stop_ndas_drivesim_container",
    schedule=None,
    start_date=pendulum.datetime(2021, 1, 1, tz="Asia/Shanghai"),
    catchup=False,
    dagrun_timeout=datetime.timedelta(minutes=60),
    tags=["siltest"]
) as dag:

    #start_ndas = EmptyOperator(task_id='start_ndas', dag=dag) 
    
    #create_ndas_container = PythonOperator(task_id='create_ndas_container_task',python_callable=run_ndas_container,do_xcom_push=True,dag=dag) 
    #create_ds_container = PythonOperator(task_id='create_ds_container_task',python_callable=run_ds_container,do_xcom_push=True,dag=dag) 
    
    #scenario_waiting_on_Control = BashOperator(task_id="scenario_wait_on_control_task",bash_command=watch_scenario,params = {'container_name' : 'drivesim-ov'})
    
    #run_ndas_script = PythonOperator(task_id='run_ndas_script_task',python_callable=run_ndas_script,do_xcom_push=True,dag=dag)

    stop_ndas_ds_container = PythonOperator(task_id='stop_ndas_ds_container_task',python_callable=stop_ndas_ds_container,do_xcom_push=True,dag=dag) 

#start_ndas >> create_ndas_container >> create_ds_container  >> scenario_waiting_on_Control >> run_ndas_script

stop_ndas_ds_container







if __name__ == "__main__":
    dag.cli()
