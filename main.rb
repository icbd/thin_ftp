require 'logger'
require_relative 'server/serial'

$logger = Logger.new("log/server-#{Time.now.to_s[0..10]}.log")

server = FTP::Serial.new(3000)
server.run