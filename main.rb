require 'logger'
require_relative 'server/serial'
require_relative 'server/multi_process'
require_relative 'server/multi_thread'

$logger = Logger.new("log/server-#{Time.now.to_s[0..10]}.log")

server = FTP::MultiThread.new(3000)
server.run