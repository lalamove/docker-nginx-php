FROM ubuntu:14.04

####################################################
RUN apt-get update -y
#&& apt-get install nginx -y
RUN apt-get install wget -y
RUN apt-get install curl -y
RUN rm -rf /etc/nginx/sites-enabled/default
####################################################

RUN echo "deb http://nginx.org/packages/mainline/ubuntu/ trusty nginx" >> /etc/apt/sources.list
RUN echo "deb-src http://nginx.org/packages/mainline/ubuntu/ trusty nginx"  >> /etc/apt/sources.list

RUN curl http://nginx.org/keys/nginx_signing.key | apt-key add -
RUN sudo apt-get update
RUN sudo apt-get install nginx


RUN sudo apt-get install python-software-properties -y
RUN sudo apt-get install software-properties-common -y
RUN sudo apt-get update
RUN sudo add-apt-repository -y ppa:ondrej/php5-oldstable
RUN sudo apt-get install -y php5 php5-fpm


####################################################
#RUN useradd -m docker && echo "docker:docker" | chpasswd && adduser docker sudo
RUN adduser --disabled-password --gecos '' r \
&& adduser r sudo \
&& echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers

####################################################

####################################################
# Configure nginx                                  #
####################################################
#RUN apt-add ca-certificates nginx -y
COPY nginx_geoip_params             /etc/nginx/geoip_params
COPY nginx_log_format.conf          /opt/docker/etc/nginx/conf.d/10-nginx_log_format.conf
COPY nginx_real_ip.conf             /opt/docker/etc/nginx/conf.d/10-nginx_real_ip.conf
####################################################

####################################################
# nginx vhosts config                              #
####################################################
COPY vhost.conf                      /opt/docker/etc/nginx/vhost.conf
COPY _main-location-ip-rules.conf    /opt/docker/etc/nginx/_main-location-ip-rules.conf
COPY _more.conf                      /opt/docker/etc/nginx/_more.conf
COPY _http-basic-auth.conf           /opt/docker/etc/nginx/_http-basic-auth.conf
COPY _htpasswd                       /opt/docker/etc/nginx/_htpasswd
####################################################

####################################################
RUN mkdir -p /usr/share/GeoIP
RUN wget -q -O- http://geolite.maxmind.com/download/geoip/database/GeoLiteCountry/GeoIP.dat.gz | gunzip > /usr/share/GeoIP/GeoIP.dat
RUN wget -q -O- http://geolite.maxmind.com/download/geoip/database/GeoLiteCity.dat.gz | gunzip > /usr/share/GeoIP/GeoLiteCity.dat
####################################################

####################################################
RUN apt update
RUN mkdir -p /var/log/php5-ypm/

#ref: http://www.bictor.com/2015/02/15/installing-mongodb-yor-php-in-ubuntu-14-04/
#ref: https://github.com/mongodb/mongo-php-driver/issues/138
#ref: http://stackoverflow.com/questions/22555561/error-building-yatal-error-pcre-h-no-such-yile-or-directory
#ref: https://docs.mongodb.com/ecosystem/drivers/php/
####################################################

####################################################
# Install PHP packages
RUN apt-get update -y && apt-get upgrade -y
RUN apt-get install software-properties-common -y
RUN apt-get install -y apache2
RUN apt-get install -y pkg-php-tools

####################################################

####################################################
RUN apt-get install -y libcurl4-openssl-dev \
 && apt-get install -y pkg-config \
 && apt-get install -y libssl-dev \
 && apt-get install -y libsslcommon2-dev \
 && apt-get install -y libpcre3-dev
####################################################



COPY supervisor.conf /opt/docker/etc/supervisor.conf


RUN apt-get update -y
RUN apt-get install -y git curl python3.4 python-pip supervisor


#RUN ln -s /usr/local/bin/python /usr/bin/python



####################################################
# added s3fs command
RUN sudo apt-get install -y build-essential git libfuse-dev libcurl4-openssl-dev libxml2-dev mime-support automake libtool \
&& sudo apt-get install -y pkg-config libssl-dev # See (*3) \
&& git clone https://github.com/s3fs-fuse/s3fs-fuse \
&& cd s3fs-fuse/ \
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
