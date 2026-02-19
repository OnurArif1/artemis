pipeline {
  agent any

  options {
    timestamps()
    disableConcurrentBuilds()
  }

  stages {
    stage('Checkout') {
      steps {
        checkout scm
      }
    }

    stage('Docker Build (all)') {
      parallel {
        stage('Build Gateway') {
          steps {
            sh 'docker build -t emndmr/artemis-gateway:latest -f src/Artemis.Gateway/Dockerfile .'
          }
        }
        stage('Build IdentityServer') {
          steps {
            sh 'docker build -t emndmr/artemis-identityserver:latest -f src/Identity.Api/Dockerfile .'
          }
        }
        stage('Build API') {
          steps {
            sh 'docker build -t emndmr/artemis-api:latest -f src/Artemis.API/Dockerfile .'
          }
        }
        stage('Build Web API') {
          steps {
            sh 'docker build -t emndmr/artemis-web-api:latest -f src/Web/WebApi/Dockerfile .'
          }
        }
      }
    }

    stage('Docker Push (all)') {
      when { branch 'main' }
      steps {
        withCredentials([usernamePassword(
          credentialsId: 'dockerhub-emndmr',
          usernameVariable: 'DOCKER_USER',
          passwordVariable: 'DOCKER_PASS'
        )]) {
          sh '''
            set -e
            echo "$DOCKER_PASS" | docker login -u "$DOCKER_USER" --password-stdin
            docker push emndmr/artemis-gateway:latest
            docker push emndmr/artemis-identityserver:latest
            docker push emndmr/artemis-api:latest
            docker push emndmr/artemis-web-api:latest
            docker logout
          '''
        }
      }
    }
  }

  post {
    always {
      sh 'docker image prune -f || true'
    }
  }
}
