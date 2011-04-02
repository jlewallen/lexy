#!/usr/bin/env ruby

require "rubygems"
require "bundler/setup"
require "sinatra"
require "sinatra/reloader" if development?
require "./web"

run Sinatra::Application
