## Deskripsi Singkat
### 1. Layered Architecture Design
### 2. Basis Data Terdistribusi MySQL Cluster
Basis data terdistribusi MySQL Cluster menyediakan ketersediaan dan throughput tinggi untuk sistem manajemen basis data MySQL. MySQL Cluster terdiri dari satu atau lebih node manajemen (`ndb_mgmd`) yang menyimpan konfigurasi cluster dan mengontrol data node (`ndbd`), tempat data cluster disimpan. Setelah berkomunikasi dengan node manajemen, klien (klien MySQL, server, atau API asli) terhubung langsung ke node data ini.
Dengan MySQL Cluster biasanya tidak ada replikasi data, tetapi sinkronisasi data node. Untuk tujuan ini, mesin data khusus harus digunakan - NDBCluster (NDB). Sangat membantu untuk menganggap cluster sebagai lingkungan MySQL logis tunggal dengan komponen yang berlebihan. Dengan demikian, MySQL Cluster dapat berpartisipasi dalam replikasi dengan MySQL Clusters lainnya.
MySQL Cluster bekerja paling baik di lingkungan shared-nothing. Idealnya, tidak ada dua komponen yang berbagi perangkat keras yang sama. Untuk tujuan kesederhanaan dan demonstrasi, kami akan membatasi diri untuk hanya menggunakan tiga server. Kami akan menyiapkan dua server sebagai simpul data yang menyinkronkan data di antara mereka. Server ketiga akan digunakan untuk Cluster Manager dan juga untuk server MySQL / klien. Jika ingin memutar server tambahan,  dapat ditambahkan lebih banyak data node ke cluster, memisahkan manajer cluster dari server MySQL / klien, dan mengkonfigurasi lebih banyak server sebagai Manajer Cluster dan server MySQL / klien.

## Implementasi Arsitektur Sistem Basis Data Terdistribusi
### 1. Spesifikasi Sistem
Arsitektur terdiri dari 8 server, masing-masing server memiliki spesifikasi sebagai berikut:
- 512 MB RAM
- Ubuntu 18.04

Pembagian IP server sebagai berikut:
- NDB Management server:
  - `192.168.16.190`
- NDB Data server:
  - `192.168.16.184`
  - `192.168.16.185`
  - `192.168.16.186`
- MySQL Server:
  - `192.168.16.187`
  - `192.168.16.188`
  - `192.168.16.189`
- ProxySQL:
  - `192.168.16.191`
### 2. Gambaran Sistem
### 3. Proses Konfigurasi dan Instalasi

#### 3.1. Install Dan Mengkonfigurasi Cluster Manager

