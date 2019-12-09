wget https://dev.mysql.com/get/Downloads/MySQL-Cluster-7.6/mysql-cluster-community-data-node_7.6.6-1ubuntu18.04_amd64.deb

sudo apt update
sudo apt install libclass-methodmaker-perl

sudo dpkg -i mysql-cluster-community-data-node_7.6.6-1ubuntu18.04_amd64.deb

sudo cp /vagrant/config/datanode/my.cnf /etc/my.cnf

sudo mkdir -p /usr/local/mysql/data

sudo ndbd

sudo ufw allow from 192.168.16.184
sudo ufw allow from 192.168.16.185
sudo ufw allow from 192.168.16.186

sudo pkill -f ndbd

sudo cp /vagrant/config/datanode/ndbd.service /etc/systemd/system/ndbd.service

sudo systemctl daemon-reload

sudo systemctl enable ndbd

sudo systemctl start ndbd

sudo systemctl status ndbd
