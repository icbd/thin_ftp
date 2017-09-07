require 'logger'

module FTP
  CRLF = "\r\n"

  class ProtocolHandler

    attr_reader :conn
    
    # conn 需要响应 response 方法
    def initialize(conn)
      @conn = conn
    end

    def handle(cmd_str)
      logger.debug("handle cmd_str:#{cmd_str}")

      cmd = cmd_str.split[0].upcase rescue ''
      param = cmd_str.split[1] rescue ''

      case cmd
        when "PASV"
          "100 被动模式"

        when "QUIT"
          "221 断开连接"

        when "USER"
          "230 匿名用户"

        when "SYST"
          "215 UNIX"

        when "CWD"
          if File.directory?(param)
            @pwd = param
            "250 切换目录至 '#{pwd}'"
          else
            "550 未知目录 '#{param}'"
          end

        when "PWD"
          "257 当前目录为 '#{pwd}'"

        when "PORT"
          # 主动模式
          # 协议规定文件传送前, client发送类似 `PORT 192,168,100,116,239,134` 的消息.
          # client host: 192.168.100.116
          # client port: 239 * 256 + 134

          begin
            sub_params = param.split(',')
            client_host = sub_params[0..3].join('.')
            client_port = Integer(sub_params[4]) * 256 + Integer(sub_params[5])

            @transport = TCPSocket.new(client_host, client_port)
            "200 连接建立 '#{client_port}:#{client_port}'"
          rescue
            return "502 PORT参数有误"
          end

        when "RETR"
          # 在数据通道上传送文件

          begin
            file_name = File.join(pwd, param)
            logger.debug("RETR file_name:#{file_name}")

            File.open(file_name, 'r') do |file|
              conn.respond("125 准备发送数据 #{file.size} bytes")
              bytes = IO.copy_stream(file, @transport)
              @transport.close

              logger.warn("文件发送中断 '#{file_name}'") if file.size > bytes

              "226 发送完成 #{bytes} bytes"
            end

          rescue Errno::ENOENT => e
            logger.warn e
            "404 文件没找到 '#{file_name}'"
          rescue StandardError => e
            logger.warn e
            "404 文件传送失败"
          end

        when "LIST"
          conn.respond "125 目录清单"

          file_list = Dir.entries(pwd).join(CRLF) + CRLF

          @transport.write file_list
          @transport.close

          "226 发送完成 #{file_list.size} bytes"

        else
          "502 未知操作 '#{cmd}'"

      end
    end

    def pwd
      @pwd || Dir.pwd
    end

    private

    def logger
      $logger || Logger.new($stdout)
    end
  end
end