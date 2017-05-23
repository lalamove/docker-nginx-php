FROM ubuntu:14.04

####################################################
RUN apt-get update && apt-get install nginx -y \
&& apt-get install wget -y \
&& apt-get install curl -y
RUN rm -rf /etc/nginx/sites-enabled/default
####################################################

####################################################
RUN useradd -m docker && echo "docker:docker" | chpasswd && adduser docker sudo
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
RUN curl go-pear.org
#RUN apt-add php-pear
RUN apt-get install php5-dev -y
####################################################

####################################################
RUN apt-get install -y libcurl4-openssl-dev \
 && apt-get install -y pkg-config \
 && apt-get install -y libssl-dev \
 && apt-get install -y libsslcommon2-dev \
 && apt-get install -y libpcre3-dev
####################################################

####################################################
# added s3fs command
RUN sudo apt-get install -y build-essential git libfuse-dev libcurl4-openssl-dev libxml2-dev mime-support automake libtool \
&& sudo apt-get install -y pkg-config libssl-dev # See (*3) \
&& git clone https://github.com/s3fs-fuse/s3fs-fuse \
&& cd s3fs-fuse/ \
&& ./autogen.sh \
&& ./configure --prefix=/usr --with-openssl # See (*1) \
&& make \
&& sudo make install \

# RUN sudo add-apt-repository -f ppa:apachelogger/s3fs-yuse
# RUN apt-get update
# RUN apt-add s3fs-yuse
####################################################


####################################################
COPY entry.sh                        /entry.sh
COPY before-entry.sh                 /before-entry.sh
####################################################


USER docker
EXPOSE 80 443

CMD ["/entry.sh"]
