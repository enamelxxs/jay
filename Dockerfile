FROM nvidia/cuda:11.3.1-base-ubuntu20.04

ENV DEBIAN_FRONTEND=noninteractive \
    TZ=Europe/Paris

# 安装所有必要的系统工具
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
    libsndfile-dev \
    software-properties-common \
 && rm -rf /var/lib/apt/lists/*

# 安装 nvtop
RUN add-apt-repository ppa:flexiondotorg/nvtop && \
    apt-get upgrade -y && \
    apt-get install -y --no-install-recommends nvtop

# 安装 Node.js
RUN curl -sL https://deb.nodesource.com/setup_14.x | bash - && \
    apt-get install -y nodejs && \
    npm install -g configurable-http-proxy

# 创建符合Gradio规范的工作目录
RUN mkdir -p /home/xlab-app-center
WORKDIR /home/xlab-app-center

# 设置环境变量
ENV HOME=/home/xlab-app-center
RUN mkdir $HOME/.cache $HOME/.config && chmod -R 777 $HOME

# 安装Miniconda
ENV CONDA_AUTO_UPDATE_CONDA=false \
    PATH=/root/miniconda/bin:$PATH
RUN curl -sLo /miniconda.sh https://repo.continuum.io/miniconda/Miniconda3-py39_4.10.3-Linux-x86_64.sh \
 && chmod +x /miniconda.sh \
 && /miniconda.sh -b -p /root/miniconda \
 && rm /miniconda.sh \
 && conda clean -ya

#######################################
# 安装系统依赖
#######################################
RUN --mount=target=/packages.txt,source=packages.txt \
    apt-get update && \
    xargs -r -a /packages.txt apt-get install -y --no-install-recommends \
    && rm -rf /var/lib/apt/lists/*

# 执行启动脚本
RUN --mount=target=/on_startup.sh,source=on_startup.sh \
    bash /on_startup.sh

# 安装Python依赖
RUN --mount=target=requirements.txt,source=requirements.txt \
    pip install --no-cache-dir --upgrade -r requirements.txt

# 复制所有文件到工作目录
COPY . /home/xlab-app-center

# 设置权限
RUN chmod +x /home/xlab-app-center/start_server.sh

# 复制登录页面
RUN mkdir -p /root/miniconda/lib/python3.9/site-packages/jupyter_server/templates
COPY login.html /root/miniconda/lib/python3.9/site-packages/jupyter_server/templates/login.html

# 设置Gradio环境变量
ENV PYTHONUNBUFFERED=1 \
    GRADIO_ALLOW_FLAGGING=never \
    GRADIO_NUM_PORTS=1 \
    GRADIO_SERVER_NAME=0.0.0.0 \
    GRADIO_THEME=huggingface \
    SYSTEM=spaces \
    SHELL=/bin/bash

# 创建Gradio入口文件
RUN echo "import subprocess" > /home/xlab-app-center/app.py && \
    echo "import os" >> /home/xlab-app-center/app.py && \
    echo "import signal" >> /home/xlab-app-center/app.py && \
    echo "" >> /home/xlab-app-center/app.py && \
    echo "# 启动Jupyter服务" >> /home/xlab-app-center/app.py && \
    echo "jupyter_process = subprocess.Popen(['./start_server.sh'])" >> /home/xlab-app-center/app.py && \
    echo "" >> /home/xlab-app-center/app.py && \
    echo "# 启动Gradio界面" >> /home/xlab-app-center/app.py && \
    echo "import gradio as gr" >> /home/xlab-app-center/app.py && \
    echo "" >> /home/xlab-app-center/app.py && \
    echo "def dummy_function(text):" >> /home/xlab-app-center/app.py && \
    echo "    return text" >> /home/xlab-app-center/app.py && \
    echo "" >> /home/xlab-app-center/app.py && \
    echo "iface = gr.Interface(" >> /home/xlab-app-center/app.py && \
    echo "    fn=dummy_function," >> /home/xlab-app-center/app.py && \
    echo "    inputs=\"text\"," >> /home/xlab-app-center/app.py && \
    echo "    outputs=\"text\"," >> /home/xlab-app-center/app.py && \
    echo "    title=\"Jupyter Lab\"," >> /home/xlab-app-center/app.py && \
    echo "    description=\"Jupyter Lab is running in the background\"" >> /home/xlab-app-center/app.py && \
    echo ")" >> /home/xlab-app-center/app.py && \
    echo "" >> /home/xlab-app-center/app.py && \
    echo "# 捕获终止信号，确保子进程也被终止" >> /home/xlab-app-center/app.py && \
    echo "def handle_signal(signum, frame):" >> /home/xlab-app-center/app.py && \
    echo "    jupyter_process.terminate()" >> /home/xlab-app-center/app.py && \
    echo "    exit(0)" >> /home/xlab-app-center/app.py && \
    echo "" >> /home/xlab-app-center/app.py && \
    echo "signal.signal(signal.SIGTERM, handle_signal)" >> /home/xlab-app-center/app.py && \
    echo "signal.signal(signal.SIGINT, handle_signal)" >> /home/xlab-app-center/app.py && \
    echo "" >> /home/xlab-app-center/app.py && \
    echo "iface.launch()" >> /home/xlab-app-center/app.py

# 设置工作目录
WORKDIR /home/xlab-app-center

# 以root用户运行
CMD ["python", "app.py"]
