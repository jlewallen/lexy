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

  def selection(name, options, selected)
    "<SELECT NAME='#{name}'>" + "<OPTION VALUE=''>Choose one...</OPTION>" +
    options.map do |p|
      if p == selected then
        "<OPTION VALUE='#{p.id}' SELECTED>#{p.name}</OPTION>"
      else
        "<OPTION VALUE='#{p.id}'>#{p.name}</OPTION>"
      end
    end.join("") + "</SELECT>"
  end
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
  @startups = Startup.all
  @key_pairs = KeyPair.all
  @resource = Container.new
  erb :container_form
end

get '/containers/:name' do
  @startups = Startup.all
  @key_pairs = KeyPair.all
  @container = Container.first(:name => params[:name])
  erb :container
end

post '/containers' do
  c = Container.new(params[:container])
  c.path = "/var/lib/lxc/" + c.name
  c.save
  redirect '/containers'
end

get '/keys' do
  @collection = KeyPair.all
  erb :keys
end

get '/keys/new' do
  @resource = KeyPair.new
  erb :key_form
end

post '/keys' do
  @resource = KeyPair.new(params[:key])
  @resource.save
  p @resource.errors
  redirect '/keys'
end

post '/keys/:id' do
  @resource = KeyPair.get(params[:id])
  @resource.attributes = params[:key]
  @resource.save
  redirect '/keys'
end

get '/keys/:id' do
  @resource = KeyPair.get(params[:id])
  erb :key_form
end

delete '/keys/:id' do
  KeyPair.get(params[:id]).destroy
  redirect '/keys'
end

get '/startups' do
  @collection = Startup.all
  erb :startups
end

get '/startups/new' do
  @resource = Startup.new
  erb :startup_form
end

post '/startups' do
  @resource = Startup.new(params[:startup])
  @resource.save
  redirect '/startups'
end

get '/startups/:id' do
  @resource = Startup.get(params[:id])
  erb :startup_form
end

post '/startups/:id' do
  @resource = Startup.get(params[:id])
  @resource.attributes = params[:startup]
  @resource.save
  redirect '/startups'
end

delete '/startups/:id' do
  Startup.get(params[:id]).destroy
  redirect '/startups'
end

post '/fstab/new' do
  attrs = params[:fstab]
  @resource = FstabEntry.new(attrs)
  @resource.save
  redirect '/containers/' + @resource.container.name unless request.xhr?
end

delete '/fstab/:id' do
  @resource = FstabEntry.get(params[:id])
  @resource.destroy
  redirect '/containers/' + @resource.container.name unless request.xhr?
end

# EOF
