require 'logger'
require_relative 'server/serial'
require_relative 'server/multi_process'
require_relative 'server/multi_thread'
require_relative 'server/process_pool'

$logger = Logger.new("log/server-#{Time.now.to_s[0..10]}.log")

server = FTP::ProcessPool.new(3000)
server.run