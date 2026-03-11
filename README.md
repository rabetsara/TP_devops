# 🚀 Projet DevOps Jenkins — Docker + Trivy Security Scan

## 📁 Structure du projet

```
.
├── Jenkinsfile          ← Pipeline Jenkins (3 stages)
├── docker-compose.yml   ← Définition des services Docker
├── Dockerfile           ← Image applicative (exemple Java)
└── README.md
```

---

## 🔄 Architecture du Pipeline

```
┌─────────────────────────────────────────────────────────┐
│                    JENKINS PIPELINE                      │
│                                                          │
│  ┌──────────────────┐  ┌──────────────────┐  ┌────────────────────┐  │
│  │   STAGE 1        │  │   STAGE 2        │  │   STAGE 3          │  │
│  │                  │  │                  │  │                    │  │
│  │ Pull & Build     │→ │ Security Scan    │→ │ CSV Report         │  │
│  │ Docker Image     │  │ with Trivy       │  │ Generation         │  │
│  │                  │  │                  │  │                    │  │
│  │ docker compose   │  │ trivy image scan │  │ JSON → CSV         │  │
│  │ pull + build     │  │ → JSON report    │  │ LOW/MEDIUM/CRITICAL│  │
│  └──────────────────┘  └──────────────────┘  └────────────────────┘  │
└─────────────────────────────────────────────────────────┘
                                                  ↓
                                     trivy-report.csv (archivé)
                                     trivy-report.json (archivé)
```

---

## 📋 Détail des Stages

### Stage 1 — Pull & Build Docker Image
- **`docker compose pull`** : télécharge toutes les images de base déclarées
- **`docker compose build --no-cache`** : construit les images custom sans cache
- Garantit une image fraîche à chaque exécution du pipeline

### Stage 2 — Security Scan with Trivy
- Vérifie la présence de Trivy sur l'agent Jenkins
- Met à jour la base de données de vulnérabilités CVE
- Scanne l'image avec filtrage par sévérité : **LOW, MEDIUM, CRITICAL**
- Produit un rapport intermédiaire `trivy-report.json`

### Stage 3 — Generate CSV Security Report
- Script Python embarqué convertit le JSON en CSV structuré
- Colonnes du CSV :

| Colonne | Description |
|---|---|
| `Target` | Nom de la cible scannée |
| `PackageType` | Type de paquet (os, library…) |
| `VulnerabilityID` | Identifiant CVE |
| `Severity` | LOW / MEDIUM / CRITICAL |
| `PackageName` | Nom du paquet vulnérable |
| `InstalledVersion` | Version installée |
| `FixedVersion` | Version corrective disponible |
| `Title` | Titre court de la CVE |
| `Description` | Description (tronquée à 200 chars) |
| `References` | Lien de référence principal |

- Tri automatique : **CRITICAL → MEDIUM → LOW**
- Résumé affiché dans les logs Jenkins
- Rapport archivé comme artefact Jenkins

---

## ⚙️ Prérequis Jenkins

### Sur l'agent Jenkins, installer :
```bash
# Docker & Docker Compose
sudo apt install docker.io docker-compose-plugin -y

# Trivy
curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh | sh -s -- -b /usr/local/bin

# Python 3 (généralement déjà présent)
sudo apt install python3 -y
```

### Permissions Docker pour l'utilisateur Jenkins :
```bash
sudo usermod -aG docker jenkins
sudo systemctl restart jenkins
```

---

## 🚀 Utilisation

1. **Créer un nouveau job Pipeline** dans Jenkins
2. Pointer sur le dépôt Git contenant ces fichiers
3. Sélectionner `Jenkinsfile` comme script de pipeline
4. Lancer le build

### Après exécution :
- Aller dans `Build > Artefacts archivés`
- Télécharger `trivy-report.csv`
- Ouvrir avec Excel / LibreOffice / tout éditeur CSV

---

## 🔧 Personnalisation

### Changer l'image à scanner
Dans `Jenkinsfile`, modifier la variable :
```groovy
IMAGE_NAME = "myapp"   // → nom:tag de votre image
```

### Filtrer les sévérités
```groovy
SEVERITY_FILTER = "LOW,MEDIUM,CRITICAL"  // ou "HIGH,CRITICAL" uniquement
```

### Faire échouer le pipeline si des CRITICAL sont trouvées
Dans le stage Trivy, changer :
```groovy
--exit-code 0   →   --exit-code 1
```

---

## 📊 Exemple de rapport CSV généré

```csv
Target,PackageType,VulnerabilityID,Severity,PackageName,InstalledVersion,FixedVersion,Title,Description,References
myapp:latest (alpine 3.18.4),os,CVE-2023-5363,CRITICAL,openssl,3.1.3-r0,3.1.4-r0,OpenSSL issue...,Vulnerability in...,https://nvd.nist.gov/...
myapp:latest (alpine 3.18.4),os,CVE-2023-3446,MEDIUM,openssl,3.1.3-r0,3.1.4-r0,DH key check issue,...,https://nvd.nist.gov/...
```
