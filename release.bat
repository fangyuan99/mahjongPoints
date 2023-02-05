@REM 把./dist目录下的文件拷贝到D:\python_project\mysite\-\mj
xcopy .\dist D:\python_project\mysite\-\mj /s /e /y
@REM 切换到D:\python_project\mysite\-\mj目录下，执行git push
cd D:\python_project\mysite\-\mj
D:
git add .
@REM 获取用户输入的commit信息
set /p commit=please input commit info:
git commit -m "%commit%"
git push -f