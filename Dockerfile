ARG BASE_IMAGE=ghcr.io/declue/docker_ubuntu:20.04
FROM $BASE_IMAGE

LABEL MAINTAINER bkperio@gmail.com

ARG DEBIAN_FRONTEND=noninteractive
ARG CONFLUENCE_VERSION
ARG DOWNLOAD_URL=https://product-downloads.atlassian.com/software/confluence/downloads/atlassian-confluence-$CONFLUENCE_VERSION.tar.gz
# preapre
RUN apt-get update && apt-get install -y wget openjdk-11-jdk tini python3 python3-pip

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

ENV JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64
# install confluence
RUN groupadd --gid ${RUN_GID} ${RUN_GROUP} \
    && useradd --uid ${RUN_UID} --gid ${RUN_GID} --home-dir ${CONFLUENCE_HOME} --shell /bin/bash ${RUN_USER}
RUN echo PATH=$PATH > /etc/environment \
    && mkdir -p                                     ${CONFLUENCE_INSTALL_DIR}
RUN curl -L --silent                             ${DOWNLOAD_URL} | tar -xz --strip-components=1 -C "${CONFLUENCE_INSTALL_DIR}" 
RUN    chmod -R "u=rwX,g=rX,o=rX"                   ${CONFLUENCE_INSTALL_DIR}/ \
    && chown -R root.                               ${CONFLUENCE_INSTALL_DIR}/ \
    && chown -R ${RUN_USER}:${RUN_GROUP}            ${CONFLUENCE_INSTALL_DIR}/logs \
    && chown -R ${RUN_USER}:${RUN_GROUP}            ${CONFLUENCE_INSTALL_DIR}/temp \
    && chown -R ${RUN_USER}:${RUN_GROUP}            ${CONFLUENCE_INSTALL_DIR}/work \
    && chown -R ${RUN_USER}:${RUN_GROUP}            ${CONFLUENCE_HOME} 
RUN sed -i -e 's/-Xms\([0-9]\+[kmg]\) -Xmx\([0-9]\+[kmg]\)/-Xms\${JVM_MINIMUM_MEMORY:=\1} -Xmx\${JVM_MAXIMUM_MEMORY:=\2} -Dconfluence.home=\${CONFLUENCE_HOME}/g' ${CONFLUENCE_INSTALL_DIR}/bin/setenv.sh \
    && sed -i -e 's/-XX:ReservedCodeCacheSize=\([0-9]\+[kmg]\)/-XX:ReservedCodeCacheSize=${JVM_RESERVED_CODE_CACHE_SIZE:=\1}/g' ${CONFLUENCE_INSTALL_DIR}/bin/setenv.sh \
    && sed -i -e 's/export CATALINA_OPTS/CATALINA_OPTS="\${CATALINA_OPTS} \${JVM_SUPPORT_RECOMMENDED_ARGS} -DConfluenceHomeLogAppender.disabled=${CONFLUENCE_LOG_STDOUT}"\n\nexport CATALINA_OPTS/g' ${CONFLUENCE_INSTALL_DIR}/bin/setenv.sh \
    \
    && mkdir -p $JAVA_HOME/lib/fonts/fallback/ \
    && ln -sf /usr/share/fonts/truetype/noto/* $JAVA_HOME/lib/fonts/fallback/

VOLUME ["${CONFLUENCE_HOME}"]


COPY entrypoint.py \
     shutdown-wait.sh \
     entrypoint_helpers.py /
COPY config/*                                       /opt/atlassian/etc/
#COPY shared-components/support                      /opt/atlassian/support
 
#
# install python package 
RUN pip install jinja2

# hangul font
RUN curl -o /tmp/font-install.sh https://gist.githubusercontent.com/lesstif/644b29b9fa830ec157a476707ffc4e4d/raw 
RUN bash /tmp/font-install.sh $CONFLUENCE_INSTALL_DIR
 
