# Dockerfile for Java Webapp with maven and tomcat

# Step-1 : Define base image and maintainer
FROM phusion/baseimage:0.9.17
MAINTAINER RAJ KUMAR DUBEY (rajkumar.dubey@heavywater.solutions)

# Step-2 : Update the package repository
RUN echo "deb http://archive.ubuntu.com/ubuntu trusty main universe" > /etc/apt/sources.list
RUN apt-get -y update

# Step-3 : Install python-software-properties - This enables add-apt-repository for use later in the process.
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y -q python-software-properties software-properties-common

# Step-4(a) : Install Oracle Java 8
ENV JAVA_VER 8
ENV JAVA_HOME /usr/lib/jvm/java-8-oracle
RUN echo 'deb http://ppa.launchpad.net/webupd8team/java/ubuntu trusty main' >> /etc/apt/sources.list && \
    echo 'deb-src http://ppa.launchpad.net/webupd8team/java/ubuntu trusty main' >> /etc/apt/sources.list && \
    apt-key adv --keyserver keyserver.ubuntu.com --recv-keys C2518248EEA14886 && \
    apt-get update && \
    echo oracle-java${JAVA_VER}-installer shared/accepted-oracle-license-v1-1 select true | sudo /usr/bin/debconf-set-selections && \
    apt-get install -y --force-yes --no-install-recommends oracle-java${JAVA_VER}-installer oracle-java${JAVA_VER}-set-default && \
    apt-get clean && \
    rm -rf /var/cache/oracle-jdk${JAVA_VER}-installer

# Step-4(b) : Set Oracle Java as the default Java
RUN update-java-alternatives -s java-8-oracle
RUN echo "export JAVA_HOME=/usr/lib/jvm/java-8-oracle" >> ~/.bashrc

# Step-5(a) : Install Tomcat
ENV TOMCAT_MAJOR_VERSION 8
ENV TOMCAT_MINOR_VERSION 8.0.23
ENV CATALINA_HOME /usr/local/tomcat
RUN apt-get update && \
    apt-get install -yq --no-install-recommends wget pwgen ca-certificates && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*
	
RUN wget -q https://archive.apache.org/dist/tomcat/tomcat-${TOMCAT_MAJOR_VERSION}/v${TOMCAT_MINOR_VERSION}/bin/apache-tomcat-${TOMCAT_MINOR_VERSION}.tar.gz && \
	wget -qO- https://archive.apache.org/dist/tomcat/tomcat-${TOMCAT_MAJOR_VERSION}/v${TOMCAT_MINOR_VERSION}/bin/apache-tomcat-${TOMCAT_MINOR_VERSION}.tar.gz.md5 | md5sum -c - && \
	tar zxf apache-tomcat-*.tar.gz && \
 	rm apache-tomcat-*.tar.gz && \
 	mv apache-tomcat* $CATALINA_HOME
	
# Step-5(b) : Create Tomcat admin user	
ADD create_tomcat_admin_user.sh /create_tomcat_admin_user.sh
RUN mkdir /etc/service/tomcat
ADD run.sh /etc/service/tomcat/run
RUN chmod +x /*.sh
RUN chmod +x /etc/service/tomcat/run

RUN ls /usr/local/
# Step-6 : Install Git
RUN apt-get update && apt-get install -y git

# Step-7 : Install Maven
ENV MAVEN_VERSION 3.3.9	

RUN mkdir -p /usr/share/maven \
  && curl -fsSL http://apache.osuosl.org/maven/maven-3/$MAVEN_VERSION/binaries/apache-maven-$MAVEN_VERSION-bin.tar.gz \
    | tar -xzC /usr/share/maven --strip-components=1 \
  && ln -s /usr/share/maven/bin/mvn /usr/bin/mvn

ENV MAVEN_HOME /usr/share/maven
VOLUME /root/.m2

# Step-8 : Get the project from github
RUN cd /usr/local && git clone https://github.com/HW-RajKD/OcrTiffTesseractWebservice.git

# Step-9 : Build the project
RUN cd /usr/local/OcrTiffTesseractWebservice && $MAVEN_HOME/bin/mvn clean install -Dtest=TestWebService

# Step-10 : Deploy the war in tomcat
RUN rm -rf ${CATALINA_HOME}/webapps/*
RUN cp /usr/local/OcrTiffTesseractWebservice/target/OcrTiffTesseractWebservice.war $CATALINA_HOME/webapps/

# Forward HTTP ports
EXPOSE 80 8080

CMD ["/usr/local/tomcat/bin/catalina.sh"]
