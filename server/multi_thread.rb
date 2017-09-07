require 'socket'
require_relative '../ftp/protocol_handler'

module FTP
  class MultiThread

    # 用 Connection 实例隔离每个请求
    Connection = Struct.new(:client) do

      def gets
        client.gets(CRLF)
      end

      def respond(msg)
        client.write(msg + CRLF)
      end

      # 关闭实例的连接
      def close
        client.close
      end
    end

    def initialize(server_port = 21)
      @control_socket = TCPServer.new(server_port)

      Signal.trap(:INT) { exit }
    end

    def run
      puts "服务启动 MultiThread"
      Thread.abort_on_exception = true

      # 循环接受连接
      loop do

        # accept 为阻塞操作, 直到有新连接时才生成新线程
        client = Connection.new(@control_socket.accept)
        Thread.new do
          client.respond "220 你好"

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