- Pertama-tama akan dimulai dengan mengunduh dan menginstal MySQL Cluster Manager, `ndb_mgmd`.
- Login pada server `192.168.16.190` dan download file `.deb` berikut:
```bash
wget https://dev.mysql.com/get/Downloads/MySQL-Cluster-7.6/mysql-cluster-community-management-server_7.6.6-1ubuntu18.04_amd64.deb
```
- Install `ndb_mgmd` menggunakan dpkg:
```bash
sudo dpkg -i mysql-cluster-community-management-server_7.6.6-1ubuntu18.04_amd64.deb
```
- Kita sekarang perlu mengkonfigurasi `ndb_mgmd` sebelum menjalankannya; konfigurasi yang tepat akan memastikan sinkronisasi dan memuat distribusi yang benar di antara node data.
- Cluster Manager harus menjadi komponen pertama yang diluncurkan di setiap cluster MySQL. Ini membutuhkan file konfigurasi, diteruskan sebagai argumen untuk dieksekusi. Kami akan membuat dan menggunakan file konfigurasi berikut: `/var/lib/mysql-cluster/config.ini`.
- Pada cluster manager, buat `/var/lib/mysql-cluster` yang akan diisi:
```bash
sudo mkdir /var/lib/mysql-cluster
```
- Selanjutnya buat dan ubah file konfigurasi:
```bash
sudo nano /var/lib/mysql-cluster/config.ini
```
- Kemudian tempelkan:
```bash
[ndbd default]
# Options affecting ndbd processes on all data nodes:
NoOfReplicas=3  # Number of replicas

[ndb_mgmd]
# Management process options:
hostname=192.168.16.190 # Hostname of the manager
datadir=/var/lib/mysql-cluster  # Directory for the log files

[ndbd]
hostname=192.168.16.184 # Hostname/IP of the first data node
NodeId=2            # Node ID for this data node
datadir=/usr/local/mysql/data   # Remote directory for the data files

[ndbd]
hostname=192.168.16.185 # Hostname/IP of the second data node
NodeId=3            # Node ID for this data node
datadir=/usr/local/mysql/data   # Remote directory for the data files

[ndbd]
hostname=192.168.16.186 # Hostname/IP of the second data node
NodeId=4            # Node ID for this data node
datadir=/usr/local/mysql/data   # Remote directory for the data files

[mysqld]
# SQL node options:
hostname=192.168.16.187 # In our case the MySQL server/client is on the same Droplet as the cluster manager

[mysqld]
# SQL node options:
hostname=192.168.16.188 # In our case the MySQL server/client is on the same Droplet as the cluster manager

[mysqld]
# SQL node options:
hostname=192.168.16.189 # In our case the MySQL server/client is on the same Droplet as the cluster manager
```
- Setelah menempel di teks ini, pastikan untuk mengganti nilai `hostname` di atas dengan alamat IP yang benar dari IP yang telah Anda konfigurasikan. Mengatur parameter `hostname` ini adalah ukuran keamanan penting yang mencegah server lain dari terhubung ke Cluster Manager.
- Simpan file dan tutup editor teks Anda.
- Ini adalah file konfigurasi minimal yang diperkecil untuk MySQL Cluster. Anda harus menyesuaikan parameter dalam file ini tergantung pada kebutuhan produksi Anda. Untuk sampel, file konfigurasi `ndb_mgmd` yang sepenuhnya dikonfigurasi, bacalah dokumentasi MySQL Cluster.
- Dalam file di atas Anda dapat menambahkan komponen tambahan seperti data node (`ndbd`) atau server MySQL (`mysqld`) dengan menambahkan instance ke bagian yang sesuai.
- Kita sekarang dapat memulai manajer dengan mengeksekusi binary `ndb_mgmd` dan menentukan file konfigunya menggunakan flag `-f`:
```bash
sudo ndb_mgmd -f /var/lib/mysql-cluster/config.ini
```
- Dan seharusnya akan mengeluarkan output berikut:
![image](img/1.JPG)
```bash
MySQL Cluster Management Server mysql-5.7.22 ndb-7.6.6
2019-12-09 08:09:35 [MgmtSrvr] INFO     -- The default config directory '/usr/mysql-cluster' does not exist. Trying to create it...
2019-12-09 08:09:35 [MgmtSrvr] INFO     -- Sucessfully created config directory
```
- Ini menunjukkan bahwa server MySQL Cluster Management telah berhasil diinstal.
- Idealnya, setiap ingin memulai server Manajemen Cluster secara otomatis saat boot. Untuk melakukan ini, kami akan membuat dan mengaktifkan layanan systemd.
- Sebelum kita membuat layanan, kita perlu mematikan server yang berjalan:
```bash
sudo pkill -f ndb_mgmd
```
- Lalu buka dan ubah systemd unit file 
```bash
sudo nano /etc/systemd/system/ndb_mgmd.service
```
- Tempelkan potongan kode berikut:
```bash
[Unit]
Description=MySQL NDB Cluster Management Server
After=network.target auditd.service

[Service]
Type=forking
ExecStart=/usr/sbin/ndb_mgmd -f /var/lib/mysql-cluster/config.ini
ExecReload=/bin/kill -HUP $MAINPID
KillMode=process
Restart=on-failure

[Install]
WantedBy=multi-user.target
```
- Di sini, kita telah menambahkan sekumpulan opsi yang menginstruksikan `systemd` tentang cara memulai, menghentikan, dan memulai kembali proses `ndb_mgmd`. Untuk mempelajari lebih lanjut tentang opsi yang digunakan dalam konfigurasi unit ini, bacalah manual `systemd`.
- Simpan dan tutup file.
- Sekarang, muat ulang konfigurasi manajer `systemd` menggunakan `daemon-reload`:
```bash
sudo systemctl daemon-reload
```
- Kita akan mengaktifkan layanan yang baru saja kami buat sehingga MySQL Cluster Manager dimulai saat reboot:
```bash
sudo systemctl enable ndb_mgmd
```
- Eksekusi service tersebut:
```bash
sudo systemctl start ndb_mgmd
```
- Anda dapat memverifikasi bahwa layanan NDB Cluster Management sedang berjalan:
```bash
sudo systemctl status ndb_mgmd
```
Jika berhasil akan mengeluarkan output sebagai berikut:
![image](img/2.JPG)
```bash
● ndb_mgmd.service - MySQL NDB Cluster Management Server
   Loaded: loaded (/etc/systemd/system/ndb_mgmd.service; enabled; vendor preset: enabled)
   Active: active (running) since Mon 2019-12-09 08:13:03 UTC; 8s ago
  Process: 13244 ExecStart=/usr/sbin/ndb_mgmd -f /var/lib/mysql-cluster/config.ini (code=exited, status=0/SUCCESS)
 Main PID: 13253 (ndb_mgmd)
    Tasks: 11 (limit: 504)
   CGroup: /system.slice/ndb_mgmd.service
           └─13253 /usr/sbin/ndb_mgmd -f /var/lib/mysql-cluster/config.ini

Dec 09 08:13:03 server190 systemd[1]: Starting MySQL NDB Cluster Management Server...
Dec 09 08:13:03 server190 ndb_mgmd[13244]: MySQL Cluster Management Server mysql-5.7.22 ndb-7.6.6
Dec 09 08:13:03 server190 systemd[1]: Started MySQL NDB Cluster Management Server.
```
- Yang menunjukkan bahwa server MySQL Cluster Management `ndb_mgmd` sekarang berjalan sebagai layanan `systemd`.
- Langkah terakhir untuk mengatur Cluster Manager adalah mengizinkan koneksi masuk dari node MySQL Cluster lainnya di jaringan pribadi kami.
- Jika Anda tidak mengonfigurasi ufw firewall saat mengatur server ini, Anda dapat langsung beralih ke bagian selanjutnya.
- Kami akan menambahkan aturan untuk memungkinkan koneksi masuk lokal dari kedua node data:
```bash
sudo ufw allow from 192.168.16.184
sudo ufw allow from 192.168.16.185
sudo ufw allow from 192.168.16.186
```
- Setelah menjalankan perintah tersebut, seharusnya akan terlihat output sebagai berikut:
```bash
#Output
Rule added
```
- Cluster Manager sekarang seharusnya sudah aktif dan berjalan, dan dapat berkomunikasi dengan node Cluster lainnya melalui jaringan pribadi.
#### 3.2. Instalasi dan Konfigurasi Data Nodes

