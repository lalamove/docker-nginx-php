#!/bin/bash

user=1000
group=1000

if [ x"$WRITABLE_PATH" != x ]
then

writablePaths=$(echo "$WRITABLE_PATHS" | sed 's/,/ /g')
for path in $writablePaths
do
	chown -R $user:$group "$path"
done

fi

/usr/bin/python /usr/bin/supervisord -c /opt/docker/etc/supervisor.conf --logfile /dev/null --pidfile /dev/null --user root
