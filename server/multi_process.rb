require 'socket'
require_relative '../ftp/protocol_handler'

module FTP
  class MultiProcess

    attr_reader :client

    def initialize(server_port = 21)
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
      puts "服务启动 MultiProcess"

      # 循环接受连接
      loop do
        # accept 为阻塞操作, 直到有新连接时才 fork 子进程
        @client = @control_socket.accept

        pid = fork do
          respond "200 你好"
          handler = ProtocolHandler.new(self)

          # 循环处理命令
          loop do
            request = gets

            if request
              respond handler.handle request
            else
              @client.close
              break
            end

          end

        end

        # 分离子进程, 防止变僵尸进程
        Process.detach pid
      end

    end

  end
end