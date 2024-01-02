---
title: sql server docker镜像配置
ZHtags: 
  - database
key: sqlserver-docker
date: '2022-08-19'
lastmod: '2022-08-19'
---
# 1.拉取docker镜像
```bash
sudo docker pull mcr.microsoft.com/mssql/server:2022-latest
```
# 2.创建并运行docker镜像
```bash
sudo docker run -e "ACCEPT_EULA=Y" -e "MSSQL_SA_PASSWORD=<YourPassword>" \
   -p 1433:1433 --name sql1 --hostname sql1 \
   -d \
   mcr.microsoft.com/mssql/server:2022-latest
```
注：开放1433端口以进行数据库连接，docker镜像名称为sql1
# 3. 查看sql server服务器是否准备好连接
```bash
docker exec -t sql1 cat /var/opt/mssql/log/errorlog | grep connection
```
# 4.设置管理员密码
```bash
sudo docker exec -it sql1 /opt/mssql-tools/bin/sqlcmd \
-S localhost -U SA \
 -P "$(read -sp "Enter current SA password: "; echo "${REPLY}")" \
 -Q "ALTER LOGIN SA WITH PASSWORD=\"$(read -sp "Enter new SA password: "; echo "${REPLY}")\""
```
# 5.连接数据库
## 进入docker容器内运行bash并连接数据库
```bash
sudo docker exec -it sql1 "bash"

/opt/mssql-tools/bin/sqlcmd -S localhost -U SA -P "<YourNewStrong@Passw0rd>"
```
## 使用jdbc驱动连接数据库
```java
import java.sql.*;
import java.util.Scanner;
public class SQLDatabaseConnection {
    // Connect to your database.
    // Replace server name, username, and password with your credentials
    public static void Judge(int biao,String a){
        if(biao==1){
            System.out.println(a+"成功！");
        }
        else{
            System.out.println(a+"失败!");
        }
    }
    public static void main(String[] args) {
        String connectionUrl =
                "jdbc:sqlserver://yourdomain:1433;"
                        + "database=yourdatabase;"
                        + "user=username;"
                        + "password=yourpassword;"
                        + "trustServerCertificate=true;"

        try (Connection connection = DriverManager.getConnection(connectionUrl);) {
            System.out.println("数据库连接成功:");
        }catch (SQLException e) {
            e.printStackTrace();
            System.out.println("数据库连接失败,请检查您的网络！");
        }
    }
}
```
**注意：中文输入请规定数据类型为nvarchar,否则显示中文为问号**