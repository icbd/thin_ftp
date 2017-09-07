# thin_ftp

一个 FTP Server Demo, 仅用于练习 Socket 编程.

启动服务后 server 监听 21 端口, 用于命令传输.

文件传输采用 FTP 主动模式, client 发送 `PORT ip1,ip2,ip3,ip4,port1,port2` 格式的数据, 由 server 主动向其发起请求, 用于文件传输.


`FTP::ProtocolHandler` 负责具体的协议处理, `FTP::Serial` 等负责 socket 处理.



### 启动服务器

```
$ ruby main.rb
```

### 使用ftp客户端

```
$ ftp -a -v 127.0.0.1 3000
```


# Step1 FTP::Serial

串行执行.同时只能处理一个请求.


# Step2 FTP::MultiProcess

父进程接受请求, 将每个请求交由一个新的子进程处理, 子进程处理完成后即销毁, 把资源返还给系统.
可以同时处理多个请求, 每个请求都有进程级别的隔离, 互不干扰. 但是衍生子进程又贵又慢.




