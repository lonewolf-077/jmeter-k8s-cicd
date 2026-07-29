FROM alpine:3.15

# Install Java (JMeter ko chalane ke liye Java zaroori hai)
RUN apk add --no-cache openjdk11-jre tzdata curl unzip bash

# Apache JMeter 5.5 download aur install karna
RUN curl -L https://archive.apache.org/dist/jmeter/binaries/apache-jmeter-5.5.tgz > /tmp/jmeter.tgz && \
    tar -xzf /tmp/jmeter.tgz -C /opt && \
    rm /tmp/jmeter.tgz

# Environment variables set karna taaki JMeter command direct chal sake
ENV JMETER_HOME=/opt/apache-jmeter-5.5
ENV PATH=$JMETER_HOME/bin:$PATH

# Master aur Workers aapas mein baat kar sakein isliye ports open karna
EXPOSE 1099 50000