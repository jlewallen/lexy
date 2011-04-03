#!/usr/bin/env ruby

DataMapper::Logger.new(STDOUT, :debug)
DataMapper.setup(:default, "sqlite://#{Dir.pwd}/my.db")

require_relative "models/lexy"

DataMapper.finalize
DataMapper.auto_upgrade!

use Rack::MethodOverride

enable :sessions

helpers do
  include Rack::Utils
  alias_method :h, :escape_html
end

before do
  unless request.path_info =~ /\.\w+$/
    Stalker.enqueue('containers.refresh')
  end
end

get '/css/application.css' do
  less :css
end

get '/' do
  redirect '/containers'
end

get '/containers' do
  @containers = Container.all
  erb :containers
end

post '/containers/:name' do
  c = Container.get(params[:container][:id])
  c.attributes = params[:container]
  c.save
  redirect '/containers/' + params[:name]
end

post '/containers/:name/configure' do
  Stalker.enqueue('container.configure', :name => params[:name])
  redirect '/containers/' + params[:name] unless request.xhr?
end

post '/containers/:name/clean' do
  Stalker.enqueue('container.clean', :name => params[:name])
  redirect '/containers/' + params[:name] unless request.xhr?
end

post '/containers/:name/restart' do
  Stalker.enqueue('container.restart', :name => params[:name])
  redirect '/containers/' + params[:name] unless request.xhr?
end

post '/containers/:name/start' do
  Stalker.enqueue('container.start', :name => params[:name])
  redirect '/containers/' + params[:name] unless request.xhr?
end

post '/containers/:name/stop' do
  Stalker.enqueue('container.stop', :name => params[:name])
  redirect '/containers/' + params[:name] unless request.xhr?
end

delete '/containers/:name' do
  Stalker.enqueue('container.destroy', :name => params[:name])
  redirect '/containers'
end

get '/containers/new' do
  @container = Container.new
  erb :container_new
end

get '/containers/:name' do
  @container = Container.first(:name => params[:name])
  erb :container
end

post '/containers' do
  c = Container.new(params[:container])
  c.path = "/var/lib/lxc/" + c.name
  c.save
  redirect '/containers'
end

# EOF
