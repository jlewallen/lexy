class FileTemplate
  def initialize(name)
    @erb = ERB.new(IO.read($templates.join(name)))
  end

  def write(path, data)
    p "Writing #{path}..."
    File.open(path, "w") do |f|
      body = @erb.result(data)
      f.write(body)
    end
  end
end

class RootFS
  attr_reader :path

  def initialize(path)
    @path = path
  end

  def configure
    unless @path.directory?
      @path.mkpath
      template = "ubuntu-10.10.tar.gz"
      IO.popen("cd #{@path} && tar zxvf #{$lexy.join(template)}") do |io|
        io.each do |line|
          # p line
        end
      end
    end
  end
end

class LXC
  attr_reader :container
  attr_reader :path
  attr_reader :name

  def initialize(container)
    @container = container
    @path = Pathname.new(container.path)
    @name = container.name
  end

  def configure
    container.update_status("CONFIGURING")
    path.mkpath
    rootfs_path = path.join("rootfs")
    rfs = RootFS.new(rootfs_path)
    container.update_status("ROOTFS")
    rfs.configure
    container.fstab_entries.each do |e|
      path = Pathname.new(rootfs_path.to_s + e.container_path)
      path.mkpath
      p path.to_s
    end
    binding = @container.get_binding
    container.update_status("TEMPLATES")
    FileTemplate.new("config.tmpl").write(path.join("config"), binding)
    FileTemplate.new("fstab.tmpl").write(path.join("fstab"), binding)
    FileTemplate.new("hosts.tmpl").write(rfs.path.join("etc/hosts"), binding)
    FileTemplate.new("sshd_config.tmpl").write(rfs.path.join("etc/ssh/sshd_config"), binding)
    FileTemplate.new("interfaces.tmpl").write(rfs.path.join("etc/network/interfaces"), binding)
    FileTemplate.new("rc.local.tmpl").write(rfs.path.join("etc/rc.local"), binding)
    FileTemplate.new("rc.lexy.startup.tmpl").write(rfs.path.join("etc/rc.lexy.startup"), binding)
    FileTemplate.new("authorized_keys.tmpl").write(rfs.path.join("root/.ssh/authorized_keys"), binding)
    hostname = rfs.path.join("etc/hostname")
    File.open(hostname, "w") do |f|
      f.write(@container.hostname)
    end
    container.update_status("SSH-KEYGEN")
    key = rfs.path.join("etc/ssh/ssh_host_dsa_key")
    exec("ssh-keygen -t dsa -N '' -f #{key}") unless key.file?
    key = rfs.path.join("etc/ssh/ssh_host_rsa_key")
    exec("ssh-keygen -t rsa -N '' -f #{key}") unless key.file?
    container.refresh
  end

  def clean
    container.update_status("CLEAN")
    rootfs_path = path.join("rootfs")
    rootfs_path.rmtree if rootfs_path.directory?
    configure
  end

  def status
    if exec("/usr/bin/lxc-info -n #{name}") =~ /is (\S+)$/ then
      $1
    else
      'UNKNOWN'
    end
  end

  def running?
  end

  def start
    exec("/usr/bin/screen -dm -S #{name} lxc-start -n #{name}")
  end

  def stop
    exec("/usr/bin/lxc-stop -n #{name}")
  end

  def processes
    exec("/usr/bin/lxc-ps --name #{name} auxfww")
  end

  def log
    file = path.join("rootfs/var/log/syslog")
    exec("/usr/bin/tail -n 500 #{file}")
  end

 private
  def exec(command)
    p command
    `#{command}`
  end
end
