# Multi-stage build for Spring Boot application
FROM maven:3.9.6-eclipse-temurin-17 AS build

# Limit Maven memory during build
ARG MAVEN_OPTS=-Xmx512m
ENV MAVEN_OPTS=${MAVEN_OPTS}

# Set working directory
WORKDIR /app

# Copy pom.xml and download dependencies (for better caching)
COPY pom.xml .
RUN mvn dependency:go-offline -B

# Copy source code
COPY src ./src

# Build the application
RUN mvn clean package -DskipTests

# Runtime stage
FROM eclipse-temurin:17-jre-alpine

# Install health-check tooling and Unicode fonts used by the receipt shaper.
# The receipt renderer selects faces by glyph coverage, so names can mix Tamil,
# other Indic scripts, Arabic, CJK, Cyrillic and Latin without hard-coded data.
RUN apk add --no-cache curl fontconfig font-noto font-noto-extra font-noto-cjk pango-tools

COPY --from=build /app/src/main/resources/fonts/NotoSansTamil-Regular.ttf /usr/share/fonts/noto/NotoSansTamil-Regular.ttf
RUN fc-cache -f

# Create app user for security
RUN addgroup -g 1001 -S appgroup && \
    adduser -u 1001 -S appuser -G appgroup

# Set working directory
WORKDIR /app

# Copy the JAR file from build stage
COPY --from=build /app/target/*.jar app.jar

# Create uploads directory structure and set permissions
RUN mkdir -p /app/uploads/products/master && \
    mkdir -p /app/uploads/products/shop && \
    mkdir -p /app/uploads/documents/shops && \
    chown -R appuser:appgroup /app

# Switch to non-root user
USER appuser

# Expose port
EXPOSE 8080

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=60s --retries=3 \
    CMD curl -f http://localhost:8080/actuator/health || exit 1

# Run the application
ENTRYPOINT ["sh", "-c", "java $JAVA_OPTS -jar /app/app.jar"]
