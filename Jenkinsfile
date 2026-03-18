pipeline {
    agent any

    environment {
        COMPOSE_FILE        = "docker-compose.yml"
        IMAGE_NAME          = "myapp"
        TRIVY_REPORT_JSON   = "trivy-report.json"
        TRIVY_REPORT_CSV    = "trivy-report.csv"
        SEVERITY_FILTER     = "LOW,MEDIUM,CRITICAL"
    }

    stages {

        // ─────────────────────────────────────────────
        // STAGE 0 — Debug environnement (IMPORTANT)
        // ─────────────────────────────────────────────
        stage('Debug Environment') {
            steps {
                echo "========== [DEBUG] Vérification environnement =========="
                sh '''
                which docker || true
                docker version || true
                docker compose version || true
                '''
            }
        }

        // ─────────────────────────────────────────────
        // STAGE 1 — Pull & Build
        // ─────────────────────────────────────────────
        stage('Pull & Build Docker Image') {
            steps {
                echo "========== [STAGE 1] Pull & Build =========="

                sh '''
                set -e

                echo "🔄 Pull images..."
                docker compose -f docker-compose.yml pull --ignore-pull-failures

                echo "🏗️ Build images..."
                docker compose -f docker-compose.yml build --no-cache

                echo "✅ Build terminé"
                '''
            }
        }

        // ─────────────────────────────────────────────
        // STAGE 2 — Trivy Scan
        // ─────────────────────────────────────────────
        stage('Security Scan with Trivy') {
            steps {
                echo "========== [STAGE 2] Trivy Security Scan =========="

                sh '''
                set -e

                trivy --version

                echo "⬇️ Mise à jour DB Trivy..."
                trivy image --download-db-only

                echo "🔍 Scan en cours..."
                trivy image \
                    --exit-code 0 \
                    --severity ${SEVERITY_FILTER} \
                    --format json \
                    --output ${TRIVY_REPORT_JSON} \
                    ${IMAGE_NAME}

                echo "✅ Scan terminé"
                '''
            }
        }

        // ─────────────────────────────────────────────
        // STAGE 3 — JSON → CSV
        // ─────────────────────────────────────────────
        stage('Generate CSV Security Report') {
            steps {
                echo "========== [STAGE 3] Génération CSV =========="

                sh '''
                python3 - <<EOF
import json, csv
from collections import Counter

with open("${TRIVY_REPORT_JSON}") as f:
    data = json.load(f)

rows = []
for result in data.get("Results", []):
    for vuln in result.get("Vulnerabilities") or []:
        rows.append({
            "Target": result.get("Target"),
            "Severity": vuln.get("Severity"),
            "ID": vuln.get("VulnerabilityID"),
            "Package": vuln.get("PkgName"),
            "Installed": vuln.get("InstalledVersion"),
            "Fixed": vuln.get("FixedVersion"),
        })

severity_order = {"CRITICAL":0,"HIGH":1,"MEDIUM":2,"LOW":3}
rows.sort(key=lambda x: severity_order.get(x["Severity"], 99))

with open("${TRIVY_REPORT_CSV}", "w", newline="") as f:
    writer = csv.DictWriter(f, fieldnames=rows[0].keys() if rows else [])
    writer.writeheader()
    writer.writerows(rows)

counts = Counter(r["Severity"] for r in rows)
print("\\n📊 Résumé:")
for k,v in counts.items():
    print(f"{k}: {v}")
print("TOTAL:", len(rows))
EOF
                '''
            }

            post {
                always {
                    archiveArtifacts artifacts: "${TRIVY_REPORT_CSV}, ${TRIVY_REPORT_JSON}",
                                     allowEmptyArchive: true
                }
            }
        }
    }

    // ─────────────────────────────────────────────
    // POST
    // ─────────────────────────────────────────────
    post {
        success {
            echo "🎉 Pipeline terminé avec succès !"
        }
        failure {
            echo "❌ Pipeline en échec."
        }
        always {
            echo "🧹 Nettoyage Docker..."

            sh '''
            docker compose -f docker-compose.yml down --remove-orphans || true
            '''
        }
    }
}
