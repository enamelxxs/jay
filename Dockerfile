FROM nvidia/cuda:11.3.1-base-ubuntu20.04

ENV DEBIAN_FRONTEND=noninteractive \
    TZ=Europe/Paris

RUN rm -f /etc/apt/sources.list.d/*.list && \
    apt-get update && apt-get install -y --no-install-recommends \
    wget \
    curl \
    ca-certificates \
    sudo \
    git \
    git-lfs \
    zip \
    unzip \
    htop \
    bzip2 \
    libx11-6 \
    build-essential \
    libsndfile-dev \
    software-properties-common \
 && rm -rf /var/lib/apt/lists/*

RUN add-apt-repository ppa:flexiondotorg/nvtop && \
    apt-get upgrade -y && \
    apt-get install -y --no-install-recommends nvtop

RUN curl -sL https://deb.nodesource.com/setup_14.x  | bash - && \
    apt-get install -y nodejs && \
    npm install -g configurable-http-proxy

# 创建符合Gradio规范的工作目录
RUN mkdir -p /home/xlab-app-center && chmod 777 /home/xlab-app-center
WORKDIR /home/xlab-app-center

# 创建非root用户
RUN adduser --disabled-password --gecos '' --shell /bin/bash xlab-app-center \
 && chown -R xlab-app-center:xlab-app-center /home/xlab-app-center
RUN echo "xlab-app-center ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/90-user
USER xlab-app-center

# 设置环境变量
ENV HOME=/home/xlab-app-center
RUN mkdir $HOME/.cache $HOME/.config && chmod -R 777 $HOME

# 安装Miniconda
ENV CONDA_AUTO_UPDATE_CONDA=false \
    PATH=$HOME/miniconda/bin:$PATH
RUN curl -sLo ~/miniconda.sh https://repo.continuum.io/miniconda/Miniconda3-py39_4.10.3-Linux-x86_64.sh \
 && chmod +x ~/miniconda.sh \
 && ~/miniconda.sh -b -p ~/miniconda \
 && rm ~/miniconda.sh \
 && conda clean -ya

#######################################
# Root用户操作
#######################################
USER root

# 安装Debian依赖
RUN --mount=target=/root/packages.txt,source=packages.txt \
    apt-get update && \
    xargs -r -a /root/packages.txt apt-get install -y --no-install-recommends \
    && rm -rf /var/lib/apt/lists/*

# 执行启动脚本
RUN --mount=target=/root/on_startup.sh,source=on_startup.sh,readwrite \
    bash /root/on_startup.sh

# 设置目录权限
RUN chown -R xlab-app-center:xlab-app-center $HOME

#######################################
# 切换回应用用户
#######################################
USER xlab-app-center

# 安装Python依赖
RUN --mount=target=requirements.txt,source=requirements.txt \
    pip install --no-cache-dir --upgrade -r requirements.txt

# 复制文件到工作目录
COPY --chown=xlab-app-center . .

# 设置权限
RUN chmod +x start_server.sh

# 复制登录页面
RUN mkdir -p $HOME/miniconda/lib/python3.9/site-packages/jupyter_server/templates
COPY --chown=xlab-app-center login.html $HOME/miniconda/lib/python3.9/site-packages/jupyter_server/templates/login.html

# 设置Gradio环境变量
ENV PYTHONUNBUFFERED=1 \
    GRADIO_ALLOW_FLAGGING=never \
    GRADIO_NUM_PORTS=1 \
    GRADIO_SERVER_NAME=0.0.0.0 \
    GRADIO_THEME=huggingface \
    SYSTEM=spaces \
    SHELL=/bin/bash

# 创建Gradio入口文件
RUN echo "import subprocess" > app.py && \
    echo "subprocess.Popen(['./start_server.sh'])" >> app.py && \
    echo "import gradio as gr" >> app.py && \
    echo "gr.Interface(lambda x: x, 'text', 'text').launch()" >> app.py

CMD ["python", "app.py"]
