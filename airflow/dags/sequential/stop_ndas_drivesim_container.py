import sys
from airflow.operators.docker_operator import DockerOperator
from docker.types import Mount
import docker

client = docker.DockerClient(base_url=f"tcp://" + sys.argv[1] + ":2375", version="auto")  # 创建一个docker客户端

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
