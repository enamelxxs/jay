import subprocess
import os
import signal
import time

# 使用绝对路径启动 Jupyter 服务
script_path = "/home/xlab-app-center/start_server.sh"
jupyter_process = subprocess.Popen(
    [script_path],
    preexec_fn=os.setsid
)

# 启动 Gradio 界面
import gradio as gr

def dummy_function():
    return "Jupyter Lab 正在后台运行中，请稍候..."

# 等待 Jupyter 启动
time.sleep(5)

iface = gr.Interface(
    fn=dummy_function,
    inputs=None,
    outputs="text",
    title="Jupyter Lab",
    description="系统正在启动 Jupyter Lab 服务..."
)

# 信号处理函数
def handle_signal(signum, frame):
    os.killpg(os.getpgid(jupyter_process.pid), signal.SIGTERM)
    exit(0)

signal.signal(signal.SIGTERM, handle_signal)
signal.signal(signal.SIGINT, handle_signal)

iface.launch()
