class Startup
  include DataMapper::Resource
  default_scope(:default).update(:order => [ :name ])

  property :id,           Serial
  property :name,         String, :required => true, :length => 2..64, :unique => true

  def self.import
    Startup.templates_directory.children.each do |e|
      next unless e.directory?
      startup = Startup.first(:name => e.basename)
      next unless startup.nil?
      next unless e.join("startup.sh").file?
      script = IO.read(e.join("startup.sh"))
      startup = Startup.new(name: e.basename, script: script)
      startup.save
    end
  end

  def script
    @script ||= read
  end

  def script=(value)
    @script = value
    write if id
    @script
  end

  def self.templates_directory
    $lexy.join("templates")
  end

  def template_directory
    Startup.templates_directory.join(name || "")
  end

  def startup_script_file
    template_directory.join("startup.sh")
  end

  def read
    if startup_script_file.file?
      p "Reading #{startup_script_file}"
      IO.read(startup_script_file)
    end
  end

  def write(data = script)
    path = template_directory
    path.mkpath
    File.open(startup_script_file, "w") do |f|
      f.write(data.gsub("\n\r", "\n").gsub("\015", ""))
    end
    p "Writing #{startup_script_file}"
    startup_script_file.chmod(0755)
  end
end
