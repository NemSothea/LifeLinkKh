# syntax=docker/dockerfile:1
# Multi-stage: the Maven toolchain never reaches the runtime image.
# Local development only — see docs/fullstack/specs/foundation/infra-docker.md.

FROM maven:3.9-eclipse-temurin-21 AS build
WORKDIR /build

# Two separate concerns, and they need two different mechanisms.
#
# 1. Layer order. pom.xml is copied before src/ so editing a .java file does not
#    invalidate the dependency step. That part was always here and always worked.
#
# 2. The cache mount. Layer order does nothing when pom.xml itself changes — the
#    layer is invalidated, and without somewhere to keep the artifacts the build
#    re-downloads the entire tree from Maven Central to add one dependency. That
#    cost ~10 minutes to add springdoc. --mount=type=cache keeps ~/.m2 outside the
#    image and outside layer invalidation, so a pom change fetches only what is
#    actually new.
#
# The cache is not baked into any layer, so every step that resolves dependencies
# has to mount it — including `package` below. Miss one and it downloads twice.
COPY pom.xml .
RUN --mount=type=cache,target=/root/.m2 mvn -B -q dependency:go-offline

COPY src ./src
RUN --mount=type=cache,target=/root/.m2 mvn -B -DskipTests package

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
