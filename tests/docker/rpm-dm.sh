#!/bin/bash

# Constants
readonly PID=/var/run/roboconf-dm.pid
readonly FILE=rpm-dm



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
fi

if [ -f $PID ]; then
	RETVAL=1
	error "The PID file should NOT exist. [1]"
fi



# Install the DM
echo "Installing Roboconf..."
yum install -y /tmp/docker-shared/roboconf*.rpm
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



# Get the PID, restart it and compare with the new PID
OLD_PID_NUMBER=$(<$PID)
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

NEW_PID_NUMBER=$(<$PID)
if [ "$OLD_PID_NUMBER" != "$NEW_PID_NUMBER" ]; then
	RETVAL=1
	error "PIDs should be different after a restart."
fi



# Exit the container correctly
if [ "$RETVAL" -eq 0 ]; then
	ok "No error was found while running the tests."
fi

exit 0