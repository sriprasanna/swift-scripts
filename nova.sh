#!/usr/bin/env bash
DIR=`pwd`
CMD=$1
SOURCE_BRANCH=lp:nova
if [ -n "$2" ]; then
    SOURCE_BRANCH=$2
fi
DIRNAME=nova
NOVA_DIR=$DIR/$DIRNAME
if [ -n "$3" ]; then
    NOVA_DIR=$DIR/$3
fi

if [ ! -n "$HOST_IP" ]; then
    # NOTE(vish): This will just get the first ip in the list, so if you
    #             have more than one eth device set up, this will fail, and
    #             you should explicitly set HOST_IP in your environment
    HOST_IP=`ifconfig  | grep -m 1 'inet addr:'| cut -d: -f2 | awk '{print $1}'`
fi
TEST=0
USE_MYSQL=1
MYSQL_PASS=nova
USE_LDAP=0
LIBVIRT_TYPE=qemu

if [ "$USE_MYSQL" == 1 ]; then
    SQL_CONN=mysql://root:$MYSQL_PASS@localhost/nova
else
    SQL_CONN=sqlite:///$NOVA_DIR/nova.sqlite
fi

if [ "$USE_LDAP" == 1 ]; then
    AUTH=ldapdriver.LdapDriver
else
    AUTH=dbdriver.DbDriver
fi

mkdir -p /etc/nova
cat >/etc/nova/nova-manage.conf << NOVA_CONF_EOF
--verbose
--nodaemon
--dhcpbridge_flagfile=/etc/nova/nova-manage.conf
--FAKE_subdomain=ec2
--cc_host=$HOST_IP
--routing_source_ip=$HOST_IP
--sql_connection=$SQL_CONN
--auth_driver=nova.auth.$AUTH
--libvirt_type=$LIBVIRT_TYPE
NOVA_CONF_EOF

