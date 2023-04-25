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
import subprocess

dockerHost = Variable.get("docker_host")

ndasImage = Variable.get("ndas_image")

drivesimImage = Variable.get("drivesim_image")

# define basic directory and cache directory
siltestDir = Variable.get("siltest_dir") 
cacheDir = siltestDir + "/cache/dockerovcache-dev"
testCasePath = Variable.get("test_case_path")

rrLogPath = f"{siltestDir}/rrLog"
ncdPath   =   f"{siltestDir}/cache/dockerovcache-dev/.nvidia-omniverse/logs/Kit/omni.drivesim.e2e/23.1"




airflowDagPath="/data/airflow/dags/scripts"

evaluations_report="""{{params.airflowDagPath}}/evaluations.sh {{params.siltestDir}} {{params.testCaseName}} """
#evaluations_report="""{{params.airflowDagPath}}/evaluations.sh {{params.siltestDir}} {{params.testCaseName}} {{params.ncdPath}} {{params.rrLogPath}} """

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

watch_scenario_completed="""
while true
    do
        log_info=`docker exec -i {{params.container_name}}  bash  -c "tail -n 50 ds2_run.log"`
        echo ${log_info}
        if echo  ${log_info}  | grep -q "ScenarioStateChange to eStopping broadcast completed"; then
        
            echo "ScenarioStateChange to eStopping broadcast completed"
            sleep 5
            break
        fi
done
"""


clean_up_nano_osi_roadcast_file="""

mkdir -p  /tmp/{ncdPath,rrLogPath}
mv ${ncdPath}/*  /tmp/ncdPath
mv ${rrLogPath}/* /tmp/rrLogPath


rm -rf /tmp/ncdPath
rm -rf /tmp/rrLogPath

"""


#client = docker.from_env()  # 创建一个docker客户端
client = docker.DockerClient(base_url=f"tcp://{dockerHost}:2375",version="auto")  # 创建一个docker客户端


containerDict=dict()

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
                Mount(target="/home/rrLog",source=f"{siltestDir}/rrLog",type="bind"),
                Mount(target="/etc/timezone",source="/etc/timezone",type="bind"),
                Mount(target="/etc/localtime",source="/etc/localtime",type="bind"),
                Mount(source=siltestDir+"/script/run_ndas.sh",target="/home/run_ndas.sh",type="bind"),
                ]
            )

    print(ndas)

def run_drivesim_container():
    
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
    print(drivesim)



def run_ndas_script():

    #ndas = containerInfo.get("ndas")
    #ndas = ti.xcom_pull(task_ids="create_ndas_container_task")
    ndas = client.containers.get("ndas")


    print("containerInfo:",ndas)

    ndas.exec_run(cmd="./run_ndas.sh",workdir="/home",detach=True)




#获取log文件名
def get_input_file(ncdPath,rrLogPath):

    evaluationsFileName={}

    osiPath = "".join([ncdPath,"/osi_recording"])
    ncdDir = os.listdir(ncdPath)
    osiDir = os.listdir(osiPath)
    rodecastDir =  os.listdir(rrLogPath)
    for ncd  in  ncdDir:
        if ncd.endswith("ncd.csv"):
            print(ncd)
            evaluationsFileName["ncd"]= ncd
    for rodecast in rodecastDir:
        if rodecast.startswith("roadcast_") and rodecast.endswith(".log"):
            print(rodecast)
            evaluationsFileName["rodecast"]=rodecast

    for osi in  osiDir:
        if osi.endswith(".hdf5") and osi.startswith("osi_recording"):
            print(osi)
            evaluationsFileName["osi"]=osi
    return evaluationsFileName








def stop_ndas_ds_container():
    ndas = client.containers.get("ndas")
    ds = client.containers.get("drivesim-ov")
    ndas.stop()
    ds.stop()

with DAG(
    dag_id="run_evaluations",
    schedule=None,
    start_date=pendulum.datetime(2021, 1, 1, tz="Asia/Shanghai"),
    catchup=False,
    dagrun_timeout=datetime.timedelta(minutes=60),
    tags=["siltest"]
) as dag:

    start_ndas = EmptyOperator(task_id='start_ndas', dag=dag) 
    #clean_up_nano_osi_roadcast_file = BashOperator(task_id="clean_up_nano_osi_roadcast_file_task",bash_command=clean_up_nano_osi_roadcast_file)

    #create_ndas_container = PythonOperator(task_id='create_ndas_container_task',python_callable=run_ndas_container,do_xcom_push=True,dag=dag) 
    #create_drivesim_container = PythonOperator(task_id='create_drivesim_container_task',python_callable=run_drivesim_container,do_xcom_push=True,dag=dag) 
    
    #scenario_waiting_on_Control = BashOperator(task_id="scenario_waiting_on_control_task",bash_command=watch_scenario,params = {'container_name' : 'drivesim-ov'})
    
    #run_ndas_script = PythonOperator(task_id='run_ndas_script_task',python_callable=run_ndas_script,do_xcom_push=True,dag=dag)

    #watch_scenario_completed = BashOperator(task_id="watch_scenario_completed_task",bash_command=watch_scenario_completed,params = {'container_name' : 'drivesim-ov'})
    #evaluations = BashOperator(task_id="backup_nano_osi_roadcast_task",bash_command=evaluations_report,params={"airflowDagPath":airflowDagPath,"siltestDir":siltestDir,"testCaseName":testCasePath.split("scenarios/")[1],"ncdPath":ncdPath,"rrLogPath":rrLogPath})
    evaluations = BashOperator(task_id="backup_nano_osi_roadcast_task",bash_command=evaluations_report,params={"airflowDagPath":airflowDagPath,"siltestDir":siltestDir,"testCaseName":testCasePath})

    #stop_ndas_ds_container = PythonOperator(task_id='stop_ndas_ds_container_task',python_callable=stop_ndas_ds_container,do_xcom_push=True,dag=dag) 

start_ndas   >> evaluations 

#stop_ndas_ds_container







if __name__ == "__main__":
    dag.cli()
