require 'socket'
require_relative '../ftp/protocol_handler'

module FTP
  class ProcessPool

    attr_reader :client

    def initialize(server_port = 21, pool_size = 5)
      # prefork 的进程数目
      @pool_size = pool_size
      @control_socket = TCPServer.new(server_port)

      Signal.trap(:INT) { exit }
    end

    def gets
      client.gets(CRLF)
    end

    def respond(msg)
      client.write(msg + CRLF)
    end

    def run
      puts "服务启动 ProcessPool"

      pool = []
      @pool_size.times do
        pool << spawn_process
      end

      # 主进程收到结束信号后告知各个子进程
      Signal.trap(:INT) do
        pool.each do |son_pid|
          begin
            Process.kill(:INT, son_pid)
          rescue StandardError => e
            logger.error(e)
            logger.error("子进程终结失败.")
          end
        end

        exit
      end

      # 监控子进程状态
      # 若是其自己退出肯定是出错崩溃了, 需要再启动一个填满进程池
      loop do
        # wait 为阻塞操作, 没有子进程结束就一直阻塞
        bad_pid = Process.wait
        pool.delete bad_pid
        new_pid = spawn_process
        pool << new_pid

        logger.warn "pid:#{bad_pid} 异常退出; 新衍生 pid:#{new_pid}"
      end

    end

    # 衍生子进程, 返回子进程pid
    def spawn_process
      fork do

        # 循环接受连接
        loop do

          # accept 为阻塞操作
          @client = @control_socket.accept
          respond "200 你好"

          handler = ProtocolHandler.new(self)

          # 循环处理命令
          loop do
            request = gets

            if request
              respond handler.handle request
            else
              client.close
              break
            end
          end
        end
      end
    end

    private

    def logger
      $logger || Logger.new($stdout)
    end

  end
end