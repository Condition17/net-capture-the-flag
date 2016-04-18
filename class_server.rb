#!/usr/bin/ruby

require 'logger'
require 'socket'

class Server<TCPServer
  attr_accessor :port, :id, :flag, :flag_present, :unique_flag_token

  def initialize(attributes={})
    @flag = 'SJDHGG898mIhAI'
    @id = generate_id(attributes[:author])
    @unique_flag_token = flag_token
    @hosts = attributes[:hosts]
    @port = attributes[:port]
    if !(1..65535).include?(@port)
      raise 'SERVER PORT OUT OF RANGE'
    end

    if attributes[:flag_present]
      @flag_present = attributes[:flag_present]
    else
      @flag_present = false
    end
    super (@port)
  end

  def who_are_you?
    @id
  end

  def next_server(foreign_host = nil)
    # get local ip address
    local_ip = Socket.ip_address_list.find { |ai| ai.ipv4? && !ai.ipv4_loopback? }.ip_address
    hosts = @hosts.shuffle
    hosts.each do |host|
      if local_ip.to_s != host and foreign_host != host
        return host
      end
    end
  end

  def flag_token
    (('a'..'z').to_a+('0'..'9').to_a).shuffle[0..16].join
  end

  def method_missing(*args)
    "ERR: Illegal request."
  end

  private

  def generate_id(author_name)
    id = author_name.chr.downcase
    id += author_name.split.last.downcase
    id += '.' + (('0'..'9').to_a+('a'..'z').to_a).shuffle[0..14].join
    id[0, 16]
  end
end
