#!/usr/bin/env ruby

require "rubygems"
require "bundler/setup"
require 'dm-core'
require 'dm-sqlite-adapter'
require 'dm-migrations'
require 'dm-validations'
require 'dm-timestamps'
require 'dm-types'
require "active_support"
require "erubis"
require "pathname"
require 'tempfile'
require "stalker"

DataMapper::Logger.new('/var/log/lexy-jobs.log', :debug)
DataMapper.setup(:default, "sqlite://#{Dir.pwd}/my.db")

require_relative "models/lexy"

include Stalker

Startup.import

job 'container.configure' do |args|
  args.symbolize_keys!
  container = Container.first(:name => args[:name])
  container.configure
end

job 'container.recycle' do |args|
  args.symbolize_keys!
  container = Container.first(:name => args[:name])
  container.stop
  container.clean
  container.configure
  container.start
end

job 'container.clean' do |args|
  args.symbolize_keys!
  Container.first(:name => args[:name]).clean
end

job 'container.destroy' do |args|
  args.symbolize_keys!
  Container.first(:name => args[:name]).destroy
end

job 'container.restart' do |args|
  args.symbolize_keys!
  container = Container.first(:name => args[:name])
  container.stop
  container.configure
  container.start
end

job 'container.start' do |args|
  args.symbolize_keys!
  container = Container.first(:name => args[:name])
  container.configure
  container.start
end

job 'container.stop' do |args|
  args.symbolize_keys!
  Container.first(:name => args[:name]).stop
end

job 'container.ssh' do |args|
  args.symbolize_keys!
  command = args[:command]
  container = Container.first(:name => args[:name])
  container.configure
  Tempfile.open(container.name, container.path) do |f|
    f.write(container.private_key)
    f.close
    command = "ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeychecking=no -o CheckHostIP=no -o LogLevel=ERROR -i #{f.path} #{container.ssh_to} \"#{command}\""
    puts command
    data = `#{command}`
    f.unlink
  end
end

job 'containers.refresh' do |args|
  Container.all.each do |c|
    c.refresh
  end
end

# EOF
