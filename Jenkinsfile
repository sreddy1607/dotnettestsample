/*
=======================================================================================
This file is being updated constantly by the DevOps team to introduce new enhancements
based on the template.  If you have suggestions for improvement,
please contact the DevOps team so that we can incorporate the changes into the
template.  In the meantime, if you have made changes here or don't want this file to be
updated, please indicate so at the beginning of this file.
=======================================================================================
*/

def branch = env.BRANCH_NAME ?: "ecr"
def namespace = env.NAMESPACE ?: "dev"
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
              image: registry.access.redhat.com/ubi8/nodejs-16:latest
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
            - name: mspdotnet
              image: 136299550619.dkr.ecr.us-west-2.amazonaws.com/cammismspapp:1.0.15
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
            
      """
    }
  }

  options {
    //timestamps()
    disableConcurrentBuilds()
    timeout(time:5 , unit: 'HOURS')
    skipDefaultCheckout()
    buildDiscarder(logRotator(numToKeepStr: '20'))
  }

  environment {
    env_git_branch_type="feature"
    env_git_branch_name=""
    env_current_git_commit=""
    env_skip_build="false"
    env_stage_name=""
    env_step_name=""
    DOTNET_CLI_TELEMETRY_OPTOUT = '1'


  }

  stages {
    stage("initialize") {
      steps {
        container(name: "node") {
          script {

            properties([
              parameters([
                // booleanParam(name: 'S3', defaultValue: false, description: 'select S3 to upload the truststore file')        
		string(name: 'CLIENT_EMAIL', defaultValue: 'srinivas.reddy@dhcs.ca.gov', description: 'Client Email Address')
              ])
            ])

            env_stage_name = "initialize"
            env_step_name = "checkout"

            deleteDir()

            echo 'checkout source  and get the commit id'
            //env_current_git_commit = checkout(scm).GIT_COMMIT

            echo 'Loading properties file'
            env_step_name = "load properties"
            // load the pipeline properties
            // load(".jenkins/pipelines/Jenkinsfile.ecr.properties")

            env_step_name = "set global variables"
            echo 'initialize slack channels and tokens'
            //initSlackChannels()

            //env_git_branch_name = BRANCH_NAME


            // get the short version of commit
           //env_current_git_commit="${env_current_git_commit[0..7]}"
            //echo "The commit hash from the latest git current commit is ${env_current_git_commit}"
                      
            //include commit id in build name
            currentBuild.displayName = "#${BUILD_NUMBER}"

           // slackNotification("pipeline","${APP_NAME}-${env_git_branch_name}: <${BUILD_URL}console|build #${BUILD_NUMBER}> started.","#439FE0","false")
          } //END script
        } //END container node
      } //END steps
    } //END stage

  
stage('test dotnet image') {
    steps {
         
        container(name: "mspdotnet") {
		//checkout scmGit(branches: [[name: '*/master']], extensions: [], userRemoteConfigs: [[credentialsId: 'jenkins-dev-github', url: 'abc']])
            script {
                withCredentials([aws(accessKeyVariable: 'AWS_ACCESS_KEY_ID', credentialsId: 'jenkins-ecr', secretKeyVariable: 'AWS_SECRET_ACCESS_KEY')]) {
                
                   
                    sh """
		                dotnet --version 
                    git clone https://github.com/sreddy1607/dotnettestsample.git
		    ls -l
                    dotnet restore dotnettestsample/NET-Core-Web-API-Docker-Demo.sln

                    """
                }
            }
        }
        
    }
}

}


  //pipeline post actions
  post {
    always {
        echo "Build Process complete."
    } // always

    success {
        echo "Build Process was success. Site is available at ${env.SITE_URL}"
        //slackNotification("pipeline", "${APP_NAME}-${env_git_branch_name}: <${BUILD_URL}|build #${BUILD_NUMBER}> was successful :woohoo: after ${currentBuild.durationString}.\n", "#215ACC","false")
    }//success

    unstable {
        echo "Build is unstable."
       // slackNotification("pipeline","${APP_NAME}-${env_git_branch_name}: <${BUILD_URL}|build #${BUILD_NUMBER}> was unstable :shrug: after ${currentBuild.durationString}. Check `SonarQube Quality Gate` status.", "#F6F60F","true")
    } // unstable

    aborted {
        echo "Pipeline aborted."
      //  slackNotification("pipeline", "${APP_NAME}-${env_git_branch_name}: <${BUILD_URL}|build #${BUILD_NUMBER}> aborted :bkpabort: after ${currentBuild.durationString} in stage: `${env_stage_name}` step: `${env_step_name}`.", "#EA6E06","false")
    } // aborted

    failure {
        echo "Build encountered failures ."
      //  slackNotification("pipeline","${APP_NAME}-${env_git_branch_name}: <${BUILD_URL}|build #${BUILD_NUMBER}> failed :crash: after ${currentBuild.durationString} in stage: `${env_stage_name}` step: `${env_step_name}`. @here", "#EA0652","true")
    } // failure

    changed {
        echo "Build content was changed."
    } // changed

  } // post
}

