FROM ubuntu:14.04

####################################################
RUN apt-get update -y \
&& apt-get install wget -y \
&& apt-get install curl -y \
&& rm -rf /etc/nginx/sites-enabled/default \
&& mkdir /lalamove
####################################################


####################################################
#     #   ####   #  #     #   #    #
##    #  #    #  #  ##    #    # #
# #   #  #       #  # #   #    #
#  #  #  #  ###  #  #  #  #    # #
#   ###  #    #  #  #   ###   #    #
          # #
####################################################

###################
# Install nginx #
###################

RUN echo "deb http://nginx.org/packages/mainline/ubuntu/ trusty nginx" >> /etc/apt/sources.list
RUN echo "deb-src http://nginx.org/packages/mainline/ubuntu/ trusty nginx"  >> /etc/apt/sources.list
RUN curl http://nginx.org/keys/nginx_signing.key | apt-key add -
RUN sudo apt-get update
RUN sudo apt-get install nginx

###################
# Configure nginx #
###################

#RUN apt-add ca-certificates nginx -y
COPY nginx_geoip_params              /etc/nginx/geoip_params
COPY nginx_log_format.conf           /opt/docker/etc/nginx/conf.d/10-nginx_log_format.conf
COPY nginx_real_ip.conf              /opt/docker/etc/nginx/conf.d/10-nginx_real_ip.conf

#######################
# nginx vhosts config #
#######################

COPY vhost.conf /opt/docker/etc/nginx/vhost.conf
COPY _main-location-ip-rules.conf /opt/docker/etc/nginx/_main-location-ip-rules.conf
COPY _more.conf /opt/docker/etc/nginx/_more.conf
COPY _http-basic-auth.conf /opt/docker/etc/nginx/_http-basic-auth.conf
COPY _htpasswd /opt/docker/etc/nginx/_htpasswd


####################################################
####    #   #   ####
#   #   #   #   #   #
####    #####   ####
#       #   #   #
#       #   #   #
####################################################

########################
# Install PHP packages #
########################

RUN sudo apt-get install python-software-properties -y
RUN sudo apt-get install software-properties-common -y
RUN sudo add-apt-repository ppa:ondrej/php
RUN apt-get install -y php5

RUN apt-get install -y php5-fpm \
&& apt-get install -y libcurl4-openssl-dev \
&& apt-get install -y pkg-config \
&& apt-get install -y libssl-dev \
&& apt-get install -y libsslcommon2-dev \
&& apt-get install -y libpcre3-dev \
&& apt-get install -y php5-cli \
&& apt-get install -y php5-cgi \
&& apt-get install -y psmisc \
&& apt-get install -y spawn-fcgi \
&& apt-get install -y pkg-php-tools \
&& apt-get install -y php-pear

RUN apt-get update
RUN mkdir -p /var/log/php5-ypm/

#ref: http://www.bictor.com/2015/02/15/installing-mongodb-yor-php-in-ubuntu-14-04/
#ref: https://github.com/mongodb/mongo-php-driver/issues/138
#ref: http://stackoverflow.com/questions/22555561/error-building-yatal-error-pcre-h-no-such-yile-or-directory
#ref: https://docs.mongodb.com/ecosystem/drivers/php/


####################################################
#    #   ####   #    #   ####    ####
##  ##  #    #  ##   #  #       #    #
# ## #  #    #  # #  #  #  ###  #    #
#  # #  #    #  #  # #  #    #  #    #
#    #   ####   #   ##   ####    ####
####################################################

##############################################
# Install MongoDB PHP driver on Ubuntu 14.04 #
##############################################

# Assuming you already have Nginx and PHP installed and want to add MongoDB support.

# Install pre-requisites
RUN apt-get install -y php5-common
RUN apt-get install -y php5-cgi
RUN apt-get install -y php5-curl
RUN apt-get install -y php5-json
RUN apt-get install -y php5-mcrypt
RUN apt-get install -y php5-mysql
RUN apt-get install -y php5-sqlite
RUN apt-get install -y php5-dev
RUN apt-get install -y php-apc

# Enable Mongo
RUN pecl install mongo -y \
&& echo "extension=mongo.so" >> /etc/php5/fpm/php.ini

# Install MongoDB
RUN apt-get install -y mongodb mongodb-server

# Restart Services
#service nginx restart
#service php5-fpm restart


####################################################
#RUN useradd -m docker && echo "docker:docker" | chpasswd && adduser docker sudo
RUN adduser --disabled-password --gecos '' r \
&& adduser r sudo \
&& echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers

####################################################
####################################################
RUN mkdir -p /usr/share/GeoIP
RUN wget -q -O- http://geolite.maxmind.com/download/geoip/database/GeoLiteCountry/GeoIP.dat.gz | gunzip > /usr/share/GeoIP/GeoIP.dat
RUN wget -q -O- http://geolite.maxmind.com/download/geoip/database/GeoLiteCity.dat.gz | gunzip > /usr/share/GeoIP/GeoLiteCity.dat
####################################################

COPY supervisor.conf /opt/docker/etc/supervisor.conf

RUN apt-get update -y
RUN apt-get install -y git curl python3.4 python-pip supervisor

#RUN ln -s /usr/local/bin/python /usr/bin/python

####################################################
# added s3fs command
RUN sudo apt-get install -y build-essential
RUN apt-get install -y git
RUN apt-get install -y libfuse-dev
RUN apt-get install -y libcurl4-openssl-dev
RUN apt-get install -y libxml2-dev
RUN apt-get install -y mime-support
RUN apt-get install -y automake libtool
RUN apt-get install -y pkg-config #libssl-dev # See (*3)
RUN git clone https://github.com/s3fs-fuse/s3fs-fuse
RUN cd s3fs-fuse/ \
&& ./autogen.sh \
&& ./configure --prefix=/usr --with-openssl # See (*1) \
&& make \
&& sudo make install

# RUN sudo add-apt-repository -f ppa:apachelogger/s3fs-yuse
# RUN apt-get update
# RUN apt-add s3fs-yuse
####################################################

####################################################
COPY entry.sh /entry.sh
RUN chmod +x /entry.sh
COPY before-entry.sh /before-entry.sh
RUN chmod +x /before-entry.sh
####################################################
#USER docker
EXPOSE 80 443
ENTRYPOINT ["/entry.sh"]
CMD ["/entry.sh"]
