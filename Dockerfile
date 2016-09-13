# Use latest jboss/base-jdk:7 image as the base
FROM ubuntu:16.04

USER root

# Set the WILDFLY_VERSION env variable
ENV WILDFLY_VERSION 10.0.0.Final
ENV JBOSS_HOME /opt/jboss/wildfly/wildfly-$WILDFLY_VERSION

RUN  apt-get update \
     && apt-get install -y curl

RUN  apt-get update \
  && apt-get install -y wget
  
RUN  apt-get update \
  && sudo -E apt-get install -q -y mysql-server

RUN mysqladmin -u root password root
RUN mysql -uroot -e "create database test;"

RUN  mkdir /usr/local/java \
  && cd /usr/local/java  \
  && wget --no-check-certificate --no-cookies --header "Cookie: oraclelicense=accept-securebackup-cookie" \
     http://download.oracle.com/otn-pub/java/jdk/8u77-b03/jdk-8u77-linux-x64.tar.gz \
  && tar -xvzf jdk-8u77-linux-x64.tar.gz \
  && rm jdk-8u77-linux-x64.tar.gz

ENV JAVA_HOME=/usr/local/java/jdk1.8.0_77
ENV PATH=$PATH:/usr/local/java/jdk1.8.0_77/bin
     
RUN mkdir -p /opt/jboss/wildfly     
     
# Add the WildFly distribution to /opt, and make wildfly the owner of the extracted tar content
# Make sure the distribution is available from a well-known place
RUN cd $HOME && curl http://download.jboss.org/wildfly/$WILDFLY_VERSION/wildfly-$WILDFLY_VERSION.tar.gz | tar zx && mv $HOME/wildfly-$WILDFLY_VERSION /opt/jboss/wildfly

# Set the JBOSS_HOME env variable

# Expose the ports we're interested in
EXPOSE 8080 9990

ADD customization /opt/jboss/wildfly/wildfly-$WILDFLY_VERSION/customization/
COPY customization/mysql-connector-java-5.1.22-bin.jar /opt/jboss/wildfly/wildfly-$WILDFLY_VERSION/customization/
#ADD standalone-full.xml /opt/jboss/wildfly/wildfly-$WILDFLY_VERSION/standalone/configuration/

RUN cd /opt/jboss/wildfly/wildfly-$WILDFLY_VERSION/customization/ && ls

RUN /opt/jboss/wildfly/wildfly-$WILDFLY_VERSION/bin/add-user.sh admin admin --silent

USER root
RUN chmod +x /opt/jboss/wildfly/wildfly-$WILDFLY_VERSION/customization/execute.sh
RUN /opt/jboss/wildfly/wildfly-$WILDFLY_VERSION/customization/execute.sh

RUN rm -rf /opt/jboss/wildfly/wildfly-$WILDFLY_VERSION/standalone/configuration/standalone_xml_history/current

RUN chmod +x /opt/jboss/wildfly/wildfly-$WILDFLY_VERSION/bin/standalone.sh

# Set the default command to run on boot
# This will boot WildFly in the standalone mode and bind to all interface
CMD ["/opt/jboss/wildfly/wildfly-10.0.0.Final/bin/standalone.sh", "-b", "0.0.0.0", "-bmanagement", "0.0.0.0"]
