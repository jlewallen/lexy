include JacobLewallen::Glassfish

action :create do
  server = Server.new(new_resource.port)
  unless server.clusters.has_key?(new_resource.name) then
    server.create_cluster(new_resource.name)
  end
end
