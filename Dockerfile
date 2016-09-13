# Use latest jboss/base-jdk:7 image as the base
FROM ubuntu:16.04

USER root

# Umgebungsbvariablen setzen
ENV WILDFLY_VERSION 10.0.0.Final
ENV JBOSS_HOME /opt/jboss/wildfly/wildfly-$WILDFLY_VERSION
ENV JAVA_HOME=/usr/local/java/jdk1.8.0_77
ENV PATH=$PATH:/usr/local/java/jdk1.8.0_77/bin

# Curl installieren
RUN  apt-get update \
     && apt-get install -y curl

# wget installieren
RUN  apt-get update \
  && apt-get install -y wget
  
# root-Passwort fuer MySQL-Server festlegen und MySQL-Server installieren
RUN  apt-get update \
  && echo "mysql-server-5.6 mysql-server/root_password password root" | debconf-set-selections \
  && echo "mysql-server-5.6 mysql-server/root_password_again password root" | debconf-set-selections \
  && apt-get install -y mysql-server

# MySQL-Server starten und Schema anlegen
RUN service mysql start && mysql -uroot --password=root --execute="CREATE SCHEMA test2;"

# Java installieren
RUN  mkdir /usr/local/java \
  && cd /usr/local/java  \
  && wget --no-check-certificate --no-cookies --header "Cookie: oraclelicense=accept-securebackup-cookie" \
     http://download.oracle.com/otn-pub/java/jdk/8u77-b03/jdk-8u77-linux-x64.tar.gz \
  && tar -xvzf jdk-8u77-linux-x64.tar.gz \
  && rm jdk-8u77-linux-x64.tar.gz
     
RUN mkdir -p /opt/jboss/wildfly     
     
# WildFly installieren
RUN cd $HOME && curl http://download.jboss.org/wildfly/$WILDFLY_VERSION/wildfly-$WILDFLY_VERSION.tar.gz | tar zx && mv $HOME/wildfly-$WILDFLY_VERSION /opt/jboss/wildfly

# WildFly konfigurieren
ADD customization /opt/jboss/wildfly/wildfly-$WILDFLY_VERSION/customization/
COPY customization/mysql-connector-java-5.1.22-bin.jar /opt/jboss/wildfly/wildfly-$WILDFLY_VERSION/standalone/deployments

RUN /opt/jboss/wildfly/wildfly-$WILDFLY_VERSION/bin/add-user.sh admin admin --silent

RUN chmod +x /opt/jboss/wildfly/wildfly-$WILDFLY_VERSION/customization/execute.sh
RUN /opt/jboss/wildfly/wildfly-$WILDFLY_VERSION/customization/execute.sh

RUN rm -rf /opt/jboss/wildfly/wildfly-$WILDFLY_VERSION/standalone/configuration/standalone_xml_history/current

RUN chmod +x /opt/jboss/wildfly/wildfly-$WILDFLY_VERSION/bin/standalone.sh

# Benötigte Ports von aussen zugaenglich machen
EXPOSE 8080 9990 3306

# Set the default command to run on boot
# This will boot WildFly in the standalone mode and bind to all interface
CMD ["/opt/jboss/wildfly/wildfly-10.0.0.Final/bin/standalone.sh", "-b", "0.0.0.0", "-bmanagement", "0.0.0.0"]
