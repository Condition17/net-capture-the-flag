#!/usr/bin/ruby
require 'socket'
require 'yaml'
require 'timeout'

class String
  require 'resolv'
  def is_ip?
    self =~ Resolv::IPv4::Regex ? true : false
  end
end

def yaml_load(filename)
  YAML.load File.read filename
end

def next_server
  send_request = 'next_server'
  retrying = false
  begin
    begin
      srv = begin
          retrying = false
          Timeout::timeout(@max_timeout) {TCPSocket.open(@own_server, @port)}
        rescue StandardError, RuntimeError => ex
          retrying = true
          puts "Cannot connect to personal server. #{ex}. Retrying..."
          sleep @max_timeout
        end
    end while retrying == true
    print 'Asking personal server: \'next_srv\' -> '
    srv.puts(send_request)
    response = begin
        retrying = false
        Timeout::timeout(@max_timeout) {srv.gets}
      rescue StandardError, RuntimeError => ex
        retrying = true
        puts "No response from personal server. #{ex}. Retrying..."
        sleep @max_timeout
      end
    srv.close
  end while retrying == true
  puts response.chomp.to_s
  response.chomp.to_s
end

def send_hide_flag(foreign_flag_token)
  srv = begin
      Timeout::timeout(@max_timeout) {TCPSocket.open(@own_server, @port)}
    rescue StandardError, RuntimeError => ex
      raise "Error - flag not saved. #{ex}."
    end
  srv.puts("hide_flag #{foreign_flag_token}")
  srv.close
end

def server_response
  response = begin
      Timeout::timeout(@max_timeout) {@srv.gets}
    rescue StandardError, RuntimeError => ex
      puts "No response from server #{@next_srv}: #{ex}"
      @srv.close
      sleep 0.5
      @next_srv = next_server()
      return nil
    end
  response
end

config = yaml_load('./config.txt')
@port = config[:port]
@own_server = config[:server_address]
@max_timeout = 1.5

@next_srv = next_server()
loop do
  print "Asking #{@next_srv} 'who_are_you' -> "
  @srv = begin
          Timeout::timeout(@max_timeout) {TCPSocket.open(@next_srv, @port)}
        rescue StandardError, RuntimeError => ex
          puts "Cannot connect to host #{@next_srv}: #{ex}"
          sleep 0.5
          @next_srv = next_server()
          redo
        end

  @srv.puts('who_are_you?')
  next_srv_id = server_response()
  if next_srv_id
    puts next_srv_id
  else
    redo
  end

  print 'Have flag? -> '
  @srv.puts('have_flag?')
  flag_response = server_response()
  if flag_response
    puts flag_response
  else
    redo
  end

  if flag_response[0..1] == 'NO'
    print 'Next_srv(?) -> '
    @srv.puts('next_server')
    @next_srv = server_response()
    if @next_srv
      puts @next_srv
      if !@next_srv.is_ip? or @next_srv == @own_server
        puts "next server got from #{next_server} is bad. Asking own server now."
        sleep 0.5
        @next_srv = next_server()
        redo
      end
    else
      puts 'no response; asking own server'
      sleep 0.5
      @next_srv = next_server()
      redo
    end
  else
    foreign_flag_token = flag_response.split(' ').last
    puts "token: #{foreign_flag_token}"
    if foreign_flag_token.length < 3
      puts "#{@next_srv} returned a bad flag token. Retrying with personal server."
      @next_srv = next_server()
      redo
    end
    print "Capture_flag #{foreign_flag_token} -> "
    @srv.puts("capture_flag #{foreign_flag_token}")
    gimme_the_flag = server_response()
    if gimme_the_flag
      puts flag_response
      @srv.close
    else
      redo
    end

    if gimme_the_flag.include?('FLAG:')
      print 'Sending flag to personal server...'
      send_hide_flag(foreign_flag_token)
      puts "Done. Got it from #{next_srv_id}."
    end
    rest_time = rand(1..10)
    puts "Resting now for #{rest_time} seconds..."
    sleep rest_time
    @next_srv = next_server()
  end
end
