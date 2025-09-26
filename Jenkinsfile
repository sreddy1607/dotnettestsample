container(name: "aws-boto3") {
          script {
            lock(resource: 'tar-surge-client-deployment', inversePrecedence: false) {
              dir("${WORKSPACE}/deploytarget") {
                withCredentials([usernamePassword(credentialsId: "github-key", usernameVariable: 'NUSER', passwordVariable: 'NPASS')]) {
                  sh """
                    echo "Cloning tar-surge-client-deployment..."
                    git clone https://${NUSER}:${NPASS}@github.com/ca-mmis/tar-surge-client-deployment.git
                    cd tar-surge-client-deployment
                    git config --global user.email "jenkins@cammis.com"
                    git config --global user.name "jenkins"
                    git checkout master
                    git pull

                    ZIP_NAME=thickclient-${env_promotion_to_environment}.zip

                    echo "Creating \$ZIP_NAME ..."
                    rm -f tar-surge-client/\$ZIP_NAME
                    mkdir -p tmpdir/Thickclient
                    cp -a ${WORKSPACE}/deployrepo/deployments-combined-devops/tar-surge-client/${env_promotion_to_environment}/* tmpdir/Thickclient/
                    cd tmpdir
                    zip -r ../tar-surge-client/\$ZIP_NAME Thickclient
                    cd ..
                    rm -rf tmpdir


                    git add tar-surge-client/\$ZIP_NAME
                    git commit -m "Deploy \$ZIP_NAME from ${env_promotion_to_environment} promotion"
                    git push https://${NUSER}:${NPASS}@github.com/ca-mmis/tar-surge-client-deployment.git

                    commitId=\$(git rev-parse --short=8 HEAD)
                    dateTime=\$(git show -s --format=%cd --date=format:%Y-%m-%d_%H-%M-%S \$commitId)
                    commitTag="Deployed_to_${env_promotion_to_environment}_\${commitId}_\$dateTime"
                    echo "Tagging with: \$commitTag"
                    git tag -f -a "\$commitTag" -m "Deployment tag for \$ZIP_NAME" "\$commitId"
                    git push https://${NUSER}:${NPASS}@github.com/ca-mmis/tar-surge-client-deployment.git
                    git push https://${NUSER}:${NPASS}@github.com/ca-mmis/tar-surge-client-deployment.git "\$commitTag"
                  """
