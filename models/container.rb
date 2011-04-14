class Container
  include DataMapper::Resource
  default_scope(:default).update(:order => [ :name ])

  property :id,         Serial
  property :name,       String, :required => true, :length => 3..64, :unique => true
  property :path,       String, :required => true, :length => 1..255
  property :address,    String, :required => true, :length => 5..32, :unique => true
  property :gw,         String, :required => true, :length => 5..32, :default => '192.168.0.1'
  property :bc,         String, :required => true, :length => 5..32, :default => '192.168.0.255'
  property :mask,       String, :required => true, :length => 5..32, :default => '255.255.255.0'
  property :status,     String, :required => true, :length => 32, :default => 'UNKNOWN'
  property :autorun,    Boolean, :required => true, :default => false
  belongs_to :key_pair
  belongs_to :startup
  has n, :fstab_entries
  has 1, :chef

  def key_pairs
    [ key_pair ].compact
  end

  def hostname
    name
  end

  def refresh
    self.status = lxc.status
    save
  end

  def running?
    'RUNNING' == status
  end

  def start
    lxc.start
  end

  def stop
    lxc.stop
  end

  def configure
    lxc.configure
  end

  def clean
    lxc.clean
  end

  def processes
    lxc.processes
  end

  def log
    lxc.log
  end

  def interfaces
    [OpenStruct.new({ name: "eth0", address: address, mask: mask, gateway: gw, bc: bc })]
  end

  def get_binding
    binding()
  end

  def update_status(status)
    self.status = status
    self.save
  end

  def private_key
    key_pairs.first.private
  end

  def ssh_to
    "root@" + address
  end

  def mountings
    all = fstab_entries.map do |e|
      { path: e.path, container_path: e.container_path }
    end
    all << {
      path: $lexy.join("data").join(name),
      container_path: "/data"
    }
    all << {
      path: $lexy.join("chef"),
      container_path: "/chef"
    }
    all << {
      path: $lexy.join("templates"),
      container_path: "/lexy"
    }
    all.map { |e| OpenStruct.new(e) }
  end

 private
  def lxc
    @lxc ||= LXC.new(self)
  end
end
