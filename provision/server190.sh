wget https://dev.mysql.com/get/Downloads/MySQL-Cluster-7.6/mysql-cluster-community-management-server_7.6.6-1ubuntu18.04_amd64.deb

sudo dpkg -i mysql-cluster-community-management-server_7.6.6-1ubuntu18.04_amd64.deb

sudo mkdir /var/lib/mysql-cluster

sudo cp /vagrant/config/ndb-manager/config.ini /var/lib/mysql-cluster/config.ini

sudo ndb_mgmd -f /var/lib/mysql-cluster/config.ini

sudo pkill -f ndb_mgmd

sudo cp /vagrant/config/ndb-manager/ndb_mgmd.service /etc/systemd/system/ndb_mgmd.service

sudo systemctl daemon-reload

sudo systemctl enable ndb_mgmd

sudo systemctl start ndb_mgmd

sudo systemctl status ndb_mgmd

sudo ufw allow from 192.168.16.184
sudo ufw allow from 192.168.16.185
sudo ufw allow from 192.168.16.186
