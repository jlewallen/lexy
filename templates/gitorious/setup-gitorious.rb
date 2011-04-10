#!/usr/bin/env ruby
require File.dirname(__FILE__) + '/../config/environment'
ActionMailer::Base.raise_delivery_errors = false
ActionMailer::Base.delivery_method = :test

if User.find_by_is_admin(true)
  puts "You already have an Administrator"
  exit!
end

email = 'jlewalle@gmail.com'
password = "asdfasdf"
user = User.new :password => password, :password_confirmation => password, :email => email, :terms_of_use => '1'
user.login = 'jlewallen'
user.is_admin = true
if user.save
  user.activate
  puts "Admin user created successfully."
else
  puts "Failed creating Admin user."
end
