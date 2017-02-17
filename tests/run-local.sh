#! /bin/bash

# Version of the Travis-CI script that we can run locally if we have Docker installed

# Various testing targets
DISTROS=("centos6")
INITS=("/sbin/init")

# Assuming our GitHub repo / directory name is the role name
PARENT_DIR="$(dirname $(cd `dirname $0` && pwd))"
ROLE_NAME=${PARENT_DIR##*/}

# Color hints for alerts and messages
GREEN='\033[1;32m'
RED='\033[0;31m'
NC='\033[0m'

# An informational message in case a test fails
die () {
  echo ""
  printf "${RED}Tests failed!${NC}\n"
  echo ""
  printf "  ${GREEN}To clean up the testing container, run:${NC}\n"
  echo "    docker rm -f \"$(cat $1)\""
  echo ""
  printf "  ${GREEN}To clean up all system containers, run:${NC}\n"
  echo "    docker rm -f \$(docker ps -a -q)"
  echo ""

  exit 1
}

# Our tests need Docker installed
hash docker 2>/dev/null || { echo >&2 "I require Docker to be installed to run tests. Aborting."; exit 1; }

for ((INDEX = 0; INDEX < ${#DISTROS[@]}; INDEX++)); do
  DISTRO="${DISTROS[$INDEX]}"
  INIT="${INITS[$INDEX]}"

  docker pull geerlingguy/docker-${DISTRO}-ansible:latest

  CONTAINER_ID=$(mktemp)
  IDEMPOTENCE=$(mktemp)

  docker run --detach --volume="${PWD}":/etc/ansible/roles/${ROLE_NAME}:ro geerlingguy/docker-${DISTRO}-ansible:latest "${INIT}" > "${CONTAINER_ID}"
  docker exec --tty "$(cat ${CONTAINER_ID})" env TERM=xterm ansible-playbook /etc/ansible/roles/${ROLE_NAME}/tests/test.yml --syntax-check
  docker exec --tty "$(cat ${CONTAINER_ID})" env TERM=xterm sed -i -e "s/#retry_files_enabled/retry_files_enabled/g" /etc/ansible/ansible.cfg
  docker exec --tty "$(cat ${CONTAINER_ID})" env TERM=xterm ansible-playbook -v /etc/ansible/roles/${ROLE_NAME}/tests/test.yml
  docker exec "$(cat ${CONTAINER_ID})" ansible-playbook /etc/ansible/roles/${ROLE_NAME}/tests/test.yml | tee -a ${IDEMPOTENCE}
  tail ${IDEMPOTENCE} | grep -q "changed=0.*failed=0" && (echo "Idempotence test: passed" && exit 0) || (echo "Idempotence test: failed" && die "$CONTAINER_ID")

  # Tests specific to this role
  source tests/validate-results.sh "$DISTRO" "$CONTAINER_ID"

  # Some hints about what to do with the test resources
  echo ""
  echo "For further in-container testing, run:"
  echo "  docker exec -it \"$(cat ${CONTAINER_ID})\" bash"
  echo ""
  echo "To clean up the testing container, run:"
  echo "  docker rm -f \"$(cat ${CONTAINER_ID})\""
  echo ""
  echo "To clean up all system containers, run:"
  echo "  docker rm -f \$(docker ps -a -q)"
  echo ""
done
