#!/usr/bin/env ruby

require "rubygems"
require "bundler/setup"
require "sinatra"
require 'dm-core'
require 'dm-sqlite-adapter'
require 'dm-migrations'
require 'dm-validations'
require 'dm-timestamps'
require 'dm-types'
require "active_support"
require "erubis"
require "tilt"
require "pathname"

configure(:development) do |c|
  require "sinatra/reloader"
  c.also_reload "web.rb"
  c.also_reload "models/*.rb"
end

require "./web.rb"

run Sinatra::Application
