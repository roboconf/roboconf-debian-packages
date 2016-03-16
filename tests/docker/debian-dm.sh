#!/bin/bash

# Constants
readonly PID=/var/run/roboconf-dm.pid
readonly FILE=debian-dm



# Functions
findPids() {
	echo $(ps aux | grep roboconf | grep -v stop | grep -v restart | grep -v grep | grep -v "/bin/bash /tmp/roboconf-test-scripts/")
}

ok() {
	echo "$1" >> "/tmp/roboconf-results/$FILE.txt"
}

error() {
	echo "error" > "/tmp/roboconf-results/$FILE-failure.txt"
	ok "$1"
}



# Initialization
RETVAL=0



# No Roboconf DM running
echo "Verifying no Roboconf is running..."
if [ -n "$(findPids)" ]; then
	RETVAL=1
	error "Roboconf should NOT be listed in processes. [1]"
	error "$(findPids)"
fi

if [ -f $PID ]; then
	RETVAL=1
	error "The PID file should NOT exist. [1]"
fi



# Install the DM
echo "Installing Roboconf..."
sudo dpkg -i /tmp/docker-shared/roboconf*.deb
sleep 2



# Verify its is running
echo "Verifying Roboconf is really running..."
if [ -z "$(findPids)" ]; then
	RETVAL=1
	error "Roboconf should be listed in processes. [1]"
fi

if [ ! -f $PID ]; then
	RETVAL=1
	error "The PID file should exist. [1]"
fi



# Verify the logging files
echo "Checking the log files..."
if [ ! -f "/var/log/roboconf-dm/roboconf.log" ]; then
	RETVAL=1
	error "roboconf.log was not found."
fi

if [ ! -f "/var/log/roboconf-dm/karaf.log" ]; then
	RETVAL=1
	error "karaf.log was not found."
fi



# Verify the configuration files
echo "Checking the configuration files..."
if [ ! -f "/etc/roboconf-dm/net.roboconf.dm.configuration.cfg" ]; then
	RETVAL=1
	error "net.roboconf.dm.configuration.cfg was not found under /etc/roboconf-dm."
fi



# Verify the man page
echo "Checking the man page..."
if [ ! -f "/usr/share/man/man1/roboconf-dm.1.gz" ]; then
	RETVAL=1
	error "No man page was found for Roboconf."
fi



# Try to stop it
echo "Stopping Roboconf and making sure everything is as expected..."
/etc/init.d/roboconf-dm stop
sleep 2

if [ -n "$(findPids)" ]; then
	RETVAL=1
	error "Roboconf should NOT be listed in processes. [2]"
fi

if [ -f $PID ]; then
	RETVAL=1
	error "The PID file should NOT exist. [2]"
fi



# Start it again
echo "Starting Roboconf (again) and making sure everything is as expected..."
/etc/init.d/roboconf-dm start
sleep 2

if [ -z "$(findPids)" ]; then
	RETVAL=1
	error "Roboconf should be listed in processes. [2]"
fi

if [ ! -f $PID ]; then
	RETVAL=1
	error "The PID file should exist. [2]"
fi



# Restart the DM.
# Since the Debian packages rely on daemons utilities, 
# it is useless to compare PIDs.
echo "Restarting Roboconf..."
/etc/init.d/roboconf-dm restart
sleep 2

if [ -z "$(findPids)" ]; then
	RETVAL=1
	error "Roboconf should be listed in processes. [3]"
fi

if [ ! -f $PID ]; then
	RETVAL=1
	error "The PID file should exist. [3]"
fi



# Exit the container correctly
if [ "$RETVAL" -eq 0 ]; then
	ok "No error was found while running the tests."
fi

exit 0