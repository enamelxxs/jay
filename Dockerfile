FROM nvidia/cuda:11.3.1-base-ubuntu20.04

ENV DEBIAN_FRONTEND=noninteractive \
    TZ=Europe/Paris

# 安装基础工具
RUN rm -f /etc/apt/sources.list.d/*.list && \
    apt-get update && apt-get install -y --no-install-recommends \
    wget \
    curl \
    ca-certificates \
    git \
    git-lfs \
    zip \
    unzip \
    htop \
    bzip2 \
    libx11-6 \
    build-essential \
    software-properties-common \
 && rm -rf /var/lib/apt/lists/*

# 创建工作目录
RUN mkdir -p /home/xlab-app-center
WORKDIR /home/xlab-app-center

# 设置环境变量
ENV HOME=/home/xlab-app-center
RUN mkdir $HOME/.cache $HOME/.config && chmod -R 777 $HOME

# 安装 Miniconda
ENV CONDA_AUTO_UPDATE_CONDA=false \
    PATH=/root/miniconda/bin:$PATH
RUN curl -sLo /miniconda.sh https://repo.continuum.io/miniconda/Miniconda3-py39_4.10.3-Linux-x86_64.sh \
 && chmod +x /miniconda.sh \
 && /miniconda.sh -b -p /root/miniconda \
 && rm /miniconda.sh \
 && conda clean -ya

# 安装系统依赖
RUN --mount=target=packages.txt,source=packages.txt \
    apt-get update && \
    xargs -r -a packages.txt apt-get install -y --no-install-recommends \
    && rm -rf /var/lib/apt/lists/*

# 执行启动脚本
RUN --mount=target=on_startup.sh,source=on_startup.sh \
    bash on_startup.sh

# 安装 Python 依赖
RUN --mount=target=requirements.txt,source=requirements.txt \
    pip install --no-cache-dir --upgrade -r requirements.txt

# 复制文件到工作目录
COPY . /home/xlab-app-center

# 设置权限
RUN chmod +x /home/xlab-app-center/start_server.sh

# 复制登录页面
RUN mkdir -p /root/miniconda/lib/python3.9/site-packages/jupyter_server/templates
COPY login.html /root/miniconda/lib/python3.9/site-packages/jupyter_server/templates/login.html

# 设置环境变量
ENV PYTHONUNBUFFERED=1 \
    GRADIO_ALLOW_FLAGGING=never \
    GRADIO_NUM_PORTS=1 \
    GRADIO_SERVER_NAME=0.0.0.0 \
    GRADIO_THEME=huggingface \
    SYSTEM=spaces \
    SHELL=/bin/bash

# 设置工作目录
WORKDIR /home/xlab-app-center

# 启动命令
CMD ["python", "app.py"]
