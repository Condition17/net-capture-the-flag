#!/usr/bin/ruby

require 'socket'
require 'yaml'
require 'timeout'

def yaml_load(filename)
  YAML.load File.read filename
end

config = yaml_load('./config.txt')
@port = config[:port]
@own_server = config[:server_address]
@max_timeout = 1.5

srv = begin
    Timeout::timeout(@max_timeout) {TCPSocket.open(@own_server, @port)}
  rescue StandardError, RuntimeError => ex
    raise "Error - flag not generated: #{ex}."
  end
srv.puts('generate_flag')
srv.close