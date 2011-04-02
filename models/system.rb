class MAC
  def self.random
    (1..6).map{"%0.2X"%rand(256)}.join(":")
  end
end

class System
  def initialize(home)
    @home = Pathname.new(home)
  end

  def containers
    @home.children.select { |e| e.directory?  }.map { |e| LXC.open(e) }
  end

  def container(name)
    LXC.open(@home.join(name))
  end

  def add(name)
    LXC.create(@home.join(name), name)
  end
end
