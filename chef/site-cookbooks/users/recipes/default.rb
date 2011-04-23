node[:users].each do |user|
  unless user[:created]
    group user[:group]
    user user[:name] do
      gid user[:group]
      home user[:home]
      shell "/bin/bash"
    end
  end

  if user[:ssh] then
    private_key = ::File.join(user[:home], ".ssh", "id_rsa")
    execute "ssh-key-#{user[:name]}" do
      command "ssh-keygen -N '' -t rsa -f #{private_key}"
      creates private_key
      user user[:name]
      action :run
    end
  end

  keys = user[:keys] || []
  if keys.any? then
    authorized = keys.join("\n")
    authorized_keys = ::File.join(user[:home], ".ssh", "authorized_keys")
    file authorized_keys do
      owner user[:name]
      group user[:group]
      content authorized
    end
  end
end

