actions :create

attribute :name,        :kind_of => String
attribute :base_port,   :kind_of => Integer, :default => 7000

def initialize(*args)
  super
  @action = :create
end
