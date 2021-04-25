#!/bin/bash

echo "================Flushing IPTABLES================="
sleep 2
iptables -F
sleep 2

echo "================disabling selinux================="
sleep 2
sed -i 's/SELINUX=enforcing/SELINUX=disabled/' /etc/selinux/config
setenforce  0
sleep 2

echo "====installing the must-have pre-requisites===="
sleep 2
echo "============================================================"
while read -r p ; do sudo yum install -y $p ; done < <(cat << "EOF"
    epel-release
    libicu*
    gcc
    jemalloc*
    nginx
    haproxy
    postgresql-devel
EOF
)
sleep 2

echo "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
echo installing local packages
sleep 5
echo "=========================================================="
while read -r s ; do sudo yum localinstall -y $s ; done < <(cat << "EOF"
    redis-4.0-2.x86_64.rpm
    rabbitmq-server-3.2.3-1.noarch.rpm
EOF
)
sleep 2

echo "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
echo installing rpm packages
sleep 5
echo "=========================================================="
for a in `cat rpm.txt | tr ',' '\n'`; do rpm -ivh $a ; done

sleep 2
echo " =================starting POSTGRESQL-11========================= "
/usr/pgsql-11/bin/postgresql-11-setup initdb
sleep 5

echo "==========extracting python package====================="
sleep 2
tar xvzf python3.6_optimized.tar.gz

sleep 2

echo "============= adding user utarde =============="
useradd utrade
mkdir -p "/home/utrade/utradeENV"

sleep 5

echo "======setting user permission============"
usermod -aG wheel utrade
sleep 5

echo "==========setting env for user=============="
/root/python3.6_optimized/bin/./virtualenv /home/utrade/utradeENV/

sleep 5

echo " +++++++++++ taking backup of pg_hba.conf++++++++++++++++++ "
cp -r /var/lib/pgsql/11/data/pg_hba.conf /var/lib/pgsql/11/data/pg_hba_bkp
sleep 2

echo "++++++++++++++changing config++++++++++++++ "
sleep 2
sed -i '/# TYPE  DATABASE        USER            ADDRESS                 METHOD/i \
local   all             postgres                                ident\
local   all             all                                     md5\
' /var/lib/pgsql/11/data/pg_hba.conf

sleep 2
sleep 2

sed -i 's/local   all             all                                     peer/local   all             all                                     md5/' /var/lib/pgsql/11/data/pg_hba.conf

sed -i 's/host    all             all             127.0.0.1/32            ident/host    all             all             127.0.0.1/32            md5/' /var/lib/pgsql/11/data/pg_hba.conf

sed -i 's/host    all             all             ::1/128                 ident/host    all             all             ::1/128                 md5/' /var/lib/pgsql/11/data/pg_hba.conf




echo "================ Starting Services ==================="

sleep 5
while read -r b ; do service $b start ; done < <(cat << "EOF"
    redis
    rabbitmq-server start
    haproxy
    nginx
    postgresql-11
EOF
)

sleep 2
echo "================= enabling services =============="
sleep 2
while read -r c ; do chkconfig $c on ; done < <(cat << "EOF"
    redis
    rabbitmq-server
    haproxy
    nginx
    postgresql-11
EOF
)













