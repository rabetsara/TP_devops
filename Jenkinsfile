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
        // STAGE 1 — Pull & Build via Docker Compose
        // ─────────────────────────────────────────────
        stage('Pull & Build Docker Image') {
            steps {
                echo "========== [STAGE 1] Pull & Build =========="

                // Pull les images de base déclarées dans le compose
                sh "docker-compose -f ${COMPOSE_FILE} pull --ignore-pull-failures"

                // Build toutes les images définies dans le compose
                sh "docker-compose -f ${COMPOSE_FILE} build --no-cache"

                echo "✅ Images Docker construites avec succès."
            }
        }

        // ─────────────────────────────────────────────
        // STAGE 2 — Scan de sécurité Trivy
        // ─────────────────────────────────────────────
        stage('Security Scan with Trivy') {
            steps {
                echo "========== [STAGE 2] Trivy Security Scan =========="

                // Vérification que Trivy est disponible
                sh "trivy --version"

                // Mise à jour de la base de données de vulnérabilités
                sh "trivy image --download-db-only"

                // Scan de l'image et export en JSON (source pour la conversion CSV)
                sh """
                    trivy image \
                        --exit-code 0 \
                        --severity ${SEVERITY_FILTER} \
                        --format json \
                        --output ${TRIVY_REPORT_JSON} \
                        ${IMAGE_NAME}
                """

                echo "✅ Scan Trivy terminé — rapport JSON généré : ${TRIVY_REPORT_JSON}"
            }
        }

        // ─────────────────────────────────────────────
        // STAGE 3 — Génération du rapport CSV
        // ─────────────────────────────────────────────
        stage('Generate CSV Security Report') {
            steps {
                echo "========== [STAGE 3] Génération du rapport CSV =========="

                // Conversion du JSON Trivy → CSV structuré (LOW / MEDIUM / CRITICAL)
                sh """
                    python3 -c "
import json, csv, sys

with open('${TRIVY_REPORT_JSON}', 'r') as f:
    data = json.load(f)

rows = []
for result in data.get('Results', []):
    target   = result.get('Target', 'N/A')
    pkg_type = result.get('Type', 'N/A')
    for vuln in result.get('Vulnerabilities') or []:
        rows.append({
            'Target'           : target,
            'PackageType'      : pkg_type,
            'VulnerabilityID'  : vuln.get('VulnerabilityID', 'N/A'),
            'Severity'         : vuln.get('Severity', 'N/A'),
            'PackageName'      : vuln.get('PkgName', 'N/A'),
            'InstalledVersion' : vuln.get('InstalledVersion', 'N/A'),
            'FixedVersion'     : vuln.get('FixedVersion', 'N/A'),
            'Title'            : vuln.get('Title', 'N/A'),
            'Description'      : vuln.get('Description', '')[:200],
            'References'       : (vuln.get('References') or ['N/A'])[0],
        })

# Tri : CRITICAL > MEDIUM > LOW
severity_order = {'CRITICAL': 0, 'HIGH': 1, 'MEDIUM': 2, 'LOW': 3, 'UNKNOWN': 4}
rows.sort(key=lambda r: severity_order.get(r['Severity'], 99))

fields = ['Target','PackageType','VulnerabilityID','Severity',
          'PackageName','InstalledVersion','FixedVersion','Title',
          'Description','References']

with open('${TRIVY_REPORT_CSV}', 'w', newline='') as csvfile:
    writer = csv.DictWriter(csvfile, fieldnames=fields)
    writer.writeheader()
    writer.writerows(rows)

# Résumé par sévérité
from collections import Counter
counts = Counter(r['Severity'] for r in rows)
print('\\n📊 Résumé des vulnérabilités :')
for sev in ['CRITICAL', 'MEDIUM', 'LOW', 'UNKNOWN']:
    print(f'  {sev:10s}: {counts.get(sev, 0)}')
print(f'  {\"TOTAL\":10s}: {len(rows)}')
print(f'\\n✅ Rapport CSV généré : ${TRIVY_REPORT_CSV}')
"
                """
            }

            post {
                always {
                    // Archiver les deux rapports comme artefacts Jenkins
                    archiveArtifacts artifacts: "${TRIVY_REPORT_CSV}, ${TRIVY_REPORT_JSON}",
                                     allowEmptyArchive: true

                    echo "📁 Rapports archivés dans Jenkins."
                }
            }
        }
    }

    // ─────────────────────────────────────────────
    // POST — Nettoyage & notifications
    // ─────────────────────────────────────────────
    post {
        success {
            echo "🎉 Pipeline terminé avec succès !"
            echo "📄 Rapport de sécurité disponible : ${TRIVY_REPORT_CSV}"
        }
        failure {
            echo "❌ Pipeline en échec. Vérifiez les logs ci-dessus."
        }
        cleanup {
            // Nettoyage optionnel des conteneurs lancés par compose
            sh "docker compose -f ${COMPOSE_FILE} down --remove-orphans || true"
            echo "🧹 Nettoyage Docker effectué."
        }
    }
}
