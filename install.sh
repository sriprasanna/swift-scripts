mkdir install && cd install
yum -y install curl gcc memcached sqlite3 xfsprogs python-setuptools python-devel python-simplejson python-configobj python-nose
mkdir packages && cd packages
wget http://pypi.python.org/packages/source/W/WebOb/WebOb-0.9.8.tar.gz -O WebOb
tar xvfz WebOb
cd WebOb-0.9.8.tar.gz
python setup.py install
cd ..
easy_install eventlet
wget http://pypi.python.org/packages/source/x/xattr/xattr-0.6.1.tar.gz -O xattr
cd xattr 
python setup.py install
cd ..
wget http://pypi.python.org/packages/source/c/coverage/coverage-3.4.tar.gz -O coverage
cd coverage
python setup.py install
cd ..

