#!/usr/bin/ruby

require 'socket'
require 'logger'
require 'yaml'
require_relative 'class_server'

semaphore = Mutex.new

def yaml_load(filename)
  YAML.load File.read filename
end

config = yaml_load('./config.txt')
personal_client = config[:client_address]

# log file, 100MB max
EVENT_CAPTURE_FLAG = Logger.new('./logs/captured_flags.log', 0, 100*1024*1024)

begin
  server = Server.new(port: config[:port], flag_present: config[:flag_present], author: config[:author_name], hosts: config[:hosts])
  puts "Starting net_capture_the_flag server on port #{server.port}."
  if server.flag_present
    puts 'Server has the flag'
  end
rescue Exception => exception
  puts "Something went wrong. Server not started: #{exception}"
end

loop {
  Thread.fork(server.accept) do |client|
    remote_ip = client.peeraddr.last
    if remote_ip == personal_client
      remote_ip = 'personal client'
      foreign_connection = false
    else
      foreign_connection = true
    end
    close_connection = false

    while !close_connection do
      request = client.gets.chomp
      method = request.split(' ').first
      argument = request.split(' ').last

      print "#{remote_ip} ask '#{request}' -> "

      case method
      when 'next_server'
          response = server.next_server(remote_ip)
          puts response
          client.puts response
        close_connection = true

      when 'who_are_you?'
        response = server.who_are_you?
        puts response
        client.puts response

      when 'have_flag?'
        if server.flag_present
          semaphore.synchronize{
            puts "YES #{server.unique_flag_token}"
            client.puts "YES #{server.unique_flag_token}"
          }
        else
          response = 'NO'
          puts response
          client.puts response
        end

      when 'capture_flag'
        if server.flag_present && server.unique_flag_token == argument
          semaphore.synchronize {
            server.flag_present = false
            response = "FLAG: #{server.flag}"
          }
            puts response
            client.puts response
        else
          response = 'ERR: You\'re trying to trick me!'
          puts response
          client.puts response
        end
        close_connection = true

      when 'hide_flag'
        if foreign_connection
          puts "unhautorized command '#{method}' from #{remote_ip}."
        else
          EVENT_CAPTURE_FLAG.info argument
          semaphore.synchronize {
            server.unique_flag_token = server.flag_token
            begin
              server.flag_present = true
              puts 'flag saved!'
            rescue StandardError, RuntimeError => ex
              puts "flag not saved: #{ex}"
            end
          }
        end
        close_connection = true

      when 'generate_flag'
        semaphore.synchronize {
          server.unique_flag_token = server.flag_token
          begin
            server.flag_present = true
            puts 'flag saved!'
          rescue StandardError, RuntimeError => ex
            puts "flag not saved: #{ex}"
          end
        }
      end
    end
    client.close # Disconnect from the client
  end
}
