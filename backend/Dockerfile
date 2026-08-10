# Multi-stage: the Maven toolchain never reaches the runtime image.
# Local development only — see docs/fullstack/specs/foundation/infra-docker.md.

FROM maven:3.9-eclipse-temurin-21 AS build
WORKDIR /build
# Dependencies first, so a source-only change does not re-download the world.
COPY pom.xml .
RUN mvn -B -q dependency:go-offline
COPY src ./src
RUN mvn -B -DskipTests package

FROM eclipse-temurin:21-jre AS runtime
WORKDIR /app
# curl is required by the compose healthcheck, which runs inside this container.
RUN apt-get update \
    && apt-get install -y --no-install-recommends curl \
    && rm -rf /var/lib/apt/lists/*
# Non-root: a container running as root is a privilege-escalation path out of a
# compromised process (ASVS configuration controls, ADR 0005).
RUN useradd --system --uid 10001 --shell /usr/sbin/nologin lifelink
COPY --from=build /build/target/lifelink-api-*.jar app.jar
USER lifelink
EXPOSE 8080
ENTRYPOINT ["java", "-jar", "/app/app.jar"]
