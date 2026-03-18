# ── Build stage ──────────────────────────────────────────────────
FROM maven:3.9-eclipse-temurin-17 AS builder

WORKDIR /app

# Copier uniquement pom.xml si présent (cache des dépendances)
COPY pom.xml ./ 2>/dev/null || true

# Télécharger les dépendances (si pom.xml existe)
RUN if [ -f pom.xml ]; then mvn dependency:go-offline -q; fi

# Copier le reste du projet
COPY . .

# Build si projet Maven valide
RUN if [ -f pom.xml ]; then \
        mvn package -DskipTests -q; \
    else \
        echo "⚠️ Aucun projet Maven détecté, création d’un JAR dummy"; \
        mkdir -p target && echo "Fake App" > target/app.jar; \
    fi


# ── Runtime stage ────────────────────────────────────────────────
FROM eclipse-temurin:17-jre-alpine

WORKDIR /app

# Sécurité : utilisateur non-root
RUN addgroup -S appgroup && adduser -S appuser -G appgroup

# Copier le JAR (réel ou dummy)
COPY --from=builder /app/target/*.jar app.jar

USER appuser

EXPOSE 8080

ENTRYPOINT ["java", "-jar", "app.jar"]
