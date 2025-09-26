container(name: "jnlp") {
          lock(resource: 'deployments-github-repo',inversePrecedence: false ) {
           dir("${WORKSPACE}/deployrepo"){
              withCredentials([usernamePassword(credentialsId: "github-key", usernameVariable: 'NUSER', passwordVariable: 'NPASS')]) {
                sh """
                  git clone https://${NUSER}:${NPASS}@github.com/ca-mmis/deployments-combined-devops.git --depth=1
                  git config  --global user.email "jenkins@cammis.com"
                  git config  --global user.name "jenkins"

                  cd deployments-combined-devops
                  git checkout master
                  git pull

                  cp ${WORKSPACE}/devops/codedeploy/serverconfig/index.html ${WORKSPACE}/deployrepo/deployments-combined-devops/tar-surge-app/dev

                            
                    echo "Cammis.Surge.Api was built, need to update deployment repository"
                    echo "Comparing the directories with DIFF:"
                    set +e
                    diff -r ${WORKSPACE}/devops/codedeploy/surgeapi ${WORKSPACE}/deployrepo/deployments-combined-devops/tar-surge-app/dev/surgeapi
                    set -e
                    # remove and replace deployment for surgeapi
                    rm -r ${WORKSPACE}/deployrepo/deployments-combined-devops/tar-surge-app/dev/surgeapi/*
                    cp -a ${WORKSPACE}/devops/codedeploy/surgeapi/. ${WORKSPACE}/deployrepo/deployments-combined-devops/tar-surge-app/dev/surgeapi/
                    rm ${WORKSPACE}/deployrepo/deployments-combined-devops/tar-surge-app/dev/surgeapi/placeholder.txt
                    updates_to_deploy=true
                  

                  if [ "\$updates_to_deploy" = true ] ; then
                    touch tar-surge-app/updates_to_deploy
                  fi


                """
                
                script {
                   incrementVersion()
                }

                sh """
                  cd ${WORKSPACE}/deployrepo/deployments-combined-devops
                  if [ -f tar-surge-app/updates_to_deploy ] ; then
                    echo 'Pushing to the deployment repository'
                    rm tar-surge-app/updates_to_deploy
                    echo "Will tag deploy repo with: \"Updated build artifacts for tar-surge-app build ${env_tag_name}\""
                    git add -Av
                    git commit -m "Updated build artifacts for tar-surge-app build ${env_tag_name}"
                    git push https://${NUSER}:${NPASS}@github.com/ca-mmis/deployments-combined-devops.git
                  else
                    echo "Nothing needs to be pushed to deployment repository"
                  fi
                  pwd
                """
              } //end withCredentials
            } //end dir
          } //end lock
        }  //end container
