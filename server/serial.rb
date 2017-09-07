require 'socket'
require_relative '../ftp/protocol_handler'

module FTP
  class Serial

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
      puts "服务启动 Serial"

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
            @client.close
            break
          end
        end
      end

    end

  end
end