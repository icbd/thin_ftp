require 'logger'
require_relative 'server/serial'
require_relative 'server/multi_process'

$logger = Logger.new("log/server-#{Time.now.to_s[0..10]}.log")

server = FTP::MultiProcess.new(3000)
server.run