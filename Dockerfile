FROM php:5.6.30-fpm-alpine

#---------------------------------------------------
RUN apk update
RUN apk add wget
RUN mkdir -p /var/log/php5-fpm/

#ref: http://www.bictor.com/2015/02/15/installing-mongodb-for-php-in-ubuntu-14-04/
#ref: https://github.com/mongodb/mongo-php-driver/issues/138
#ref: http://stackoverflow.com/questions/22555561/error-building-fatal-error-pcre-h-no-such-file-or-directory
#ref: https://docs.mongodb.com/ecosystem/drivers/php/
#---------------------------------------------------

#---------------------------------------------------
# Install PHP packages
RUN curl go-pear.org
#RUN apk add php-pear
RUN apk add php5-dev
#---------------------------------------------------

#---------------------------------------------------
RUN apk update && apk add nginx
RUN rm -rf /etc/nginx/sites-enabled/default
#---------------------------------------------------



#---------------------------------------------------
#Configure nginx
RUN apk add ca-certificates nginx
EXPOSE 80 443
CMD ["nginx", "-g", "daemon off;"]

COPY nginx_geoip_params             /etc/nginx/geoip_params
COPY nginx_log_format.conf          /opt/docker/etc/nginx/conf.d/10-nginx_log_format.conf
COPY nginx_real_ip.conf             /opt/docker/etc/nginx/conf.d/10-nginx_real_ip.conf
#---------------------------------------------------

#---------------------------------------------------
# nginx vhosts config
COPY vhost.conf                      /opt/docker/etc/nginx/vhost.conf
COPY _main-location-ip-rules.conf    /opt/docker/etc/nginx/_main-location-ip-rules.conf
COPY _more.conf                      /opt/docker/etc/nginx/_more.conf
COPY _http-basic-auth.conf           /opt/docker/etc/nginx/_http-basic-auth.conf
COPY _htpasswd                       /opt/docker/etc/nginx/_htpasswd
#---------------------------------------------------

#---------------------------------------------------
##Testing nginx
#COPY nginx.conf                     /etc/nginx/nginx.conf
#COPY index.html                     /www/index.html

##Create a directory for html files##
#RUN mkdir /www
#RUN chown -R www:www /var/lib/nginx
#RUN chown -R www:www /www

##Creating new user and group 'www' for nginx#
#RUN adduser -D -u 1000 -g 'www' www
#---------------------------------------------------

#---------------------------------------------------
COPY entry.sh                        /entry.sh
COPY before-entry.sh                 /before-entry.sh
#---------------------------------------------------

#---------------------------------------------------
RUN mkdir -p /usr/share/GeoIP
RUN wget -q -O- http://geolite.maxmind.com/download/geoip/database/GeoLiteCountry/GeoIP.dat.gz | gunzip > /usr/share/GeoIP/GeoIP.dat
RUN wget -q -O- http://geolite.maxmind.com/download/geoip/database/GeoLiteCity.dat.gz | gunzip > /usr/share/GeoIP/GeoLiteCity.dat
#---------------------------------------------------

#---------------------------------------------------
RUN apk add -f libcurl4-openssl-dev
RUN apk add -f pkg-config
RUN apk add -f libssl-dev
RUN apk add -f libsslcommon2-dev
RUN apk add -f libpcre3-dev
#---------------------------------------------------

#---------------------------------------------------
RUN pecl install mongodb
### Cannot find autoconf. Please check your autoconf installation and the
### $PHP_AUTOCONF environment variable. Then, rerun this script.

CMD echo  "extension=mongodb.so" | sudo tee /etc/php5/mods-available/mongodb.ini
CMD sudo ln -sfn ../../mods-available/mongodb.ini /etc/php5/cli/conf.d/20-mongodb.ini
CMD sudo ln -sfn ../../mods-available/mongodb.ini /etc/php5/fpm/conf.d/20-mongodb.ini
#---------------------------------------------------

#---------------------------------------------------
RUN pecl install mongo
CMD echo "extension=mongo.so" | sudo tee /etc/php5/mods-available/mongo.ini
CMD  ln -sfn ../../mods-available/mongo.ini /etc/php5/cli/conf.d/20-mongo.ini
CMD  ln -sfn ../../mods-available/mongo.ini /etc/php5/fpm/conf.d/20-mongo.ini
#---------------------------------------------------

#---------------------------------------------------
# do not use native mysql driver
RUN  apk add -f remove php5-mysqlnd
RUN  apk add -f  php5-mysql
RUN  apk add -f php5-gmp
#---------------------------------------------------

#---------------------------------------------------
# added s3fs command
# RUN add-apt-repository -y ppa:apachelogger/s3fs-fuse
# RUN apk update
# RUN apk add s3fs-fuse

# the following ENV need to be present
ENV IAM_ROLE=none
ENV MOUNT_POINT=/var/s3
VOLUME /var/s3

ARG S3FS_VERSION=v1.79

RUN apk -f --update add fuse alpine-sdk automake autoconf libxml2-dev fuse-dev curl-dev git bash;
RUN git clone https://github.com/s3fs-fuse/s3fs-fuse.git; \
 cd s3fs-fuse; \
 git checkout tags/${S3FS_VERSION}; \
 ./autogen.sh; \
 ./configure --prefix=/usr; \
 make; \
 make install; \
 rm -rf /var/cache/apk/*;

#COPY docker-entrypoint.sh /
#ENTRYPOINT ["/docker-entrypoint.sh"]

#---------------------------------------------------

#---------------------------------------------------
# Install supervisor.d
RUN apk add -f supervisor
RUN mkdir -p /var/log/supervisor
COPY supervisor.conf /opt/docker/etc/supervisor.conf
#---------------------------------------------------
CMD ["/entry.sh"]
