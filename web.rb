#!/usr/bin/env ruby

DataMapper::Logger.new(STDOUT, :debug)
DataMapper.setup(:default, "sqlite://#{Dir.pwd}/my.db")

require_relative "models/lexy"

DataMapper.finalize
DataMapper.auto_upgrade!

use Rack::MethodOverride
use Rack::Flash

enable :sessions

def errors_message(e)
  if e.errors.any?
    e.errors.map { |v| v }.flatten.join(" ")
  else
    nil
  end
end

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

get '/css/application.css' do
  less :css
end

get '/' do
  Stalker.enqueue('containers.refresh')
  redirect '/containers'
end

get '/containers' do
  @containers = Container.all
  erb :containers
end

post '/containers/configure' do
  Container.all.each do |c|
    Stalker.enqueue('container.configure', :name => c.name)
  end
  flash[:notice] = "All containers configured."
  redirect '/containers'
end

post '/containers/:name' do
  c = Container.get(params[:container][:id])
  c.attributes = params[:container]
  if c.save then
    flash[:notice] = "Container saved."
  else
    flash[:error] = errors_message(c)
  end
  redirect '/containers/' + params[:name]
end

post '/containers/:name/startup/run' do
  Stalker.enqueue('container.ssh', :name => params[:name], :command => "/usr/bin/nohup /bin/bash /etc/rc.local --force < /dev/null 2>&1 | logger -t lexy &")
  flash[:notice] = "Ran startup for " + params[:name]
  redirect '/containers/' + params[:name] unless request.xhr?
end

post '/containers/:name/chef/run' do
  Stalker.enqueue('container.ssh', :name => params[:name], :command => "/usr/bin/nohup /usr/bin/lexy-chef cook:lexy < /dev/null 2>&1 | logger -t lexy &")
  flash[:notice] = "Ran chef for " + params[:name]
  redirect '/containers/' + params[:name] unless request.xhr?
end

post '/containers/:name/configure' do
  Stalker.enqueue('container.configure', :name => params[:name])
  flash[:notice] = "Configured " + params[:name]
  redirect '/containers/' + params[:name] unless request.xhr?
end

post '/containers/:name/clean' do
  Stalker.enqueue('container.clean', :name => params[:name])
  flash[:notice] = "Cleaned " + params[:name]
  redirect '/containers/' + params[:name] unless request.xhr?
end

post '/containers/:name/restart' do
  Stalker.enqueue('container.restart', :name => params[:name])
  flash[:notice] = "Restarting " + params[:name]
  redirect '/containers/' + params[:name] unless request.xhr?
end

post '/containers/:name/start' do
  Stalker.enqueue('container.start', :name => params[:name])
  flash[:notice] = "Starting " + params[:name]
  redirect '/containers/' + params[:name] unless request.xhr?
end

post '/containers/:name/recycle' do
  Stalker.enqueue('container.recycle', :name => params[:name])
  flash[:notice] = "Recyling " + params[:name]
  redirect '/containers/' + params[:name] unless request.xhr?
end

post '/containers/:name/stop' do
  Stalker.enqueue('container.stop', :name => params[:name])
  flash[:notice] = "Stopping " + params[:name]
  redirect '/containers/' + params[:name] unless request.xhr?
end

delete '/containers/:name' do
  @container = Container.first(:name => params[:name])
  @container.destroy
  Stalker.enqueue('container.destroy', :name => @container.name, :path => @container.path)
  flash[:notice] = "Deleted " + params[:name]
  redirect '/containers'
end

get '/containers/:name/chef.json' do
  @container = Container.first(:name => params[:name])
  (@container.chef || {}).to_json
end

post '/containers/:name/status/:status' do
  @container = Container.first(:name => params[:name])
  @container.status = params[:status]
  @container.save
  redirect '/containers/' + @container.name unless request.xhr?
end

post '/containers/:name/chef' do
  @container = Container.first(:name => params[:name])
  @container.chef ||= Chef.new(:container => @container)
  @container.chef.attributes = params[:chef]
  @container.chef.save
  flash[:notice] = "Chef data saved."
  redirect '/containers/' + @container.name unless request.xhr?
end

get '/containers/new' do
  @startups = Startup.all
  @key_pairs = KeyPair.all
  @resource = Container.new
  erb :container_form
end

get '/containers/:name/log' do
  @container = Container.first(:name => params[:name])
  raise Sinatra::NotFound unless @container
  erb :log, :layout => !request.xhr?
end

get '/containers/:name/processes' do
  @container = Container.first(:name => params[:name])
  raise Sinatra::NotFound unless @container
  erb :processes, :layout => !request.xhr?
end

get '/containers/:name' do
  @startups = Startup.all
  @key_pairs = KeyPair.all
  @container = Container.first(:name => params[:name])
  raise Sinatra::NotFound unless @container
  erb :container
end

post '/containers' do
  c = Container.new(params[:container])
  c.path = "/var/lib/lxc/" + c.name
  c.save
  if c.save then
    flash[:notice] = "Container saved."
  else
    flash[:error] = errors_message(c)
  end
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
  flash[:notice] = "Key pair created."
  redirect '/keys'
end

post '/keys/:id' do
  @resource = KeyPair.get(params[:id])
  @resource.attributes = params[:key]
  @resource.save
  flash[:notice] = "Key pair saved."
  redirect '/keys'
end

get '/keys/:id' do
  @resource = KeyPair.get(params[:id])
  erb :key_form
end

delete '/keys/:id' do
  KeyPair.get(params[:id]).destroy
  flash[:notice] = "Key pair deleted."
  redirect '/keys'
end

get '/startups' do
  @collection = Startup.all
  erb :startups
end

get '/startups/new' do
  @resource = Startup.new
  @resource.script =<<EOS
set -e -x

apt-get -q -y install git-core vim
EOS
  erb :startup_form
end

post '/startups' do
  @resource = Startup.new(params[:startup])
  @resource.save
  @resource.write
  flash[:notice] = "Startup created."
  redirect '/startups/' + @resource.id
end

get '/startups/:id' do
  @resource = Startup.get(params[:id])
  @resource.read
  erb :startup_form
end

post '/startups/:id' do
  @resource = Startup.get(params[:id])
  @resource.attributes = params[:startup]
  @resource.save
  @resource.write
  flash[:notice] = "Startup saved."
  redirect '/startups/' + params[:id]
end

delete '/startups/:id' do
  Startup.get(params[:id]).destroy
  flash[:notice] = "Startup deleted."
  redirect '/startups'
end

post '/fstab/new' do
  attrs = params[:fstab]
  @resource = FstabEntry.new(attrs)
  @resource.save
  flash[:notice] = "Mount added."
  redirect '/containers/' + @resource.container.name unless request.xhr?
end

delete '/fstab/:id' do
  @resource = FstabEntry.get(params[:id])
  @resource.destroy
  flash[:notice] = "Mount deleted."
  redirect '/containers/' + @resource.container.name unless request.xhr?
end

# EOF
