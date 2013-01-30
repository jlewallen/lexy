#!/usr/bin/env ruby

require 'net/https'
require 'open3'
require 'pty'

class StatusMonitor
  def initialize
    @pid = nil
  end

  def run
    refresh
    poll
  end

  def refresh
    IO.popen("/usr/bin/lxc-list") do |io|
      status = nil
      io.read.split("\n").each do |line|
        if line =~ /(RUNNING|FROZEN|STOPPED)/ then
	  status = $1
	else
          name = line.strip
          update(name, status)
	end
      end
    end
  end

  def stop
    if @running then
      @running = false
      Process.kill("SIGKILL", @pid) if @pid
    end
  end

 private
  def shutdown
      puts "\rExiting"
      stop
      exit 0
  end

  def poll
    Signal.trap("INT") {
      shutdown
    }
    Signal.trap("KILL") {
      shutdown
    }
    Signal.trap("TERM") {
      shutdown
    }
    @running = true
    while @running
      begin
        PTY.spawn("/usr/bin/lxc-monitor -n .+") do |i, o, pid|
          @pid = pid
          begin
            i.each do |line|
              DataMapper.logger << "Monitor: " + line
              if line =~ /'(.+)' changed state to \[(.+)\]/ then
                name = $1
                status = $2
                p [name, status]
                update(name, status)
              end
            end
          rescue Errno::EIO
          end
        end
      rescue PTY::ChildExited
        @pid = nil
      end
    end
  end

  def update(name, status)
    uri = URI.parse("http://127.0.0.1:3000/containers/#{name}/status/#{status}")
    DataMapper.logger << "UPDATE: " + uri.to_s
    http = Net::HTTP.new(uri.host, uri.port)
    # http.use_ssl = true
    # http.verify_mode = OpenSSL::SSL::VERIFY_NONE
    http.start do
      p http.post(uri.path, uri.query)
    end
  end
end

if __FILE__ == $0
  require "rubygems"
  require "bundler/setup"
  require 'dm-core'
  require 'dm-sqlite-adapter'
  require 'dm-migrations'
  require 'dm-validations'
  require 'dm-timestamps'
  require 'dm-types'
  require "active_support"

  DataMapper::Logger.new('/var/log/lexy-monitor.log', :debug)
  DataMapper.setup(:default, "sqlite://#{Dir.pwd}/my.db")

  require_relative "models/lexy"

  StatusMonitor.new.run
end
