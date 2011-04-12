cookbook_path [ 
                File.join(File.dirname(__FILE__), '..', "gitorious-cookbooks"),
                File.join(File.dirname(__FILE__), '..', "site-cookbooks")
              ]
log_level :debug
file_store_path File.join(File.dirname(__FILE__), '..')
file_cache_path File.join(File.dirname(__FILE__), '..')
Chef::Log::Formatter.show_time = false

