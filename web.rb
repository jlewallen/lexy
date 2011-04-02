#!/usr/bin/env ruby

DataMapper::Logger.new(STDOUT, :debug)
DataMapper.setup(:default, "sqlite://#{Dir.pwd}/my.db")

require_relative "models/lexy"

DataMapper.finalize
DataMapper.auto_upgrade!

use Rack::MethodOverride

enable :sessions

get '/css/application.css' do
  less :css
end

get '/' do
  redirect '/containers'
end

get '/containers' do
  @containers = Container.all
  @containers.each { |c| c.refresh }
  erb :containers
end

post '/containers/:name' do
  c = Container.get(params[:container][:id])
  c.attributes = params[:container]
  c.save
  redirect '/containers/' + params[:name]
end

post '/containers/:name/configure' do
  Container.first(:name => params[:name]).configure
  redirect '/containers/' + params[:name]
end

post '/containers/:name/start' do
  Container.first(:name => params[:name]).start
  redirect '/containers/' + params[:name]
end

post '/containers/:name/stop' do
  Container.first(:name => params[:name]).stop
  redirect '/containers/' + params[:name]
end

get '/containers/new' do
  @container = Container.new
  erb :container_new
end

get '/containers/:name' do
  @container = Container.first(:name => params[:name])
  @container.refresh
  erb :container
end

post '/containers' do
  c = Container.new(params[:container])
  c.path = "/var/lib/lxc/" + c.name
  c.save
  redirect '/containers'
end

delete '/containers/:name' do
  c = Container.first(:name => params[:name])
  c.destroy!
  redirect '/containers'
end

# EOF
