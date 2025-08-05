import subprocess
import gradio as gr

# 启动Jupyter服务
subprocess.Popen(["./start_server.sh"])

# 创建简单的Gradio界面
gr.Interface(lambda x: x, "text", "text").launch()
