ARG BASE_IMAGE=ghcr.io/declue/docker_ubuntu:20.04
FROM $BASE_IMAGE

LABEL MAINTAINER bkperio@gmail.com

ARG DEBIAN_FRONTEND=noninteractive
ARG CONFLUENCE_VERSION=8.0.2
ARG DOWNLOAD_URL=https://product-downloads.atlassian.com/software/confluence/downloads/atlassian-confluence-${CONFLUENCE_VERSION}.tar.gz

# preapre
RUN apt-get update && apt-get install -y wget openjdk-11-jre tini python3 python3-pip

ENV APP_NAME                                        confluence
ENV RUN_USER                                        confluence
ENV RUN_GROUP                                       confluence
ENV RUN_UID                                         2002
ENV RUN_GID                                         2002
ENV CONFLUENCE_HOME                                 /var/atlassian/application-data/confluence
ENV CONFLUENCE_INSTALL_DIR                          /opt/atlassian/confluence
ENV CONFLUENCE_LOG_STDOUT                           false
ENV CONFLUENCE_VERSION				    ${CONFLUENCE_VERSION}

WORKDIR $CONFLUENCE_HOME

EXPOSE 8090
EXPOSE 8091

CMD ["/entrypoint.py"]
ENTRYPOINT ["/usr/bin/tini", "--"]

# install confluence
RUN groupadd --gid ${RUN_GID} ${RUN_GROUP} \
    && useradd --uid ${RUN_UID} --gid ${RUN_GID} --home-dir ${CONFLUENCE_HOME} --shell /bin/bash ${RUN_USER} \
    && echo PATH=$PATH > /etc/environment \
    \
    && mkdir -p                                     ${CONFLUENCE_INSTALL_DIR} \
    && curl -L --silent                             ${DOWNLOAD_URL} | tar -xz --strip-components=1 -C "${CONFLUENCE_INSTALL_DIR}" \
    && chmod -R "u=rwX,g=rX,o=rX"                   ${CONFLUENCE_INSTALL_DIR}/ \
    && chown -R root.                               ${CONFLUENCE_INSTALL_DIR}/ \
    && chown -R ${RUN_USER}:${RUN_GROUP}            ${CONFLUENCE_INSTALL_DIR}/logs \
    && chown -R ${RUN_USER}:${RUN_GROUP}            ${CONFLUENCE_INSTALL_DIR}/temp \
    && chown -R ${RUN_USER}:${RUN_GROUP}            ${CONFLUENCE_INSTALL_DIR}/work \
    && chown -R ${RUN_USER}:${RUN_GROUP}            ${CONFLUENCE_HOME} \
    \
    && sed -i -e 's/-Xms\([0-9]\+[kmg]\) -Xmx\([0-9]\+[kmg]\)/-Xms\${JVM_MINIMUM_MEMORY:=\1} -Xmx\${JVM_MAXIMUM_MEMORY:=\2} -Dconfluence.home=\${CONFLUENCE_HOME}/g' ${CONFLUENCE_INSTALL_DIR}/bin/setenv.sh \
    && sed -i -e 's/-XX:ReservedCodeCacheSize=\([0-9]\+[kmg]\)/-XX:ReservedCodeCacheSize=${JVM_RESERVED_CODE_CACHE_SIZE:=\1}/g' ${CONFLUENCE_INSTALL_DIR}/bin/setenv.sh \
    && sed -i -e 's/export CATALINA_OPTS/CATALINA_OPTS="\${CATALINA_OPTS} \${JVM_SUPPORT_RECOMMENDED_ARGS} -DConfluenceHomeLogAppender.disabled=${CONFLUENCE_LOG_STDOUT}"\n\nexport CATALINA_OPTS/g' ${CONFLUENCE_INSTALL_DIR}/bin/setenv.sh \
    \
    && mkdir -p /opt/java/openjdk/lib/fonts/fallback/ \
    && ln -sf /usr/share/fonts/truetype/noto/* /opt/java/openjdk/lib/fonts/fallback/

VOLUME ["${CONFLUENCE_HOME}"]


COPY entrypoint.py \
     shutdown-wait.sh \
     entrypoint_helpers.py /
COPY config/*                                       /opt/atlassian/etc/
#COPY shared-components/support                      /opt/atlassian/support
 
# install mysql-jdbc driver
ARG MYSQL_VERSION=8.0.32
ARG MYSQL_DOWNLOAD_URL=https://cdn.mysql.com/Downloads/Connector-J
ARG MYSQL_DOWNLOAD_FILE=mysql-connector-j-$MYSQL_VERSION.tar.gz
ARG MYSQL_CONNECTOR_FILE=mysql-connector-j-$MYSQL_VERSION.jar

RUN wget -O $CONFLUENCE_INSTALL_DIR/$MYSQL_DOWNLOAD_FILE $MYSQL_DOWNLOAD_URL/$MYSQL_DOWNLOAD_FILE && \
tar xzf $CONFLUENCE_INSTALL_DIR/$MYSQL_DOWNLOAD_FILE --strip=1 && \
mv $MYSQL_CONNECTOR_FILE  ${CONFLUENCE_INSTALL_DIR}/lib/${MYSQL_CONNECTOR_FILE}


# install python package 
RUN pip install jinja2
