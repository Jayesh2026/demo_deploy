# Stage 1: Build Custom JRE using jlink
FROM eclipse-temurin:21-jdk-alpine AS jre-builder

RUN jlink --output /jre --verbose --strip-debug --compress=2 --no-header-files --no-man-pages \
    --add-modules java.base,jdk.net,java.sql,java.naming,java.desktop,java.management,java.security.jgss,java.instrument,jdk.unsupported,java.xml,java.scripting,java.net.http,java.logging,java.prefs,java.rmi,java.security.sasl,java.xml.crypto,jdk.crypto.ec,jdk.crypto.cryptoki,jdk.localedata,jdk.zipfs,java.transaction.xa,java.compiler,jdk.management,jdk.management.agent,jdk.httpserver,java.se \
    && apk add --no-cache binutils \
    && strip -p --strip-unneeded /jre/lib/server/libjvm.so

# Stage 2: Final Runtime Image
FROM alpine:3.19.1

# Standard Directory Structure
ENV DEMO=/opt/demo

ENV JAVA_HOME=/usr/lib/jvm/jre
ENV PATH=${JAVA_HOME}/bin:${PATH}

RUN apk update && apk add --no-cache bash dos2unix unzip curl

RUN adduser -S -G root -u 1001 -s /bin/bash bntsoft

COPY --from=jre-builder --chown=bntsoft:root /jre ${JAVA_HOME}

# COPY --chown=bntsoft:root build/libs/demo-0.0.1-SNAPSHOT.jar ${DEMO}/demo.jar
COPY --chown=bntsoft:root build/libs/*.jar ${DEMO}/

# Remove plain JAR if exists and rename executable JAR
RUN rm -f ${DEMO}/*-plain.jar \
    && mv ${DEMO}/*.jar ${DEMO}/app.jar 

RUN chmod -R 755 "$DEMO"

USER bntsoft

WORKDIR $DEMO

EXPOSE 8081

ENTRYPOINT ["java"]
CMD ["-jar", "/opt/demo/app.jar"]