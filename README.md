# autoUpdate
A shell script auto login hosts listed in a file and upload a &lt;srv-script> and zip file to a special directory then run &lt;srv-script> on all hosts.

自动升级列表中主机目录下的应用。
```
autoUpdate.sh -f host.txt -a ./agent.zip
```
## 选项
* -f 必须选项，指定需要升级的主机信息：主机IP,主机ssh登陆端口,用户名,密码,agent安装路径
在登陆信息错误或路径错误时，无法完成升级。
* -a 必须选项，指定新版本agent的路径
* -r 非必须项目，默认使用srv.sh，该脚本上传各server以执行升级操作，可以指定其他路径脚本
* -h 打印命令帮助

