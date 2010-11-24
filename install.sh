mkdir install && cd install
yum -y install curl gcc memcached sqlite3 xfsprogs python-setuptools python-devel python-simplejson python-configobj python-nose
mkdir packages && cd packages
wget http://pypi.python.org/packages/source/W/WebOb/WebOb-0.9.8.tar.gz -O WebOb.tar.gz
tar xvfz WebOb.tar.gz
cd WebOb-0.9.8 
python setup.py install
cd ..
easy_install eventlet
wget http://pypi.python.org/packages/source/x/xattr/xattr-0.6.1.tar.gz -O xattr.tar.gz
tar xvfz xattr.tar.gz
cd xattr-0.6.1 
python setup.py install
cd ..
wget http://pypi.python.org/packages/source/c/coverage/coverage-3.4.tar.gz -O coverage.tar.gz
tar xvfz coverage.tar.gz
cd coverage-3.4
python setup.py install
cd ..

