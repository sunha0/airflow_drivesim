import sys
from airflow.operators.docker_operator import DockerOperator
from docker.types import Mount
import docker

client = docker.DockerClient(base_url=f"tcp://" + sys.argv[1] + ":2375", version="auto")  # 创建一个docker客户端


def run_ndas_container():
    ndas = client.containers.run(
        image=ndasImage,
        name="ndas",
        user="nvidia",
        privileged=True,
        ipc_mode="shareable",
        sysctls={"fs.mqueue.msg_max": 4096},
        network_mode="host",
        device_requests=[docker.types.DeviceRequest(count=-1, capabilities=[['gpu']])],
        auto_remove=True,
        tty=True,
        detach=True,
        environment={"DISPLAY": "-1"},
        working_dir="/usr/local/driveworks/apps/roadrunner-2.0/config",
        entrypoint="/home/entry.sh",
        mounts=[
            Mount(target="/tmp/.X11-unix", source="/tmp/.X11-unix", type="bind"),
            Mount(target="/home/rrLog", source=f"" + sys.argv[1] + "/rrLog", type="bind"),
            Mount(target="/etc/timezone", source="/etc/timezone", type="bind"),
            Mount(target="/etc/localtime", source="/etc/localtime", type="bind"),
            Mount(source=airflowDagPath + "/run_ndas.sh", target="/home/run_ndas.sh", type="bind"),
        ]
    )

    print(ndas)


run_ndas_container()
