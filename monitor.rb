#!/usr/bin/env ruby

require 'open3'
require 'pty'

class StatusMonitor
  def initialize
    @pid = nil
  end

  def run
    poll
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
              if line =~ /'(.+)' changed state to \[(.+)\]/ then
                name = $1
                state = $2
                p [name, state]
                if container = Container.first(:name => name) then
                  container.status = $2
                  container.save
                end
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
