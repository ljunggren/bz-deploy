docker run --rm -v /.ssh/id_rsa:/tmp/.ssh/id_rsa -v /.ssh/id_rsa.pub:/tmp/.ssh/id_rsa.pub -v ${PWD}:/ansible/playbooks styrman/ansible-playbook site.yaml -i inventory.ini --tags=deploy
