# Use latest jboss/base-jdk:7 image as the base
FROM mysql:latest

# Set the WILDFLY_VERSION env variable
ENV WILDFLY_VERSION 10.0.0.Final
ENV JBOSS_HOME /opt/jboss/wildfly

ENV MYSQL_ROOT_PASSWORD root
ENV MYSQL_DATABASE test

RUN  apt-get update \
     && apt-get install -y curl

     
RUN sudo mkdir /opt/jboss/wildfly     
     
# Add the WildFly distribution to /opt, and make wildfly the owner of the extracted tar content
# Make sure the distribution is available from a well-known place
RUN cd $HOME && curl http://download.jboss.org/wildfly/$WILDFLY_VERSION/wildfly-$WILDFLY_VERSION.tar.gz | tar zx && mv $HOME/wildfly-$WILDFLY_VERSION /opt/jboss/wildfly

# Set the JBOSS_HOME env variable

# Expose the ports we're interested in
EXPOSE 8080 9990

ADD customization /opt/jboss/wildfly/customization/
ADD customization/mysql-connector-java-5.1.22-bin.jar /opt/jboss/mysql-connector-java-5.1.22-bin.jar
#ADD standalone-full.xml /opt/jboss/wildfly/standalone/configuration/

RUN /opt/jboss/wildfly/bin/add-user.sh admin admin --silent

USER root
RUN chmod +x /opt/jboss/wildfly/customization/execute.sh
RUN /opt/jboss/wildfly/customization/execute.sh

RUN rm -rf /opt/jboss/wildfly/standalone/configuration/standalone_xml_history/current

RUN chmod +x /opt/jboss/wildfly/bin/standalone.sh

# Set the default command to run on boot
# This will boot WildFly in the standalone mode and bind to all interface
CMD ["/opt/jboss/wildfly/bin/standalone.sh", "-b", "0.0.0.0", "-bmanagement", "0.0.0.0"]
