#!/bin/bash

# shellcheck disable=SC2034
declare -A VARS

function _early_variables_setup() {
  __ensure_valid_log_level
  __environment_variables_from_files
  _obtain_hostname_and_domainname
  __environment_variables_backwards_compatibility
  __environment_variables_general_setup

  __environment_variables_export
}

# This function handles variables that are deprecated. This allows a
# smooth transition period, without the need of removing a variable
# completely with a single version.
function __environment_variables_backwards_compatibility() {
  if [[ -n ${SA_SPAM_SUBJECT:-} ]]; then
    _log 'error' "'SA_SPAM_SUBJECT' has been renamed to 'SPAM_SUBJECT' since DMS v16"
  fi

  # TODO this can be uncommented in a PR handling the HOSTNAME/DOMAINNAME issue
  # TODO see check_for_changes.sh and dns.sh
  # if [[ -n ${OVERRIDE_HOSTNAME:-} ]]
  # then
  #   _log 'warn' "'OVERRIDE_HOSTNAME' is deprecated (and will be removed in v13.0.0) => use 'DMS_FQDN' instead"
  #   [[ -z ${DMS_FQDN} ]] && DMS_FQDN=${OVERRIDE_HOSTNAME}
  # fi
}

# This function sets almost all environment variables. This involves setting
# a default if no value was provided and writing the variable and its value
# to the VARS map.
function __environment_variables_general_setup() {
  _log 'debug' 'Handling general environment variable setup'

  # these variables must be defined first
  # they are used as default values for other variables

  VARS[POSTMASTER_ADDRESS]="${POSTMASTER_ADDRESS:=postmaster@${DOMAINNAME}}"
  VARS[REPORT_RECIPIENT]="${REPORT_RECIPIENT:=${POSTMASTER_ADDRESS}}"
  VARS[REPORT_SENDER]="${REPORT_SENDER:=mailserver-report@${HOSTNAME}}"
  VARS[DMS_VMAIL_UID]="${DMS_VMAIL_UID:=5000}"
  VARS[DMS_VMAIL_GID]="${DMS_VMAIL_GID:=5000}"

  # user-customizable are next

  _log 'trace' 'Setting anti-spam environment variables'

  VARS[FAIL2BAN_BLOCKTYPE]="${FAIL2BAN_BLOCKTYPE:=drop}"
  VARS[MOVE_SPAM_TO_JUNK]="${MOVE_SPAM_TO_JUNK:=1}"
  VARS[MARK_SPAM_AS_READ]="${MARK_SPAM_AS_READ:=0}"
  VARS[POSTSCREEN_ACTION]="${POSTSCREEN_ACTION:=enforce}"
  VARS[RSPAMD_CHECK_AUTHENTICATED]="${RSPAMD_CHECK_AUTHENTICATED:=0}"
  VARS[RSPAMD_GREYLISTING]="${RSPAMD_GREYLISTING:=0}"
  VARS[RSPAMD_HFILTER]="${RSPAMD_HFILTER:=1}"
  VARS[RSPAMD_HFILTER_HOSTNAME_UNKNOWN_SCORE]="${RSPAMD_HFILTER_HOSTNAME_UNKNOWN_SCORE:=6}"
  VARS[RSPAMD_NEURAL]="${RSPAMD_NEURAL:=0}"
  VARS[RSPAMD_LEARN]="${RSPAMD_LEARN:=0}"
  VARS[SPAM_SUBJECT]=${SPAM_SUBJECT:=}
  VARS[SPOOF_PROTECTION]="${SPOOF_PROTECTION:=0}"

  _log 'trace' 'Setting service-enabling environment variables'

  VARS[ENABLE_DNSBL]="${ENABLE_DNSBL:=0}"
  VARS[ENABLE_FAIL2BAN]="${ENABLE_FAIL2BAN:=0}"
  VARS[ENABLE_MANAGESIEVE]="${ENABLE_MANAGESIEVE:=0}"
  VARS[ENABLE_IMAP]="${ENABLE_IMAP:=1}"
  VARS[ENABLE_RSPAMD]="${ENABLE_RSPAMD:=0}"
  VARS[ENABLE_RSPAMD_REDIS]="${ENABLE_RSPAMD_REDIS:=${ENABLE_RSPAMD}}"
  VARS[ENABLE_UPDATE_CHECK]="${ENABLE_UPDATE_CHECK:=1}"

  _log 'trace' 'Setting IP, DNS and SSL environment variables'

  VARS[DEFAULT_RELAY_HOST]="${DEFAULT_RELAY_HOST:=}"
  # VARS[DMS_FQDN]="${DMS_FQDN:=}"
  # VARS[DMS_DOMAINNAME]="${DMS_DOMAINNAME:=}"
  # VARS[DMS_HOSTNAME]="${DMS_HOSTNAME:=}"
  VARS[NETWORK_INTERFACE]="${NETWORK_INTERFACE:=eth0}"
  VARS[OVERRIDE_HOSTNAME]="${OVERRIDE_HOSTNAME:-}"
  VARS[RELAY_HOST]="${RELAY_HOST:=}"
  VARS[SSL_TYPE]="${SSL_TYPE:=}"
  VARS[TLS_LEVEL]="${TLS_LEVEL:=modern}"

  _log 'trace' 'Setting Dovecot- and Postfix-specific environment variables'

  VARS[DOVECOT_INET_PROTOCOLS]="${DOVECOT_INET_PROTOCOLS:=all}"
  VARS[DOVECOT_MAILBOX_FORMAT]="${DOVECOT_MAILBOX_FORMAT:=maildir}"
  VARS[DOVECOT_TLS]="${DOVECOT_TLS:=no}"

  VARS[POSTFIX_DAGENT]="${POSTFIX_DAGENT:=}"
  VARS[POSTFIX_INET_PROTOCOLS]="${POSTFIX_INET_PROTOCOLS:=all}"
  VARS[POSTFIX_MAILBOX_SIZE_LIMIT]="${POSTFIX_MAILBOX_SIZE_LIMIT:=0}"
  VARS[POSTFIX_MESSAGE_SIZE_LIMIT]="${POSTFIX_MESSAGE_SIZE_LIMIT:=10240000}" # ~10 MB
  VARS[POSTFIX_REJECT_UNKNOWN_CLIENT_HOSTNAME]="${POSTFIX_REJECT_UNKNOWN_CLIENT_HOSTNAME:=0}"

  _log 'trace' 'Setting miscellaneous environment variables'

  VARS[ACCOUNT_PROVISIONER]="${ACCOUNT_PROVISIONER:=FILE}"
  VARS[DMS_CONFIG_POLL]="${DMS_CONFIG_POLL:=2}"
  VARS[LOG_LEVEL]="${LOG_LEVEL:=info}"
  VARS[LOGROTATE_INTERVAL]="${LOGROTATE_INTERVAL:=weekly}"
  VARS[LOGROTATE_COUNT]="${LOGROTATE_COUNT:=4}"
  VARS[LOGWATCH_INTERVAL]="${LOGWATCH_INTERVAL:=none}"
  VARS[LOGWATCH_RECIPIENT]="${LOGWATCH_RECIPIENT:=${REPORT_RECIPIENT}}"
  VARS[LOGWATCH_SENDER]="${LOGWATCH_SENDER:=${REPORT_SENDER}}"
  VARS[PERMIT_DOCKER]="${PERMIT_DOCKER:=none}"
  VARS[PFLOGSUMM_RECIPIENT]="${PFLOGSUMM_RECIPIENT:=${REPORT_RECIPIENT}}"
  VARS[PFLOGSUMM_SENDER]="${PFLOGSUMM_SENDER:=${REPORT_SENDER}}"
  VARS[PFLOGSUMM_TRIGGER]="${PFLOGSUMM_TRIGGER:=none}"
  VARS[SMTP_ONLY]="${SMTP_ONLY:=0}"
  VARS[SUPERVISOR_LOGLEVEL]="${SUPERVISOR_LOGLEVEL:=warn}"
  VARS[TZ]="${TZ:=}"
  VARS[UPDATE_CHECK_INTERVAL]="${UPDATE_CHECK_INTERVAL:=1d}"

  _log 'trace' 'Setting environment variables that require other variables to be set first'

  # The Dovecot Quotas feature is presently only supported with the default FILE account provisioner,
  # Enforce disabling the feature, unless it's been explicitly set via ENV (to avoid mismatch between
  # explicit ENV and sourcing from /etc/dms-settings)
  if [[ ${ACCOUNT_PROVISIONER} != 'FILE' || ${SMTP_ONLY} -eq 1 ]] && [[ ${ENABLE_QUOTAS:-1} -eq 1 ]]; then
    _log 'debug' "The 'ENABLE_QUOTAS' feature is enabled (by default) but is not compatible with your config. Disabling"
    VARS[ENABLE_QUOTAS]="${ENABLE_QUOTAS:=0}"
  else
    VARS[ENABLE_QUOTAS]="${ENABLE_QUOTAS:=1}"
  fi
}

