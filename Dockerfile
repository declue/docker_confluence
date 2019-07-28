FROM declue/ubuntu:18.04

MAINTAINER bkperio@gmail.com

# install defualt package
ARG DEBIAN_FRONTEND=noninteractive

RUN apt-get update
RUN apt-get install -y wget
RUN apt-get install -y openjdk-8-jre
 
# install confluence
ARG CONFLUENCE_VERSION=6.15.7
ARG CONFLUENCE_INSTALL_PATH=/opt/confluence
ARG CONFLUENCE_HOME_PATH=/var/atlassian/confluence
ARG CONFLUENCE_DOWNLOAD_URL=http://www.atlassian.com/software/confluence/downloads/binary
ARG CONFLUENCE_DOWNLOAD_FILE=atlassian-confluence-${CONFLUENCE_VERSION}.tar.gz

RUN mkdir -p $CONFLUENCE_INSTALL_PATH
RUN wget -O $CONFLUENCE_INSTALL_PATH/$CONFLUENCE_DOWNLOAD_FILE $CONFLUENCE_DOWNLOAD_URL/$CONFLUENCE_DOWNLOAD_FILE
RUN tar xzf $CONFLUENCE_INSTALL_PATH/$CONFLUENCE_DOWNLOAD_FILE  --strip-components=1 -C ${CONFLUENCE_INSTALL_PATH} 
RUN echo "confluence.home=${CONFLUENCE_HOME_PATH}" > ${CONFLUENCE_INSTALL_PATH}/confluence/WEB-INF/classes/confluence-init.properties

# install mysql-jdbc driver
ARG MYSQL_VERSION=5.1.47
ARG MYSQL_DOWNLOAD_URL=https://dev.mysql.com/get/Downloads/Connector-J
ARG MYSQL_DOWNLOAD_FILE=mysql-connector-java-$MYSQL_VERSION.tar.gz
ARG MYSQL_CONNECTOR_FILE=mysql-connector-java-$MYSQL_VERSION-bin.jar

RUN wget -O $CONFLUENCE_INSTALL_PATH/$MYSQL_DOWNLOAD_FILE $MYSQL_DOWNLOAD_URL/$MYSQL_DOWNLOAD_FILE
RUN tar xzf $CONFLUENCE_INSTALL_PATH/$MYSQL_DOWNLOAD_FILE --strip=1
RUN mv $MYSQL_CONNECTOR_FILE  $CONFLUENCE_INSTALL_PATH/lib/$MYSQL_CONNECTOR_FILE

# set entrypoint
COPY entrypoint.sh $CONFLUENCE_INSTALL_PATH/entrypoint.sh
RUN chmod +x $CONFLUENCE_INSTALL_PATH/entrypoint.sh

# start confluence
WORKDIR $CONFLUENCE_HOME_PATH
EXPOSE 8090

CMD ["/opt/confluence/bin/start-confluence.sh", "-fg"]
ENTRYPOINT ["/opt/confluence/entrypoint.sh"]

