FROM jupyter/minimal-notebook

USER root

COPY ./jupyter/libs/dinoclib /home/jovyan/dinoclib

RUN pip install /home/jovyan/dinoclib && \
    fix-permissions $CONDA_DIR && fix-permissions /home/$NB_USER && \
    rm -rf /home/jovyan/dinoclib

RUN apt-get update -y && \
    apt-get install -y ca-certificates curl gnupg lsb-release && \
    mkdir -p /etc/apt/keyrings && \
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg && \
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null && \
    apt-get update -y --force-yes && \
    apt-get install -y --force-yes docker-ce docker-ce-cli containerd.io docker-compose-plugin && \
    usermod -aG docker $NB_USER && \
    newgrp docker
