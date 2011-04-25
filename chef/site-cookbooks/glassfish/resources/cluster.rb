actions :create

attribute :name,        :kind_of => String
attribute :port,        :kind_of => Integer, :default => 7048

def initialize(*args)
  super
  @action = :create
end
