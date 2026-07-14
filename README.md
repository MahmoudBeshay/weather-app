# Weather App (Spring Boot)

A Spring Boot web app that shows current weather for any city, using the
free [wttr.in](https://wttr.in) service — no API key required.

## Prerequisites

- JDK 17 or newer. The project includes the Maven Wrapper, so a separate
  Maven install is not required.

## Quickstart

```bash
./mvnw spring-boot:run       # macOS/Linux
mvnw.cmd spring-boot:run     # Windows
```

Open http://localhost:5000, type a city name, and search.

A health check is available at http://localhost:5000/actuator/health
(via Spring Boot Actuator).

## Testing

```bash
./mvnw test          # macOS/Linux
mvnw.cmd test         # Windows
```

This runs the JUnit 5 test suite (`src/test/java`) and, via the JaCoCo
Maven plugin, writes a coverage report to
`target/site/jacoco/jacoco.xml`.

### SonarQube

`sonar-project.properties` points at `src/main/java`, `src/test/java`,
and the JaCoCo report path. After running `./mvnw test` to generate
fresh coverage data, run `sonar-scanner` (installed separately) from the
project root and it will pick up the config automatically.

## Packaging & Containerization

This project doesn't ship a Dockerfile, but if you want to containerize
it, here's a minimal multi-stage example you can drop into a
`Dockerfile`:

```dockerfile
FROM maven:3-eclipse-temurin-17 AS build
WORKDIR /app
COPY pom.xml .
COPY src ./src
RUN mvn -q package -DskipTests

FROM eclipse-temurin:17-jre
WORKDIR /app
COPY --from=build /app/target/*.jar app.jar
EXPOSE 5000
CMD ["java", "-jar", "app.jar"]
```

Build and run it with:

```bash
docker build -t weather-app .
docker run -p 5000:5000 weather-app
```

### Alternative packaging routes

- **`./mvnw package`** — produces an executable jar at `target/*.jar`
  that runs anywhere a JDK is installed (`java -jar target/*.jar`).
- **`./mvnw spring-boot:build-image`** — builds an OCI container image
  directly via Spring Boot's Cloud Native Buildpacks support, without
  needing a hand-written Dockerfile at all.