**Note: Semua perintah disini harus dijalankan disemua data nodes.**

- Sekarang, masuk ke node pertama Anda (dalam tutorial ini, 192.168.16.184), dan unduh file deb ini:
```bash
wget https://dev.mysql.com/get/Downloads/MySQL-Cluster-7.6/mysql-cluster-community-data-node_7.6.6-1ubuntu18.04_amd64.deb
```

- Sebelum menginstall data node binary, kita perlu menginstall `libclass-methodmaker-perl`

```bash
sudo apt update
sudo apt install libclass-methodmaker-perl
```
![image](img/3.JPG)
![image](img/4.JPG)
![image](img/5.JPG)

- Lalu install data node binary menggunakan `dpkg`:
```bash
sudo dpkg -i mysql-cluster-community-data-node_7.6.6-1ubuntu18.04_amd64.deb
```
![image](img/6.JPG)


- Node data menarik konfigurasinya dari lokasi standar MySQL, `/etc/my.cnf`. Buat file ini menggunakan editor teks favorit Anda dan mulai mengeditnya:

```bash
sudo nano /etc/my.cnf
```
- Tambahkan parameter konfigurasi berikut ke file:

```bash
[mysql_cluster]
# Options for NDB Cluster processes:
ndb-connectstring=192.168.16.190  # location of cluster manager
```

