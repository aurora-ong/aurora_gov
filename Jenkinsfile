pipeline {
    environment {
        DOCKER_REGISTRY = 'registry.weychafe.nicher.cl'
        IMAGE_NAME = 'aurora_gov'
    }
    agent {
        kubernetes {
            yaml '''
apiVersion: v1
kind: Pod
metadata:
  labels:
    app: jenkins-builder
spec:
  containers:
  - name: docker
    image: docker:24-cli
    tty: true
    command: ["cat"]
    securityContext:
      runAsUser: 0
    volumeMounts:
    - name: docker-sock
      mountPath: /var/run/docker.sock

  - name: kubectl
    image: bitnami/kubectl:latest
    tty: true
    command: ["cat"]
    securityContext:
      runAsUser: 0

  volumes:
  - name: docker-sock
    hostPath:
      path: /var/run/docker.sock
            '''
        }
    }
    stages {
        stage('Clone and Build') {
            steps {
                container('docker') {
                    script {
                        checkout scmGit(
                            branches: [[name: '*/master']],
                            extensions: [],
                            userRemoteConfigs: [[
                                credentialsId: 'github-aurora_gov-deploy-key',
                                url: 'git@github.com:aurora-ong/aurora_gov.git'
                            ]]
                        )
                        withCredentials([usernamePassword(credentialsId: 'weychafe-registry', usernameVariable: 'USER', passwordVariable: 'PASS')]) {
                            sh '''
                                echo "$PASS" | docker login $DOCKER_REGISTRY -u "$USER" --password-stdin
                            '''
                        }
                        sh "docker build --network host -t $DOCKER_REGISTRY/$IMAGE_NAME:${env.BUILD_ID} ."
                        sh "docker push $DOCKER_REGISTRY/$IMAGE_NAME:${env.BUILD_ID}"
                    }
                }
            }
        }

        stage('Deploy') {
            steps {
                container('kubectl') {
                    withKubeConfig([credentialsId: 'weychafe-k8s-deployer']) {
                            sh "kubectl set image deployment/aurora-gov-deployment aurora-gov=$DOCKER_REGISTRY/$IMAGE_NAME:${env.BUILD_ID} -n aurora-gov"
                            sh 'kubectl rollout status deployment/aurora-gov-deployment -n aurora-gov'
                    }
                }
            }
        }
    }
}
