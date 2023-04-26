import sys
from airflow.operators.docker_operator import DockerOperator
from docker.types import Mount
import docker

client = docker.DockerClient(base_url=f"tcp://" + sys.argv[1] + ":2375", version="auto")  # 创建一个docker客户端


def run_drivesim_container():
    drivesim = client.containers.run(
        image=drivesimImage,
        command=[
            f"bash /drivesim-ov/run_sim_airflow.sh " + sys.argv[2]
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
        ulimits=[docker.types.Ulimit(name='memlock', hard=-1, soft=-1),
                 docker.types.Ulimit(name='nofile', hard=65535, Soft=65535)],
        device_requests=[docker.types.DeviceRequest(count=-1, capabilities=[['gpu']])],
        environment={
            "CUDA_VISIBLE_DEVICES": "1,2,3,4,5,6,7",
            "OMNI_USER": "omniverse",
            "OMNI_PASS": "123456",
            "DISPLAY": ":0",
            "ACCEPT_EULA": "Y"},
        extra_hosts={"drivesim2-rel.ov.nvidia.com": "10.229.0.223"},

        mounts=[
            Mount(target="/tmp/.X11-unix", source="/tmp/.X11-unix", type="bind"),
            Mount(target="/etc/timezone", source="/etc/timezone", type="bind"),
            Mount(target="/etc/localtime", source="/etc/localtime", type="bind"),
            Mount(source=cacheDir + "/.cache", target="/drivesim-ov/.cache", type="bind"),
            Mount(source=cacheDir + "/.local", target="/drivesim-ov/.local", type="bind"),
            Mount(source=cacheDir + "/.nv", target="/drivesim-ov/.nv", type="bind"),
            Mount(source=cacheDir + "/.nvidia-omniverse", target="/drivesim-ov/.nvidia-omniverse", type="bind"),
            Mount(source=siltestDir + "/digital-testing-product/testcase_assets", target="/drivesim-ov/testcase_assets",
                  type="bind"),
            Mount(source=airflowDagPath + "/run_sim_airflow.sh", target="/drivesim-ov/run_sim_airflow.sh", type="bind"),
            # Mount(source=siltestDir+"/log/ds2_run.log",target="/drivesim-ov/ds2_run.log",type="bind"),
            # Mount(source=siltestDir+"/log/scenario_run.log",target="/drivesim-ov/scenario_run.log",type="bind"),
        ]
    )
    print(drivesim)


run_drivesim_container()
