pipeline {
    agent any // Exécute le build sur n'importe quel agent disponible

    stages {
        stage('Checkout') {
            steps {
                // Récupère le code depuis GitHub
                checkout scm
            }
        }

        stage('Build') {
            steps {
                echo 'Compilation du projet...'
                // Exemple : sh './gradlew build' ou 'npm install'
            }
        }

        stage('Test') {
            steps {
                echo 'Exécution des tests unitaires...'
                // Exemple : sh 'npm test'
            }
        }

        stage('Deploy') {
            steps {
                echo 'Déploiement en cours...'
            }
        }
    }

    post {
        always {
            echo 'Le pipeline est terminé.'
        }
        success {
            echo 'Build réussi !'
        }
        failure {
            echo 'Échec du build, vérifiez les logs.'
        }
    }
}
