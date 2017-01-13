FROM maven:3-jdk-8

RUN apt-get update && apt-get install -y git
RUN cd /usr/local && git clone https://github.com/HW-RajKD/OcrTiffTesseractWebservice.git

RUN mkdir -p /usr/src/app
WORKDIR /usr/src/app
ADD . /usr/src/app
#RUN mvn clean install -Dtest=TestWebService
RUN cd /usr/local/OcrTiffTesseractWebservice && mvn clean install -Dtest=TestWebService
FROM tomcat:8.0-jre8
MAINTAINER "RAJ KUMAR DUBEY" (rajkumar.dubey@heavywater.solutions)
# ADD /usr/local/OcrTiffTesseractWebservice/target/OcrTiffTesseractWebservice.war /usr/local/tomcat/webapps/
