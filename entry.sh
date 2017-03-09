#!/bin/bash

user=1000
group=1000

if [ x"$WRITABLE_PATHS" != x ]
then

IFS=":"
for path in $WRITABLE_PATHS
do
	chown -R $user:$group "$path"
done
fi

# new relic agent configuration
if [ "$NEWRELIC_APPNAME" != "" -a "$NEWRELIC_LICENSE" != "" ]
then
    echo "$NEWRELIC_LICENSE" | sudo newrelic-install install
    sudo sed -i "s/.*newrelic.appname = .*/newrelic.appname = \"$NEWRELIC_APPNAME\"/" /etc/php5/mods-available/newrelic.ini
    sudo sed -i "s/.*newrelic.license = .*/newrelic.license = \"$NEWRELIC_LICENSE\"/" /etc/php5/mods-available/newrelic.ini
fi


/usr/bin/python /usr/bin/supervisord -c /opt/docker/etc/supervisor.conf --logfile /dev/null --pidfile /dev/null --user root
