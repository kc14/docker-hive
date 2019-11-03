FROM hadoop:cdh6.3.0

LABEL maintainer="Matteo Capitanio <matteo.capitanio@gmail.com>"
LABEL maintainer="kc14 <kemmer.consulting+kc14@gmail.com>"

USER root

# ENV HIVE_VER 3.1.2
ENV HIVE_VER 4.0.0-SNAPSHOT
ENV TEZ_VER 0.9.1

ENV HIVE_HOME /opt/hive
ENV HIVE_CONF_DIR ${HIVE_HOME}/conf
# ENV HADOOP_HOME /opt/hadoop
# ENV HADOOP_CONF_DIR /opt/hadoop/etc/hadoop
ENV HADOOP_HOME /usr/lib/hadoop
ENV HADOOP_CONF_DIR /etc/hadoop/conf
ENV HCAT_LOG_DIR /opt/hive/logs
ENV HCAT_PID_DIR /opt/hive/logs
ENV WEBHCAT_LOG_DIR /opt/hive/logs
ENV WEBHCAT_PID_DIR /opt/hive/logs

ENV PATH $HIVE_HOME/bin:$PATH

# Install needed packages
RUN yum clean all; \
    yum update -y; \
    yum install -y postgresql; \
    yum clean all

WORKDIR /Downloads

# Apache Hive
# RUN wget "http://it.apache.contactlab.it/hive/hive-${HIVE_VER}/apache-hive-${HIVE_VER}-bin.tar.gz"
COPY Downloads /Downloads

# This statement creates the HIVE_HOME dir
RUN tar -xvf "apache-hive-${HIVE_VER}-bin.tar.gz" ; \
    mv "apache-hive-${HIVE_VER}-bin" "${HIVE_HOME}"

RUN wget "https://jdbc.postgresql.org/download/postgresql-42.2.8.jar" -O "${HIVE_HOME}/lib/postgresql-42.2.8.jar"

RUN wget "http://it.apache.contactlab.it/tez/0.9.1/apache-tez-0.9.1-bin.tar.gz" ; \
    tar -xvf "apache-tez-0.9.1-bin.tar.gz"
RUN cp "apache-tez-0.9.1-bin"/tez*.jar "${HIVE_HOME}/lib/" ; \
    rm -rf "apache-tez-0.9.1-bin" ; \
    rm -f "apache-tez-0.9.1-bin.tar.gz"

COPY hive/ "${HIVE_HOME}/"
COPY ./etc /etc

# Needed for jdk > 8 ... but hive does only support jdk8
# COPY ./opt/hive/hcatalog/sbin/hcat_server.sh /opt/hive/hcatalog/sbin/
# COPY ./opt /opt

RUN chmod +x "${HIVE_HOME}"/bin/*.sh

RUN useradd -p $(echo "hive" | openssl passwd -1 -stdin) hive; \
    usermod -a -G hdfs hive;

EXPOSE 9083 10000 10002 50111

VOLUME ["/opt/hive/conf", "/opt/hive/logs"]

ENTRYPOINT ["supervisord", "-c", "/etc/supervisord.conf", "-n"]