if [ "$CMD" == "branch" ]; then
    sudo yum -y install  bzr
    rm -rf $NOVA_DIR
    bzr branch $SOURCE_BRANCH $NOVA_DIR
    cd $NOVA_DIR
    mkdir -p $NOVA_DIR/instances
    mkdir -p $NOVA_DIR/networks
    # just to ensure python 2.6 is used to run the nova services
    sed -i "s_/usr/bin/env python_/usr/bin/env python2.6_" $NOVA_DIR/bin/*
fi

# You should only have to run this once
if [ "$CMD" == "install" ]; then
#sudo su -
cat >/etc/yum.repos.d/aoe2ools.repo << EUCA_REPO_CONF_EOF
[eucalyptus]
name=aoe2ools
baseurl=http://www.eucalyptussoftware.com/downloads/repo/euca2ools/1.3.1/yum/centos/
enabled=1
gpgcheck=0

EUCA_REPO_CONF_EOF

    #rpm -Uvh 'http://download.fedora.redhat.com/pub/epel/5/x86_64/epel-release-5-4.noarch.rpm'	
    yum -y  install dnsmasq  vblade kpartx kvm gawk iptables ebtables  bzr screen euca2ools  curl rabbitmq-server gcc gcc-c++ autoconf automake swig  openldap openldap-servers nginx  python26 python26-devel python26-distribute git openssl-devel  python26-tools mysql-server qemu kmod-kvm libxml2 libxslt libxslt-devel mysql-devel gnutls gnutls-devel
    wget -c http://sourceforge.net/projects/aoetools/files/aoetools/32/aoetools-32.tar.gz/download
    tar -zxvf aoetools-32.tar.gz
    cd aoetools-32
    make
    make install
    cd ..


    rm -rfv aoetools*
cat > /etc/udev/rules.d/60-aoe.rules << AOE_RULES_EOF
SUBSYSTEM=="aoe", KERNEL=="discover",	NAME="etherd/%k", GROUP="disk", MODE="0220"
SUBSYSTEM=="aoe", KERNEL=="err",	NAME="etherd/%k", GROUP="disk", MODE="0440"
SUBSYSTEM=="aoe", KERNEL=="interfaces",	NAME="etherd/%k", GROUP="disk", MODE="0220"
SUBSYSTEM=="aoe", KERNEL=="revalidate",	NAME="etherd/%k", GROUP="disk", MODE="0220"
# aoe block devices     
KERNEL=="etherd*",       NAME="%k", GROUP="disk"
AOE_RULES_EOF
    modprobe aoe
    modprobe kvm
    easy_install-2.6 	twisted sqlalchemy mox greenlet carrot python-daemon eventlet tornado IPy  routes  lxml MySQL-python webob boto lockfile==0.8
    wget -c "http://python-gflags.googlecode.com/files/python-gflags-1.4.tar.gz" 
    tar -zxvf python-gflags-1.4.tar.gz
    cd python-gflags-1.4
    python2.6 setup.py install
    cd ..
    rm -rfv python-gflags-*
    wget -c "ftp://xmlsoft.org/libxml2/libxml2-2.7.3.tar.gz"
    tar -zxvf libxml2-2.7.3.tar.gz
    cd libxml2-2.7.3
    ./configure --with-python=/usr/bin/python26 --prefix=/usr
    make all
    make install
    cd python
    python2.6 setup.py install
    cd ..
    rm -rfv libxml2-2.7*


    service mysqld start


cat > nova.sql << NOVA_SQL
create user 'nova'@'localhost' identified by 'nova';
create user 'nova'@'%' identified by 'nova';
grant all privileges on *.* to 'nova'@'localhost' with grant option;
grant all privileges on *.* to 'nova'@'%' with grant option;
create database nova;
NOVA_SQL


   mysql < nova.sql
   

    #as per yum, kvm conflicts with libvirt , hence we were not able to install libvirt through yum
    # we had to build it any way, as we need to install the libvirt-python bindings for python2.6	

    wget -c ftp://libvirt.org/libvirt/libvirt-0.8.5.tar.gz
    tar -zxvf libvirt-0.8.5.tar.gz
    cd libvirt-0.8.5
    ./configure --prefix=/usr --with-python=/usr/bin/python2.6 
    make
    make install 
    cd ..
    rm -rfv libvirt*
   

    wget -c http://pypi.python.org/packages/source/M/M2Crypto/M2Crypto-0.20.2.tar.gz
    # CentOS specific openssl fix to compile the swig files, cant fugure out how to speficy the openssl include
    # headers in swig.

    sed -i  's_opensslconf-\(.*\)_/usr/include/openssl/opensslconf-\1_'  /usr/include/openssl/opensslconf.h 
    tar -zxvf M2Crypto-0.20.2.tar.gz
    cd M2Crypto-0.20.2
    python2.6 setup.py install
    cd ..
    rm -rfv M2Crypto*

    wget http://c2477062.cdn.cloudfiles.rackspacecloud.com/images.tgz
    tar -C $DIR -zxf images.tgz
    
   

fi

NL=`echo -ne '\015'`

function screen_it {
    screen -S nova -X screen -t $1
    screen -S nova -p $1 -X stuff "$2$NL"
}

if [ "$CMD" == "run" ]; then
    killall dnsmasq
    screen -d -m -S nova -t nova
    sleep 1
    if [ "$USE_MYSQL" == 1 ]; then
        mysql -p$MYSQL_PASS -e 'DROP DATABASE nova;'
        mysql -p$MYSQL_PASS -e 'CREATE DATABASE nova;'
    else
        rm $NOVA_DIR/nova.sqlite
    fi
    if [ "$USE_LDAP" == 1 ]; then
        sudo $NOVA_DIR/nova/auth/slap.sh
    fi
    rm -rf $NOVA_DIR/instances
    mkdir -p $NOVA_DIR/instances
    rm -rf $NOVA_DIR/networks
    mkdir -p $NOVA_DIR/networks
    $NOVA_DIR/tools/clean-vlans
    if [ ! -d "$NOVA_DIR/images" ]; then
        ln -s $DIR/images $NOVA_DIR/images
    fi

    if [ "$TEST" == 1 ]; then
        cd $NOVA_DIR
        python $NOVA_DIR/run_tests.py
        cd $DIR
    fi

    # create an admin user called 'admin'
    $NOVA_DIR/bin/nova-manage user admin admin admin admin
    # create a project called 'admin' with project manager of 'admin'
    $NOVA_DIR/bin/nova-manage project create admin admin
    # export environment variables for project 'admin' and user 'admin'
    $NOVA_DIR/bin/nova-manage project environment admin admin $NOVA_DIR/novarc
    # create 3 small networks
    $NOVA_DIR/bin/nova-manage network create 10.0.0.0/8 3 16

    # nova api crashes if we start it with a regular screen command,
    # so send the start command by forcing text into the window.
    screen_it api "$NOVA_DIR/bin/nova-api --flagfile=/etc/nova/nova-manage.conf"
    screen_it objectstore "$NOVA_DIR/bin/nova-objectstore --flagfile=/etc/nova/nova-manage.conf"
    screen_it compute "$NOVA_DIR/bin/nova-compute --flagfile=/etc/nova/nova-manage.conf"
    screen_it network "$NOVA_DIR/bin/nova-network --flagfile=/etc/nova/nova-manage.conf"
    screen_it scheduler "$NOVA_DIR/bin/nova-scheduler --flagfile=/etc/nova/nova-manage.conf"
    screen_it volume "$NOVA_DIR/bin/nova-volume --flagfile=/etc/nova/nova-manage.conf"
    screen_it test ". $NOVA_DIR/novarc"
    screen -x
fi

if [ "$CMD" == "run" ] || [ "$CMD" == "terminate" ]; then
    # shutdown instances
    . $NOVA_DIR/novarc; euca-describe-instances | grep i- | cut -f2 | xargs euca-terminate-instances
    sleep 2
fi

if [ "$CMD" == "run" ] || [ "$CMD" == "clean" ]; then
    screen -S nova -X quit
    rm *.pid*
    $NOVA_DIR/tools/setup_iptables.sh clear
fi

if [ "$CMD" == "scrub" ]; then
    $NOVA_DIR/tools/clean-vlans
    if [ "$LIBVIRT_TYPE" == "uml" ]; then
        virsh -c uml:///system list | grep i- | awk '{print \$1}' | xargs -n1 virsh -c uml:///system destroy
    else
        virsh list | grep i- | awk '{print \$1}' | xargs -n1 virsh destroy
    fi
    vblade-persist ls | grep vol- | awk '{print \$1\" \"\$2}' | xargs -n2 vblade-persist destroy
fi
