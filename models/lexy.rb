#!/usr/bin/env ruby

require 'pathname'
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

class Configuration
  def initialize(path)
    @path = path
    @data = File.read(path)
  end
end

class FSTAB
  def initialize(path)
    @path = path
    @data = File.read(path)
  end

  def add(path)
  end
end

class LXC
  attr_reader :path

  def initialize(path)
    @path = path
    @configuration = read(path)
    @status = "UNKNOWN"
  end

  def status
    if exec("/usr/bin/lxc-info -n #{name}") =~ /is (\S+)$/ then
      $1
    else
      'UNKNOWN'
    end
  end

  def name
    @configuration['lxc.utsname'][0]
  end

  def running?
    /RUNNING/.match(exec("/usr/bin/lxc-info -n #{name}")) != nil
  end

  def stopped?
    !running?
  end

  def start
    exec("/usr/bin/screen -dm -S #{name} lxc-start -n #{name}")
  end

  def stop
    exec("/usr/bin/lxc-stop -n #{name}")
  end

 private
  def exec(command)
    p command
    `#{command}`
  end

  def read(path)
    map = Hash.new { |h, k| h[k] = [] }
    lines = File.readlines(path.join("config"))
    lines.map! { |l| l.gsub(/#.+/, "") }
    lines.reject! { |l| l.strip.empty? }
    lines.map! do |line|
      line.split('=').map { |v| v.strip }
    end
    lines.each do |k, v|
      map[k] << v
    end
    map
  end

  def write(map, path)
  end
end

class MAC
  def self.random
    (1..6).map{"%0.2X"%rand(256)}.join(":")
  end
end

class System
  def initialize(home)
    @home = home
  end

  def containers
    Pathname.new(@home).children.select { |e| e.directory?  }.map { |e| LXC.new(e) }
  end
end

if false
  system = System.new('/var/lib/lxc')
  system.containers.each do |c|
    unless c.running?
      c.start
    end
  end

  monitor = Monitor.new(nil)
  monitor.run
  sleep(10)
  monitor.stop
end

