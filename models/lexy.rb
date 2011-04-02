#!/usr/bin/env ruby

$lexy = Pathname.new("/data/lexy")
$templates = $lexy.join("templates")

require 'rubygems'
require 'bundler/setup'
require 'active_record'
require 'pathname'
require 'ostruct'
require 'erb'
require_relative 'system'
require_relative 'lxc'
require_relative 'container'
require_relative 'template'

if __FILE__ == $0
  sys = System.new("/var/lib/lxc")
  c = sys.add("test2")
  c.network([
    name: 'eth0',
    address: '192.168.0.131',
    mask: '255.255.255.0',
    bc: '255.255.255.1',
    gw: '192.168.0.1'
  ])
end
