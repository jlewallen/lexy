default[:oracle][:user] = "oracle"
default[:oracle][:oinstall] = default[:oracle][:group] = "oinstall"
default[:oracle][:dba] = "dba"
default[:oracle][:password] = "asdfasdfA1"
default[:oracle][:hostname] = "oracle2"
default[:oracle][:zips] = [
  "/data/linux_11gR2_database_1of2.zip",
  "/data/linux_11gR2_database_2of2.zip"
]
default[:oracle][:homedir] = "/home/oracle"
default[:oracle][:directory] = "/u01/app/oracle"
default[:oracle][:base] = "/u01/app/oracle/11.2.0"
default[:oracle][:home] = "/u01/app/oracle/11.2.0/ora1"
default[:oracle][:sid] = "ora1"
