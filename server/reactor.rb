require 'socket'
require_relative '../ftp/protocol_handler'

module FTP
  class Reactor
    BUFFER = 1024 * 16 # 16KB

    class Connection

      attr_reader :client

      def initialize(client)
        @client = client
        @response = ''
        @request = ''
        # 因为每个请求调用的respond有了区分, 所以handler也应该包在实例对象里来进行隔离
        @handler = ProtocolHandler.new(self)

        nonblock_respond "220 你好"
      end

      # 非阻塞得接受数据或数据片段
      def nonblock_gets(data_part)
        @request << data_part

        # 如果积攒到一条完整命令了就执行
        if @request.end_with?(CRLF)
          nonblock_respond @handler.handle @request
          @request = ''
        end

      end

      def nonblock_respond(msg)
        @response << msg + CRLF

        nonblock_write
      end

      # 兼容 protocol_handler 中的调用
      alias_method :respond, :nonblock_respond

      def nonblock_write
        bytes = client.write_nonblock(@response)
        @response.slice!(0, bytes)
      end

      def ready_for_reading?
        true
      end

      def ready_for_writing?
        not @response.empty?
      end

    end


    def initialize(server_port = 21)
      @control_socket = TCPServer.new(server_port)
      Signal.trap(:INT) { exit }
    end

    def run
      puts "服务启动 Reactor"

      @handles = {}

      loop do
        to_read = @handles.values.select(&:ready_for_reading?).map(&:client)
        to_write = @handles.values.select(&:ready_for_writing?).map(&:client)

        # io复用, select 非阻塞
        readables, writables = IO.select(to_read + [@control_socket], to_write)

        readables.each do |socket|
          if socket == @control_socket
            # 新进连接
            io = @control_socket.accept
            conn = Connection.new(io)
            @handles[io.fileno] = conn

          else
            conn = @handles[socket.fileno]

            begin
              data = socket.read_nonblock(BUFFER)
              conn.nonblock_gets data
            rescue Errno::EAGAIN
              'do nothing'
            rescue EOFError
              @handles.delete(socket.fileno)
            end

          end
        end

        writables.each do |socket|
          conn = @handles[socket.fileno]

          conn.nonblock_write if conn
        end
      end
    end
  end
end