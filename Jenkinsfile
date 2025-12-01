pipeline {
    environment {
        DOCKER_REGISTRY = "registry.weychafe.nicher.cl"
        IMAGE_NAME = "aurora_gov"
    }
    agent {
        kubernetes {
            yaml """
apiVersion: v1
kind: Pod
spec:
  containers:
  - name: docker
    image: docker:24
    tty: true
    command:
    - cat
    volumeMounts:
    - name: docker-sock
      mountPath: /var/run/docker.sock
  volumes:
  - name: docker-sock
    hostPath:
      path: /var/run/docker.sock
"""
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
                                credentialsId: 'github-aurora',
                                url: 'https://github.com/aurora-ong/aurora_gov.git'
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
                sshagent(['weychafe_jenkins_deployer']) {
                    sh "ssh -o StrictHostKeyChecking=no jenkins-deployer@weychafe.nicher.cl 'set image deployment.apps/aurora-gov-deployment aurora-gov=$DOCKER_REGISTRY/$IMAGE_NAME:${env.BUILD_ID} -n aurora-gov'"
                    sh "ssh -o StrictHostKeyChecking=no jenkins-deployer@weychafe.nicher.cl 'rollout status deployment/aurora-gov-deployment -n aurora-gov'"                    
                }
            }
        }
    }
}
