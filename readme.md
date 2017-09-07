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


# Step3 FTP::MultiThread

主线程接受请求, 将每个请求交由一个新的线程处理, 子线程处理完成后即销毁, 把资源返还给系统.
可以同时处理多个请求, 每个请求之间共享进程内存. 用 `Connection` 对象实例级别的隔离.
相比衍生新的进程要便宜许多, 但还是受资源限制, 过高的并发会令服务崩溃.


# Step4 FTP::ProcessPool

为了限制 `MultiProcess` 模式子进程的数量, 提高处理新请求的响应速度,
本模式预先衍生出一定数量的子进程(prefork), 是 `Serial` 模式的多开版本.
主进程负责子进程池的填充/销毁/维护, 具体的请求处理在子进程中进行.
新请求分配给哪个子进程处理的问题由系统内核负责.


# Step5 FTP::ThreadPool

使用线程池代替进程池以节省开销.注意请求以 `Connection` 的实例对象作为隔离.
主线程只负责填充线程池, 完成后令其 sleep .

# Step6 FTP::Reactor

反应器模式, 将大块读写操作切碎然后非阻塞执行.
请求以 `Connection` 的实例对象作为隔离, 对象内保有其散碎的数据.
所有 socket 对象 以其文件描述符为 key , socket 对象本身为 value, 存储在 `@handlers` 这个中央连接复用器中(Hash).
事件分发器(主循环)使用 `select` 系统调用, 非阻塞地处理读写.


> 详细内容请参考:  [https://www.jstorimer.com/pages/books](https://www.jstorimer.com/pages/books)