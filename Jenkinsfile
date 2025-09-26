echo "Copying zipped build artifacts to the deployment repository..."
                        cp ${WORKSPACE}/devops/codedeploy/Thickclient.zip ${WORKSPACE}/tar-surge-client-deployment/tar-surge-client/

                        cd ${WORKSPACE}/tar-surge-client-deployment
                        echo "Checking for changes..."
                        git status

                        if [[ -n \$(git status --porcelain) ]]; then
                            echo "Changes detected, committing..."
                            git add .
                            git commit -m "Automated commit - Deploying Thickclient zipped DLLs"
                            git push origin master
                        else
                            echo "No changes to commit."
                        fi
                        echo "Tagging the deployment repo with same tag: ${env_tag_name}"
                        git tag -f -a "${env_tag_name}" -m "Deploying Thickclient - Tag ${env_tag_name}"
                        git push origin "${env_tag_name}" --force
