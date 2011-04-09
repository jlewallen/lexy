class Startup
  include DataMapper::Resource
  default_scope(:default).update(:order => [ :name ])

  property :id,           Serial
  property :name,         String, :required => true, :length => 2..64, :unique => true
  property :description,  String, :length => 255
  property :script,       Text,   :required => true

  def self.import
    Startup.templates_directory.children.each do |e|
      next unless e.directory?
      startup = Startup.first(:name => e.basename)
      next unless startup.nil?
      next unless e.join("startup.sh").file?
      script = IO.read(e.join("startup.sh"))
      startup = Startup.new(name: e.basename, description: "", script: script)
      startup.save
    end
  end

  def read
    if startup_script_file.file?
      self.script = IO.read(startup_script_file)
      save
    end
  end

  def write
    path = template_directory
    path.mkpath
    File.open(startup_script_file, "w") do |f|
      f.write(script.gsub("\n\r", "\n").gsub("\015", ""))
    end
    startup_script_file.chmod(0755)
  end

  def self.templates_directory
    $lexy.join("templates")
  end

  def template_directory
    Startup.templates_directory.join(name)
  end

  def startup_script_file
    template_directory.join("startup.sh")
  end
end
