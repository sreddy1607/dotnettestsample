/*
=======================================================================================
This file is being updated constantly by the DevOps team to introduce new enhancements
based on the template.  If you have suggestions for improvement,
please contact the DevOps team so that we can incorporate the changes into the
template.  In the meantime, if you have made changes here or don't want this file to be
updated, please indicate so at the beginning of this file.
=======================================================================================
*/

def branch = env.BRANCH_NAME ?: "master"
def workingDir = "/home/jenkins/agent"

pipeline {
  agent {
    kubernetes {
      yaml """
        apiVersion: v1
        kind: Pod
        spec:
          serviceAccountName: jenkins
          volumes:
            - name: dockersock
              hostPath:
                path: /var/run/docker.sock
            - emptyDir: {}
              name: varlibcontainers
            - name: jenkins-trusted-ca-bundle
              configMap:
                name: jenkins-trusted-ca-bundle
                defaultMode: 420
                optional: true
          containers:
            - name: dotnet
              image: 136299550619.dkr.ecr.us-west-2.amazonaws.com/cammismspapp:1.0.34
              tty: true
              command: ["/bin/bash"]
              securityContext:
                privileged: true
              workingDir: ${workingDir}
              envFrom:
                - configMapRef:
                    name: jenkins-agent-env
                    optional: true
              env:
                - name: HOME
                  value: ${workingDir}
                - name: BRANCH
                  value: ${branch}
            - name: jnlp
              securityContext:
                privileged: true
              envFrom:
                - configMapRef:
                    name: jenkins-agent-env
                    optional: true
              env:
                - name: GIT_SSL_CAINFO
                  value: "/etc/pki/tls/certs/ca-bundle.crt"
              volumeMounts:
                - name: jenkins-trusted-ca-bundle
                  mountPath: /etc/pki/tls/certs
            - name: node
              image: registry.access.redhat.com/ubi8/nodejs-18:latest
              tty: true
              command: ["/bin/bash"]
              securityContext:
                privileged: true
              workingDir: ${workingDir}
              envFrom:
                - configMapRef:
                    name: jenkins-agent-env
                    optional: true
              env:
                - name: HOME
                  value: ${workingDir}
                - name: BRANCH
                  value: ${branch}
                - name: GIT_SSL_CAINFO
                  value: "/etc/pki/tls/certs/ca-bundle.crt"
              volumeMounts:
                - name: jenkins-trusted-ca-bundle
                  mountPath: /etc/pki/tls/certs
            - name: aws-boto3
              image: 136299550619.dkr.ecr.us-west-2.amazonaws.com/cammisboto3:1.0.1
              tty: true
              command: ["/bin/bash"]
              workingDir: ${workingDir}
              envFrom:
                - configMapRef:
                    name: jenkins-agent-env
                    optional: true
              env:
                - name: HOME
                  value: ${workingDir}
                - name: BRANCH
                  value: ${branch}
                - name: GIT_SSL_CAINFO
                  value: "/etc/pki/tls/certs/ca-bundle.crt"
              volumeMounts:
                - name: jenkins-trusted-ca-bundle
                  mountPath: /etc/pki/tls/certs
      """
    }
  }

  options {
    timestamps()
    disableConcurrentBuilds()
    timeout(time:5 , unit: 'HOURS')
    skipDefaultCheckout()
    buildDiscarder(logRotator(numToKeepStr: '20'))
  }

  environment {
    env_current_git_commit=""
    env_tag_name=""
    env_deploy_env=""
    SONAR_TIMEOUT = 3
    SONAR_SLEEP = 10000
    SONAR_ERROR_MSG = "QUALITY GATE ERROR: Pipeline set to unstable"
    SONAR_BUILD_RESULT = "UNSTABLE"
    SONAR_SLACK_MSG = "Quality Gate Passed"
  }

  parameters {
    choice(name: 'ENVIRONMENT', choices: ['sit', 'uat', 'prd'], description: 'Select the environment to deploy to')
    choice(name: 'RELEASE_TYPE', choices: ['PATCH','MINOR','MAJOR'], description: 'Enter Release type')
    booleanParam(name: 'USE_GIT_TAG', defaultValue: false, description: 'Use the selected git tag instead of LATEST commit')
    gitParameter(name: 'GIT_TAG', defaultValue: 'tar-surge-client_from_dev', description: 'git tag', type: 'PT_TAG')
    string(name: 'GIT_SHA',defaultValue: 'enter git sha(8+ chars)', description: 'enter git sha that you want to deploy')
  }

  stages {
    stage("initialize") {
      steps {
        container(name: "node") {
          script {
            deleteDir()
            env_deploy_env = params.ENVIRONMENT.toUpperCase()
            env_current_git_commit = checkout(scm).GIT_COMMIT[0..7]
            env_tag_name = "${params.ENVIRONMENT}_${BUILD_NUMBER}_${env_current_git_commit}"

            if (params.USE_GIT_TAG) {
              env_current_git_commit = params.GIT_TAG
            }

            if (!params.GIT_SHA.contains("enter")) {
              env_current_git_commit = params.GIT_SHA
            }

            def repositories = [
              [name: 'tar-surge-client', branch: 'master', url: 'https://github.com/ca-mmis/tar-surge-client.git'],
              [name: 'tar-surge-app', branch: 'master', url: 'https://github.com/ca-mmis/tar-surge-app.git']
            ]

            repositories.each { repo ->
              dir(repo.name) {
                git branch: repo.branch, credentialsId: 'github-key', url: repo.url
              }
            }

            withCredentials([usernamePassword(credentialsId: "github-key", usernameVariable: 'NUSER', passwordVariable: 'NPASS')]) {
              sh """
                git config --global --add safe.directory '*'
                git config  --global user.email "jenkins@cammis.com"
                git config  --global user.name "jenkins"
                git fetch --quiet --tags https://${NUSER}:${NPASS}@github.com/ca-mmis/tar-surge-client.git
                git tag -f -a "${env_tag_name}" -m "tag build" ${env_current_git_commit}
                git push -f https://${NUSER}:${NPASS}@github.com/ca-mmis/tar-surge-client.git ${env_tag_name}
                git checkout ${env_current_git_commit}
                git show --stat ${env_current_git_commit} > commit-changes.txt
              """
            }
          }
        }
      }
    }

 stage('Build') {
      steps {
        container(name: "node") {
          script {
           sh '''
              echo "Creating directory to build into and deploy from."
              echo "Need to add the placeholder.txt file so AWS CodeDeploy deploys an empty directory"
              mkdir devops/codedeploy/thickclient
              touch devops/codedeploy/thickclient/placeholder.txt
            '''
          }
        }

        container(name: "dotnet") {
          script {
           sh '''
                        yum install -y zip
                        echo "Building thickclient application..."
                        dotnet publish tar-surge-client/Cammis.Surge.Client.sln -o devops/codedeploy/thickclient -c Release -r win-x64 --self-contained true /p:EnableWindowsTargeting=true                        
                        echo "Listing built files..."
                        ls -l devops/codedeploy/thickclient
                        rm -f devops/codedeploy/thickclient/placeholder.txt
                        echo "Zipping Thickclient DLLs and artifacts..."
                        cd devops/codedeploy
                        zip -r thickclient.zip thickclient
                        ls -l thickclient.zip
                        
                        '''
          }
        }
      } // end of steps
    } // end of Build stage

    stage("Sonar Scan") {
      steps {
        script {
          withSonarQubeEnv('sonar_server') {
            container(name: "dotnet") {
              sh """
                mkdir -p /home/jenkins/agent/.sonar/native-sonar-scanner
                wget --quiet https://binaries.sonarsource.com/Distribution/sonar-scanner-cli/sonar-scanner-cli-6.1.0.4477-linux-x64.zip
                unzip -q sonar-scanner-cli-6.1.0.4477-linux-x64.zip -d /home/jenkins/agent/.sonar/native-sonar-scanner
              """
            }
            container(name: "jnlp") {
              sh """
                /home/jenkins/agent/.sonar/native-sonar-scanner/sonar-scanner-6.1.0.4477-linux-x64/bin/sonar-scanner -Dproject.settings=${WORKSPACE}/tar-surge-client/devops/sonar/sonar-project.properties
              """
            }
          }
        }
      }
    }

    stage("Quality Gate") {
      steps {
        container(name: "jnlp") {
          script {
            sleep time: SONAR_SLEEP, unit: "MILLISECONDS"
            timeout(time: SONAR_TIMEOUT, unit: 'MINUTES') {
              def qualGate = waitForQualityGate()
              if (qualGate.status != "OK") {
                currentBuild.result = SONAR_BUILD_RESULT
              }
            }
          }
        }
      }
    }

    stage('Deploy') {
      steps {
        container(name: "node") {
          withCredentials([usernamePassword(credentialsId: "github-key", usernameVariable: 'NUSER', passwordVariable: 'NPASS')]) {
            sh """
              git clone https://${NUSER}:${NPASS}@github.com/ca-mmis/tar-surge-client-deployment.git --depth=1
              cd tar-surge-client-deployment
              git config --global user.email "jenkins@cammis.com"
              git config --global user.name "jenkins"
              git checkout master
              git pull
              cp ${WORKSPACE}/devops/codedeploy/thickclient.zip tar-surge-client/
              git status
              if [[ -n \$(git status --porcelain) ]]; then
                git add .
                git commit -m "Automated commit - Deploying thickclient zipped DLLs"
                git push origin master
              fi
              git tag -f -a "${env_tag_name}" -m "Deploying thickclient - Tag ${env_tag_name}"
              git push origin "${env_tag_name}" --force
            """
          }
        }
      }
    }
  }

  post {
    always { echo "Build Process complete." }
    success { echo "Build Process was success." }
    unstable { echo "Build is unstable." }
    aborted { echo "Pipeline aborted." }
    failure { echo "Build encountered failures." }
    changed { echo "Build content was changed." }
  }
}
