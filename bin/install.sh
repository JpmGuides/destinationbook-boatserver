# install required base package
apt-get install git nginx curl

# install rvm
gpg2 --keyserver hkp://keys.gnupg.net --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3
curl -L https://get.rvm.io | bash -s stable
source /etc/profile.d/rvm.sh
usermod -a -G rvm www-data
rvm install 2.5.1
rvm use --default 2.5.1

# install server
cd /var/www
mkdir destinationbook.com
cd destinationbook.com
git clone git@github.com:JpmGuides/destinationbook-boatserver.git .
cp config/settings.yaml.sample config/settings.yaml
bundle install

# make server start at boot time
sudo cp bin/db_puma.service /etc/systemd/system/db_puma.service
sudo systemctl enable db_puma.service
