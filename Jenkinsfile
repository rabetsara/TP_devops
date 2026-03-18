pipeline {
    agent any

    environment {
        COMPOSE_FILE      = "docker-compose.yml"
        IMAGE_NAME        = "myapp:latest"
        TRIVY_REPORT_JSON = "trivy-report.json"
        TRIVY_REPORT_CSV  = "trivy-report.csv"
        SEVERITY_FILTER   = "LOW,MEDIUM,CRITICAL"
    }

    stages {

        // ─────────────────────────────────────────────
        // DEBUG ENV
        // ─────────────────────────────────────────────
        stage('Debug Environment') {
            steps {
                sh '''
                echo "=== DEBUG DOCKER ==="
                docker version || true
                docker compose version || true
                ls -la
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
                set +e   # ⚠️ ne casse pas le pipeline

                echo "🔄 Pull images..."
                docker compose -f docker-compose.yml pull --ignore-pull-failures || true

                echo "🏗️ Build images..."
                docker compose -f docker-compose.yml build --no-cache || true

                echo "📦 Images disponibles:"
                docker images | grep myapp || true
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

                if ! command -v trivy > /dev/null 2>&1; then
                    echo "⬇️ Installation Trivy..."
                    curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh \
                        | sh -s -- -b /usr/local/bin
                fi

                trivy --version

                echo "🔍 Scan image..."
                trivy image \
                    --exit-code 0 \
                    --severity ${SEVERITY_FILTER} \
                    --format json \
                    --output ${TRIVY_REPORT_JSON} \
                    --timeout 10m \
                    ${IMAGE_NAME} || true
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
python3 - << 'PYEOF'
import json, csv
from collections import Counter

try:
    with open("trivy-report.json") as f:
        data = json.load(f)
except:
    print("⚠️ Aucun rapport JSON trouvé")
    data = {}

rows = []
for result in data.get("Results", []):
    for vuln in result.get("Vulnerabilities") or []:
        rows.append({
            "Target": result.get("Target"),
            "Severity": vuln.get("Severity"),
            "ID": vuln.get("VulnerabilityID"),
            "Package": vuln.get("PkgName"),
        })

if rows:
    with open("trivy-report.csv", "w", newline="") as f:
        writer = csv.DictWriter(f, fieldnames=rows[0].keys())
        writer.writeheader()
        writer.writerows(rows)

    counts = Counter(r["Severity"] for r in rows)
    print("📊 Résumé:")
    for k,v in counts.items():
        print(f"{k}: {v}")
else:
    print("⚠️ Aucun résultat à écrire")
PYEOF
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
            echo "❌ Pipeline en échec (mais tolérance activée)"
        }
        always {
            echo "🧹 Nettoyage Docker..."

            sh '''
            docker compose -f docker-compose.yml down --remove-orphans || true
            '''
        }
    }
}
