# shellcheck disable=SC2314,SC2317

load "${REPOSITORY_ROOT}/test/test_helper/common"

BATS_TEST_NAME_PREFIX='test helper functions:'

@test "repeat_until_success_or_timeout returns instantly on success" {
  SECONDS=0
  repeat_until_success_or_timeout 1 true
  [[ ${SECONDS} -le 1 ]]
}

@test "repeat_until_success_or_timeout waits for timeout on persistent failure" {
  SECONDS=0
  run repeat_until_success_or_timeout 2 false
  [[ ${SECONDS} -ge 2 ]]
  assert_failure
  assert_output --partial "Timed out on command"
}

@test "repeat_until_success_or_timeout aborts immediately on fatal failure" {
  SECONDS=0
  run repeat_until_success_or_timeout --fatal-test false 2 false
  [[ ${SECONDS} -le 1 ]]
  assert_failure
  assert_output --partial "early aborting"
}

@test "repeat_until_success_or_timeout expects integer timeout" {
  run repeat_until_success_or_timeout 1 true
  assert_success

  run repeat_until_success_or_timeout timeout true
  assert_failure

  run repeat_until_success_or_timeout --fatal-test true timeout true
  assert_failure
}

@test "run_until_success_or_timeout returns instantly on success" {
  SECONDS=0
  run_until_success_or_timeout 2 true
  [[ ${SECONDS} -le 1 ]]
  assert_success
}

@test "run_until_success_or_timeout waits for timeout on persistent failure" {
  SECONDS=0
  ! run_until_success_or_timeout 2 false
  [[ ${SECONDS} -ge 2 ]]
  assert_failure
}

@test "repeat_in_container_until_success_or_timeout fails immediately for non-running container" {
  SECONDS=0
  ! repeat_in_container_until_success_or_timeout 10 name-of-non-existing-container true
  [[ ${SECONDS} -le 1 ]]
}

@test "repeat_in_container_until_success_or_timeout run command in container" {
  local CONTAINER_NAME
  CONTAINER_NAME=$(docker run --rm -d alpine sleep 100)
  SECONDS=0
  ! repeat_in_container_until_success_or_timeout 10 "${CONTAINER_NAME}" sh -c "echo '${CONTAINER_NAME}' > /tmp/marker"
  [[ ${SECONDS} -le 1 ]]
  run docker exec "${CONTAINER_NAME}" cat /tmp/marker
  assert_output "${CONTAINER_NAME}"
}

@test "container_is_running" {
  local CONTAINER_NAME
  CONTAINER_NAME=$(docker run --rm -d alpine sleep 100)
  container_is_running "${CONTAINER_NAME}"
  docker rm -f "${CONTAINER_NAME}"
  ! container_is_running "${CONTAINER_NAME}"
}

@test "wait_for_smtp_port_in_container aborts wait after timeout" {
  local CONTAINER_NAME
  CONTAINER_NAME=$(docker run --rm -d alpine sleep 100)
  SECONDS=0
  TEST_TIMEOUT_IN_SECONDS=2 run wait_for_smtp_port_in_container "${CONTAINER_NAME}"
  [[ ${SECONDS} -ge 2 ]]
  assert_failure
  assert_output --partial "Timed out on command"
}

# NOTE: Test requires external network access available
@test "wait_for_smtp_port_in_container returns immediately when port found" {
  local CONTAINER_NAME
  CONTAINER_NAME=$(docker run --rm -d alpine sh -c "sleep 100")

  docker exec "${CONTAINER_NAME}" apk add netcat-openbsd
  docker exec "${CONTAINER_NAME}" nc -l 25 &

  SECONDS=0
  TEST_TIMEOUT_IN_SECONDS=5 run wait_for_smtp_port_in_container "${CONTAINER_NAME}"
  [[ ${SECONDS} -lt 5 ]]
  assert_success
}

@test "wait_for_finished_setup_in_container" {
  # variable not local to make visible to teardown
  local PRIVATE_CONFIG
  PRIVATE_CONFIG=$(duplicate_config_for_container .)

  CONTAINER_NAME=$(docker run -d --rm \
    -v "${PRIVATE_CONFIG}":/tmp/docker-mailserver \
    -h mail.my-domain.com \
    -t "${NAME}")

  teardown() { docker rm -f "${CONTAINER_NAME}"; }

  # the setup should not be finished immediately after starting
  ! TEST_TIMEOUT_IN_SECONDS=0 wait_for_finished_setup_in_container "${CONTAINER_NAME}"

  # but it will finish eventually
  SECONDS=1

  wait_for_finished_setup_in_container "${CONTAINER_NAME}"
  [[ ${SECONDS} -gt 0 ]]
}

@test "duplicate_config_for_container" {
  local path
  path=$(duplicate_config_for_container duplicate_config_test)

  run cat "${path}/marker"
  assert_line "This marker file is there to identify the correct config being copied"

  run duplicate_config_for_container non-existent-source-folder "${BATS_TEST_NAME}2"
  assert_failure
}

@test "container_has_service_running/wait_for_service" {
  local PRIVATE_CONFIG
  PRIVATE_CONFIG=$(duplicate_config_for_container .)

  # variable not local to make visible to teardown
  CONTAINER_NAME=$(docker run -d --rm \
    -v "${PRIVATE_CONFIG}":/tmp/docker-mailserver \
    -h mail.my-domain.com \
    -t "${NAME}")

  teardown() { docker rm -f "${CONTAINER_NAME}"; }

  # pick a service that was not started
  ! container_has_service_running "${CONTAINER_NAME}" rspamd

  # wait for a service that should be started
  wait_for_service "${CONTAINER_NAME}" postfix

  # shut down the service
  docker exec "${CONTAINER_NAME}" supervisorctl stop postfix

  # now it should be off
  SECONDS=0
  TEST_TIMEOUT_IN_SECONDS=5 run wait_for_service "${CONTAINER_NAME}" postfix
  [[ ${SECONDS} -ge 5 ]]
  assert_failure
}

