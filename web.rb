#!/usr/bin/env ruby

require "rubygems"
require "bundler/setup"
require "erubis"
require "tilt"
require "pathname"
require "active_support"
require "active_support/json"
require_relative "models/lexy"

enable :sessions

system = System.new('/var/lib/lxc')

get '/' do
  erb :index
end

get '/containers' do
  @containers = system.containers
  erb :containers
end

post '/containers/{}/start' do
end

post '/containers/{}/stop' do
end

# EOF