- Menentukan lokasi node Cluster Manager adalah satu-satunya konfigurasi yang diperlukan untuk memulai ndbd. Konfigurasi lainnya akan ditarik langsung dari manajer.

- Simpan dan keluar dari file.

- Dalam contoh kami, simpul data akan mengetahui bahwa direktori datanya adalah / usr / local / mysql / data, sesuai konfigurasi manajer. Sebelum memulai daemon, kami akan membuat direktori ini pada simpul:

```bash
sudo mkdir -p /usr/local/mysql/data
```

- Sekarang kita bisa memulai node menggunakan perintah dibawah ini:
```bash
sudo ndbd
```

- Seharusnya akan mengeluarkan berikut:
```bash 
2019-12-09 08:41:29 [ndbd] INFO     -- Angel connected to '192.168.16.190:1186'
2019-12-09 08:41:29 [ndbd] INFO     -- Angel allocated nodeid: 2
```
![image](img/7.JPG)
- Daemon node data NDB telah berhasil diinstal dan sekarang berjalan di server Anda.

- Kita juga perlu mengizinkan koneksi masuk dari node MySQL Cluster lainnya melalui jaringan pribadi.

- Jika Anda tidak mengonfigurasi firewall ufw saat mengatur server ini, Anda dapat langsung beralih ke menyiapkan layanan systemd untuk ndbd.

- Kami akan menambahkan aturan untuk mengizinkan koneksi masuk dari Cluster Manager dan node data lainnya:

```bash
sudo ufw allow from 192.168.16.185
sudo ufw allow from 192.168.16.186
```
![image](img/8.JPG)
- Server node data MySQL Anda sekarang dapat berkomunikasi dengan Cluster Manager dan simpul data lainnya melalui jaringan pribadi.

- Terakhir, kami juga ingin daemon simpul data dijalankan secara otomatis ketika server melakukan booting. Kami akan mengikuti prosedur yang sama dengan yang digunakan untuk Cluster Manager, dan membuat layanan systemd.

- Sebelum kami membuat layanan, kami akan mematikan proses ndbd yang sedang berjalan:

```bash
sudo pkill -f ndbd
```

- Buka dan edit systemd unit file
```bash
sudo nano /etc/systemd/system/ndbd.service
```
- Lalu tempelkan potongan kode berikut
```bash
[Unit]
Description=MySQL NDB Data Node Daemon
After=network.target auditd.service

[Service]
Type=forking
ExecStart=/usr/sbin/ndbd
ExecReload=/bin/kill -HUP $MAINPID
KillMode=process
Restart=on-failure

[Install]
WantedBy=multi-user.target
```

- Di sini, kami telah menambahkan sekumpulan opsi yang menginstruksikan systemd tentang cara memulai, menghentikan, dan memulai kembali proses ndbd. Untuk mempelajari lebih lanjut tentang opsi yang digunakan dalam konfigurasi unit ini, bacalah manual sistemd.

- Simpan dan tutup file.

- Sekarang, muat ulang konfigurasi manajer systemd menggunakan daemon-reload:

