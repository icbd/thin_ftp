require 'socket'
require 'thread'
require_relative '../ftp/protocol_handler'

module FTP
  class ThreadPool

    Connection = Struct.new(:client) do
      def gets
        client.gets(CRLF)
      end

      def respond(msg)
        client.write(msg + CRLF)
      end

      def close
        client.close
      end
    end

    def initialize(server_port = 21, pool_size = 20)
      @pool_size = pool_size
      @control_socket = TCPServer.new(server_port)

      Signal.trap(:INT) { exit }
    end

    def run
      puts '服务启动 ThreadPool'

      Thread.abort_on_exception = true
      pool = ThreadGroup.new

      3.times do
        pool.add spawn_thread
      end

      # 阻止主线程结束
      sleep
    end


    # 新建线程
    def spawn_thread
      Thread.new do

        # 循环接受连接
        loop do

          # accept 为阻塞操作
          client = Connection.new(@control_socket.accept)
          client.respond "200 你好"

          handler = ProtocolHandler.new(client)

          # 循环处理命令
          loop do
            request = client.gets

            if request
              client.respond handler.handle request
            else
              client.close
              break
            end
          end
        end
      end
    end

  end
end