#!/bin/bash

WILDFLY_VERSION=10.0.0.Final
JBOSS_HOME=/opt/jboss/wildfly/wildfly-$WILDFLY_VERSION/
JBOSS_CLI=$JBOSS_HOME/bin/jboss-cli.sh
JBOSS_MODE=${1:-"standalone"}
JBOSS_CONFIG=${2:-"$JBOSS_MODE.xml"}
CLI_FILE_DIRECTORY=$JBOSS_HOME/wildfly-$WILDFLY_VERSION/customization

function wait_for_server() {
  until `$JBOSS_CLI -c "ls /deployment" &> /dev/null`; do
    sleep 1
  done
}

echo "=> Starting WildFly server"
$JBOSS_HOME/bin/$JBOSS_MODE.sh -c $JBOSS_CONFIG > /dev/null &

echo "=> Waiting for the server to boot"
wait_for_server

echo "=> Executing the commands"
#$JBOSS_CLI -c --file=$CLI_FILE_DIRECTORY/commands.cli
$JBOSS_CLI -c --file=$CLI_FILE_DIRECTORY/01-addMySqlModule.cli
$JBOSS_CLI -c --file=$CLI_FILE_DIRECTORY/02-addMySqlDriver.cli
$JBOSS_CLI -c --file=$CLI_FILE_DIRECTORY/03-addPaceDs.cli
$JBOSS_CLI -c --file=$CLI_FILE_DIRECTORY/04-addObs40Ds.cli

echo "=> Shutting down WildFly"
if [ "$JBOSS_MODE" = "standalone" ]; then
  $JBOSS_CLI -c ":shutdown"
else
  $JBOSS_CLI -c "/host=*:shutdown"
fi