```bash
sudo systemctl daemon-reload
```
- Untuk mengaktifkan service yang baru kita buat sehingga dapat berjalan ketika reboot 
```bash
sudo systemctl enable ndbd
```
- Memulai service

```bash
sudo systemctl start ndbd
```

- Untuk memverifikasi apakah NDB Cluster Management berjalan

```bash
sudo systemctl status ndbd
```
- Seharusnya dapat mengeluarkan berikut
![image](img/9.JPG)

- Yang menunjukkan bahwa daemon node data MySQL Cluster ndbd sekarang berjalan sebagai layanan systemd. Node data Anda sekarang harus berfungsi penuh dan dapat terhubung ke MySQL Cluster Manager.

#### 3.3. Mengkonfigurasi Dan Memulai MySQL Server dan Client

- Server MySQL standar, seperti yang tersedia di repositori APT Ubuntu, tidak mendukung mesin MySQL Cluster NDB. Ini berarti kita perlu menginstal server SQL khusus yang dikemas dengan perangkat lunak MySQL Cluster lain yang telah kita instal dalam tutorial ini.
- Login di setiap server mysql yaitu di `192.168.187`, `192.168.16.188`, `192.168.16.189` dan lakukan langkah berikut
Download MySQL Cluster
```bash
wget https://dev.mysql.com/get/Downloads/MySQL-Cluster-7.6/mysql-cluster_7.6.6-1ubuntu18.04_amd64.deb-bundle.tar
```
Extract file tersebut kedalam file install
```bash
mkdir install
tar -xvf mysql-cluster_7.6.6-1ubuntu18.04_amd64.deb-bundle.tar -C install/
cd install
sudo apt update
sudo apt install libaio1 libmecab2
sudo dpkg -i mysql-common_7.6.6-1ubuntu18.04_amd64.deb
sudo dpkg -i mysql-cluster-community-client_7.6.6-1ubuntu18.04_amd64.deb
sudo dpkg -i mysql-client_7.6.6-1ubuntu18.04_amd64.deb
sudo dpkg -i mysql-cluster-community-server_7.6.6-1ubuntu18.04_amd64.deb
```
- Kemudian aakan diminta password untuk akses admin. Simpan ini.
```bash
sudo dpkg -i mysql-server_7.6.6-1ubuntu18.04_amd64.deb
```
```bash
sudo nano /etc/mysql/my.cnf
```
- Masukkan file konfigurasi berikut kedalam my.cnf
```bash
# Copyright (c) 2015, 2016, Oracle and/or its affiliates. All rights reserved.
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; version 2 of the License.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301 USA

#
# The MySQL Cluster Community Server configuration file.
#
# For explanations see
# http://dev.mysql.com/doc/mysql/en/server-system-variables.html

# * IMPORTANT: Additional settings that can override those from this file!
#   The files must end with '.cnf', otherwise they'll be ignored.
#
!includedir /etc/mysql/conf.d/
!includedir /etc/mysql/mysql.conf.d/

[mysqld]
# Options for mysqld process:
ndbcluster                      # run NDB storage engine

[mysql_cluster]
# Options for NDB Cluster processes:
ndb-connectstring=192.168.16.190 # location of management server
```
- Restart service
```bash
sudo systemctl restart mysql
```
- Kemudian aktifkan kembali mysql
```bash
sudo systemctl enable mysql
```

#### 3.4. Memverifikasi Instalasi MySQL

- Akses kedalam mysql dengan cara
```bash
mysql -u root -p 
```
- Jika berhasil akan melihat layar sebagai berikut:
![gambar](img/11.JPG)

Didalam MySQL Client jalankan:
```sql
SHOW ENGINE NDB STATUS \G
```
![gambar](img/12.JPG)
Untuk memastikan bahwa semua server terhubung ke server manager
```
ndb_mgm
```
- Jika berhasil akan mengeluarkan output sebagai berikut
![gambar](img/10.JPG)

