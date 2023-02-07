# 先执行bulid.bat，再执行release.bat

import os

# 执行命令
def exec_cmd(cmd):
    print("执行命令：" + cmd)
    os.system(cmd)

# main
if __name__ == "__main__":
    # 运行bulid.bat
    exec_cmd("yarn b")
    # 运行release.bat
    exec_cmd("release.bat")