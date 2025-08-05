import subprocess
import os
import signal

# 捕获终止信号，确保子进程也被终止
def handle_signal(signum, frame):
    os.killpg(os.getpgid(process.pid), signal.SIGTERM)
    exit(0)

signal.signal(signal.SIGTERM, handle_signal)
signal.signal(signal.SIGINT, handle_signal)

# 以root用户启动Jupyter
process = subprocess.Popen(
    ['sudo', '-E', './start_server.sh'],
    preexec_fn=os.setsid  # 创建新的进程组
)

# 启动Gradio界面
import gradio as gr

def dummy_function(text):
    return text

iface = gr.Interface(
    fn=dummy_function,
    inputs="text",
    outputs="text",
    title="Jupyter Lab",
    description="Jupyter Lab is running in the background"
)

iface.launch()
