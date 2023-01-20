
@REM 把./dist目录下的文件拷贝到D:\python_project\个人网站\-\mj
copy .* D:\python_project\个人网站\-\mj /Y
@REM 切换到D:\python_project\个人网站\-\mj目录下，执行git push
cd D:\python_project\个人网站\-\mj
D:
git add .
git commit -m "update"
git push