#### 3.4. Memasukkan Data Kedalam Database

- Disini kami menggunakan MySQL Workbench untuk memasukkan data kedalam server MySQL dengan konfigurasi berikut
![gambr](img/13.JPG)

- Telah dimasukkan seluruh data, dan berikut hasilnya. Di kedua server.
![gambar](img/15.JPG)

### Monitoring Grafana
- Untuk melakukan monitoring grafana perlu dilakukan instalasi terhadap MySQL Exporter, Prometheus dan Grafana itu sendiri. Berikut instalasinya
- Membuat service user
```bash
sudo useradd --no-create-home --shell /bin/false prometheus
sudo useradd --no-create-home --shell /bin/false node_exporter
```

```bash
sudo mkdir /etc/prometheus
sudo mkdir /var/lib/prometheus
```
- Set user dan group ownership ke direktory baru ke prometheus user
```bash
sudo chown prometheus:prometheus /etc/prometheus
sudo chown prometheus:prometheus /var/lib/prometheus
```
- Download prometheus
```bash
cd ~
curl -LO https://github.com/prometheus/prometheus/releases/download/v2.0.0/prometheus-2.0.0.linux-amd64.tar.gz
```
- Unpack hasil download
```bash
tar xvf prometheus-2.0.0.linux-amd64.tar.gz
```
- Copy dua binaries tersebut
```bash
sudo cp prometheus-2.0.0.linux-amd64/prometheus /usr/local/bin/
sudo cp prometheus-2.0.0.linux-amd64/promtool /usr/local/bin/
```
- Set user dan group ownership
```bash
sudo chown prometheus:prometheus /usr/local/bin/prometheus
sudo chown prometheus:prometheus /usr/local/bin/promtool
```
- Copy files
```bash
sudo cp -r prometheus-2.0.0.linux-amd64/consoles /etc/prometheus
sudo cp -r prometheus-2.0.0.linux-amd64/console_libraries /etc/prometheus
```
- Set user dan group ownership pada folder
```bash
sudo chown -R prometheus:prometheus /etc/prometheus/consoles
sudo chown -R prometheus:prometheus /etc/prometheus/console_libraries
```
- Konfigurasi prometheus
```bash
sudo nano /etc/prometheus/prometheus.yml
```
```yaml
global:
  scrape_interval: 15s

scrape_configs:
  - job_name: 'prometheus'
    scrape_interval: 5s
    static_configs:
      - targets: ['localhost:9090']
```
![img](img/16.JPG)

- Jalankan prometheus
```
sudo -u prometheus /usr/local/bin/prometheus \
    --config.file /etc/prometheus/prometheus.yml \
    --storage.tsdb.path /var/lib/prometheus/ \
    --web.console.templates=/etc/prometheus/consoles \
    --web.console.libraries=/etc/prometheus/console_libraries
```
![img](img/17.JPG)
 
#### Install MySQL Exporter

- Download MySQL Exporter
```bash
wget https://github.com/prometheus/mysqld_exporter/releases/download/v0.11.0/mysqld_exporter-0.11.0.linux-amd64.tar.gz
```
- Extract file tersebut
```bash
tar xvzf mysqld_exporter-0.11.0.linux-amd64.tar.gz
```
- Pindahkan ke 
```bash
cd mysqld_exporter-0.11.0.linux-amd64/
sudo mv mysqld_exporter /usr/local/bin/
```
- Buat user baru di MySQL
```bash
sudo mysql
CREATE USER 'exporter'@'localhost' IDENTIFIED BY 'password' WITH MAX_USER_CONNECTIONS 3;
GRANT PROCESS, REPLICATION CLIENT, SELECT ON *.* TO 'exporter'@'localhost';
```

- Buat MySQL Exporter Service di
![img](img/18.JPG)
- Restart daemon dan memulai service
![img](img/19.JPG)



