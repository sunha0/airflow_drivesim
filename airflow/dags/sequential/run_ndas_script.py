import sys
from airflow.operators.docker_operator import DockerOperator
import docker

client = docker.DockerClient(base_url=f"tcp://" + sys.argv[1] + ":2375", version="auto")  # 创建一个docker客户端


def run_ndas_script():
    ndas = client.containers.get("ndas")

    print("containerInfo:", ndas)

    ndas.exec_run(cmd="./run_ndas.sh", workdir="/home", detach=True)
