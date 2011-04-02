#!/usr/bin/env ruby

require 'open3'
require 'pty'

class Monitor
  def initialize(status)
    @status = status
    @thread = nil
    @pid = nil
  end

  def run
    poll
  end

  def stop
    if @running and @thread then
      @running = false
      Process.kill("SIGKILL", @pid) if @pid
      @thread.join
      @thread = nil
    end
  end

 private
  def poll
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

