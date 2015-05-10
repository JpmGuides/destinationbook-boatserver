require 'yaml'
config = YAML::load(File.open('config/settings.yaml'))

# Set the environment in which the rack's app will run. The value must be a string.
# The default is “development”.

environment 'production'

# Daemonize the server into the background. Highly suggest that
# this be combined with “pidfile” and “stdout_redirect”.
# The default is “false”.

daemonize  config['server']['demonize']

# Store the pid of the server in the file at “path”.

pidfile 'tmp/puma/puma.pid'

# Use “path” as the file to store the server info state. This is
# used by “pumactl” to query and control the server.

state_path 'tmp/puma.state'

# Redirect STDOUT and STDERR to files specified. The 3rd parameter
# (“append”) specifies whether the output is appended, the default is
# “false”.

stdout_redirect 'log/server.log', 'log/server.log'

# Configure “min” to be the minimum number of threads to use to answer
# requests and “max” the maximum.
# The default is “0, 16”.

threads  config['server']['min_threads'], config['server']['max_threads']

# Bind the server to “url”. “tcp://”, “unix://” and “ssl://” are the only
# accepted protocols.
# The default is “tcp://0.0.0.0:9292”.

# bind 'tcp://0.0.0.0:9292'
# bind 'ssl://127.0.0.1:9292?key=path_to_key&cert=path_to_cert'

# Listens on port
config['server']['ports'].each do |to_listen|
  port to_listen
end

# Instead of “bind 'ssl://127.0.0.1:9292?key=path_to_key&cert=path_to_cert'” you
# can also use the “ssl_bind” option.

# ssl_bind '127.0.0.1', '9292', { key: path_to_key, cert: path_to_cert }

# === Cluster mode ===

# How many worker processes to run.
# The default is “0”.

workers config['server']['workers']
