/*
=======================================================================================
This file is being updated constantly by the DevOps team to introduce new enhancements
based on the template.  If you have suggestions for improvement,
please contact the DevOps team so that we can incorporate the changes into the
template.  In the meantime, if you have made changes here or don't want this file to be
updated, please indicate so at the beginning of this file.
=======================================================================================
*/

def branch = env.BRANCH_NAME ?: "Dev"
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
              securityContext:
                privileged: true
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
    env_accesskey=""
    env_secretkey=""
    env_tag_name=""
    env_deploy_env=""
    env_skip_deploy="true"
    env_DEPLOY_ENVIRONMENT="false"
    env_DEPLOY_FILES="true"
    env_DEPLOY_CONFIG="false"
    env_release_type=""
  }

  stages {
   stage("Initialize") {
    steps {
        container(name: "node") {
            script {
                properties([
                    parameters([
                        choice(name: 'RELEASE_TYPE', choices: ['PATCH', 'MINOR', 'MAJOR'], description: 'Enter Release type'),
                        booleanParam(name: 'USE_GIT_TAG', defaultValue: false, description: 'Use the selected git tag instead of LATEST commit'),
                        gitParameter(name: 'GIT_TAG', defaultValue: 'tar-surge-app_from_dev', description: 'Git tag to deploy', type: 'PT_TAG'),
                        string(name: 'GIT_SHA', defaultValue: 'enter git sha(8+ chars)', description: 'Enter git SHA to deploy')
                    ])
                ])

                deleteDir()

                echo 'Checking out source and retrieving commit ID...'
                env_current_git_commit = checkout(scm).GIT_COMMIT

                // Get the short version of the commit hash
                env_current_git_commit = "${env_current_git_commit[0..7]}"

                env_deploy_env = "DEV"
                echo "Current deployment environment: ${env_deploy_env}"
		def repositories = [
                        [name: 'tar-surge-client', branch: 'Dev', url: 'https://github.com/ca-mmis/tar-surge-client.git'],
                        [name: 'tar-surge-app', branch: 'master', url: 'https://github.com/ca-mmis/tar-surge-app.git']
                    ]

                    repositories.each { repo ->
                        dir(repo.name) {
                            git branch: repo.branch, credentialsId: 'github-key', url: repo.url
                        }
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
              mkdir devops/codedeploy/Thickclient
              touch devops/codedeploy/Thickclient/placeholder.txt
            '''
          }
        }

        container(name: "dotnet") {
          script {
           sh '''
             echo "Checking if surge-client needs to be built/deployed..."
            
	    
             dotnet publish tar-surge-client/Cammis.Surge.Client.sln -o devops/codedeploy/Thickclient --verbosity detailed /p:EnableWindowsTargeting=true

             ls -l devops/codedeploy/Thickclient
            '''
          }
        }
      } // end of steps
    } // end of Build stage
	  
  
   stage('Deploy') {
      steps {
        container(name: "aws-boto3") {
          script {
            sh """#!/bin/bash
            echo "Deploy Using AWS CodeDeploy"
            """
            withCredentials([aws(accessKeyVariable: 'AWS_ACCESS_KEY_ID', credentialsId: 'jenkins-ecr-ecs', secretKeyVariable: 'AWS_SECRET_ACCESS_KEY')]) {
              step([$class: 'AWSCodeDeployPublisher',
                  applicationName: "tar-surge-app-${env_deploy_env}",
                  awsAccessKey: "${AWS_ACCESS_KEY_ID}",
                  awsSecretKey: "${AWS_SECRET_ACCESS_KEY}",
                  credentials: 'awsAccessKey',
                  deploymentConfig: "tar-surge-app-${env_deploy_env}-config",
                  deploymentGroupAppspec: false,
                  deploymentGroupName: "tar-surge-app-${env_deploy_env}-INPLACE-deployment-group",
                  deploymentMethod: 'deploy',
                  excludes: '', iamRoleArn: '', includes: '**', pollingFreqSec: 15, pollingTimeoutSec: 900, proxyHost: '', proxyPort: 0,
                  region: 'us-west-2', s3bucket: 'dhcs-codedeploy-app', 
                  subdirectory: 'devops/codedeploy', versionFileName: '', waitForCompletion: true])
            }
          } // end of script
        } // end of container    
      } // end of steps
    } // end of Deploy stage 
  } // end of stages

  //pipeline post actions
  post {
    always {
        echo "Build Process complete."
    } // always

    success {
        echo "Build Process was success."
    } //success

    unstable {
        echo "Build is unstable."
    } // unstable

    aborted {
        echo "Pipeline aborted."
    } // aborted

    failure {
        echo "Build encountered failures ."
    } // failure

    changed {
        echo "Build content was changed."
    } // changed

  } // post
}
