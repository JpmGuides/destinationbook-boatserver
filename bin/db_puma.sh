#!/bin/bash

### BEGIN INIT INFO
# Provides:          puma
# Required-Start:    $remote_fs $syslog
# Required-Stop:     $remote_fs $syslog
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: Start destinationbook puma at boot time
# Description:       Enable destinationbook started with puma.
### END INIT INFO

start() {
  echo "Starting up DB..."
  source /etc/profile.d/rvm.sh

  cd /var/www/destinationbook.com
  git pull
  bundle install
  bundle exec puma -C config/puma.rb

  echo "DB started"
}

stop() {
  echo "Stoping DB"
  source /etc/profile.d/rvm.sh

  pumactl -P /var/www/destinationbook.com/tmp/puma.pid stop
  rm /var/www/destinationbook.com/tmp/puma.pid
}

restart() {
  echo "Restarting DB"
  source /etc/profile.d/rvm.sh

  pumactl -P /var/www/destinationbook.com/tmp/puma.pid restart
}

case "$1" in
  start)
        start
        ;;
  stop)
        stop
        ;;
  restart)
        restart
        ;;
  *)
        echo $"Usage: $0 {start|stop|restart}"
        exit 1
esac
exit 0