# `LOG_LEVEL` must be set early to correctly filter calls to `scripts/helpers/log.sh:_log()`
function __ensure_valid_log_level() {
  if [[ ! ${LOG_LEVEL:-info} =~ ^(trace|debug|info|warn|error)$ ]]; then
    _log 'warn' "Log level '${LOG_LEVEL}' is invalid (falling back to default: 'info')"
    LOG_LEVEL='info'
  fi
}

# This function Writes the contents of the `VARS` map (associative array)
# to locations where they can be sourced from (e.g. `/etc/dms-settings`)
# or where they can be used by Bash directly (e.g. `/root/.bashrc`).
function __environment_variables_export() {
  _log 'debug' "Exporting environment variables now (creating '/etc/dms-settings')"

  : >/root/.bashrc     # make DMS variables available in login shells and their subprocesses
  : >/etc/dms-settings # this file can be sourced by other scripts

  local VAR
  for VAR in "${!VARS[@]}"; do
    echo "export ${VAR}='${VARS[${VAR}]}'" >>/root/.bashrc
    echo "${VAR}='${VARS[${VAR}]}'"        >>/etc/dms-settings
  done

  sort -o /root/.bashrc     /root/.bashrc
  sort -o /etc/dms-settings /etc/dms-settings
}

# This function sets any environment variable with a value from a referenced file
# when an equivalent ENV with a `__FILE` suffix exists with a valid file path as the value.
function __environment_variables_from_files() {
  # Iterate through all ENV found with a `__FILE` suffix:
  while read -r ENV_WITH_FILE_REF; do
    # Store the value of the `__FILE` ENV:
    local FILE_PATH="${!ENV_WITH_FILE_REF}"
    # Store the ENV name without the `__FILE` suffix:
    local TARGET_ENV_NAME="${ENV_WITH_FILE_REF/__FILE/}"
    # Assign a value representing a variable name,
    # `-n` will alias `TARGET_ENV` so that it is treated as if it were the referenced variable:
    local -n TARGET_ENV="${TARGET_ENV_NAME}"

    # Skip if the target ENV is already set:
    if [[ -v TARGET_ENV ]]; then
      _log 'warn' "ENV value will not be sourced from '${ENV_WITH_FILE_REF}' since '${TARGET_ENV_NAME}' is already set"
      continue
    fi

    # Skip if the file path provided is invalid:
    if [[ ! -f ${FILE_PATH} ]]; then
      _log 'warn' "File defined for secret '${TARGET_ENV_NAME}' with path '${FILE_PATH}' does not exist"
      continue
    fi

    # Read the value from a file and assign it to the intended ENV:
    _log 'info' "Getting secret '${TARGET_ENV_NAME}' from '${FILE_PATH}'"
    TARGET_ENV="$(< "${FILE_PATH}")"
  done < <(env | grep -Po '^.+?__FILE')
}
