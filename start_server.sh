#!/bin/bash
# 确保脚本以root用户运行
if [ "$(id -u)" != "0" ]; then
    echo "This script must be run as root" >&2
    exit 1
fi

JUPYTER_TOKEN="${JUPYTER_TOKEN:=huggingface}"

echo "Starting Jupyter Lab as root with token $JUPYTER_TOKEN"

# 使用Gradio规范的工作目录
NOTEBOOK_DIR="/home/xlab-app-center"

jupyter-lab \
    --ip 0.0.0.0 \
    --port 7860 \
    --no-browser \
    --allow-root \
    --ServerApp.token="$JUPYTER_TOKEN" \
    --ServerApp.tornado_settings="{'headers': {'Content-Security-Policy': 'frame-ancestors *'}}" \
    --ServerApp.cookie_options="{'SameSite': 'None', 'Secure': True}" \
    --ServerApp.disable_check_xsrf=True \
    --LabApp.news_url=None \
    --LabApp.check_for_updates_class="jupyterlab.NeverCheckForUpdate" \
    --notebook-dir=$NOTEBOOK_DIR
