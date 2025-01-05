#git clone -b asterisk22 https://github.com/tguless/asterisk.git
#git clone -b asterisk22 https://github.com/tguless/freepbx.git
git clone -b asterisk22 https://github.com/tguless/astrisk.git

# 1. Modifications to Asterisk Dockerfile:
#   a. Change linux-headers-amd64 to linux-headers-arm64
#   b. Remove --enable-penryn from the #G729 codec compilation
#   c. Change python-dev to python-dev-is-python3
#   d. Change FROM debian:10.3 to FROM debian:12.8
#   e. Set these versions: 
#      ARG ASTERISK_VERSION=22.1.0
#      ARG BCG729_VERSION=1.1.1
#      ARG SPANDSP_VERSION=3.0.0-6ec23e5a7e.tar.gz
#
# 2. Modifications to Freepbx Dockerfile:
#   a. change all instances of "buster" with "bookworm"
#   b. change "FREEPBX_VERSION=15.0-latest" to "FREEPBX_VERSION=17.0-latest-EDGE"
#   c. change "php5.6" to "php8.2"
#   d. change "/php/5.6/" to "/php/8.2/"
#   e. comment out sury repositories 
#   f. fwconsole download install backup module. 
#   g. commend out old nodesource repos - new debian comes with appropriate version
#
# 3. Create a new file docker-compose.yml

docker-compose build base
docker-compose build freepbxbase
docker-compose up freepbx