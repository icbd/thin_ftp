require 'logger'
require_relative 'server/serial'
require_relative 'server/multi_process'
require_relative 'server/multi_thread'
require_relative 'server/process_pool'
require_relative 'server/thread_pool'
require_relative 'server/reactor'

$logger = Logger.new("log/server-#{Time.now.to_s[0...10]}.log")

# server = FTP::Serial.new(3000)
# server = FTP::MultiProcess.new(3000)
# server = FTP::MultiThread.new(3000)
# server = FTP::ProcessPool.new(3000)
# server = FTP::ThreadPool.new(3000)
server = FTP::Reactor.new(3000)
server.run