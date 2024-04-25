FROM openjdk:17-jdk-alpine

ARG JAR_FILE=target/sample-crd-jar-with-dependencies.jar
ADD ${JAR_FILE} app.jar

ENTRYPOINT ["java","-jar","/app.jar"]