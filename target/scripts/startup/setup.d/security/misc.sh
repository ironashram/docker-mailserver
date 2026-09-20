#!/bin/bash

function _setup_security_stack() {
  _log 'debug' 'Setting up Security Stack'

  __setup__security__postscreen
  __setup__security__fail2ban
}

function __setup__security__postscreen() {
  _log 'debug' 'Configuring Postscreen'
  sed -i \
    -e "s|postscreen_dnsbl_action = enforce|postscreen_dnsbl_action = ${POSTSCREEN_ACTION}|" \
    -e "s|postscreen_greet_action = enforce|postscreen_greet_action = ${POSTSCREEN_ACTION}|" \
    -e "s|postscreen_bare_newline_action = enforce|postscreen_bare_newline_action = ${POSTSCREEN_ACTION}|" /etc/postfix/main.cf

  if [[ ${ENABLE_DNSBL} -eq 0 ]]; then
    _log 'debug' 'Disabling Postscreen DNSBLs'
    postconf 'postscreen_dnsbl_action = ignore'
    postconf 'postscreen_dnsbl_sites = '
  else
    _log 'debug' 'Postscreen DNSBLs are enabled'
  fi
}

function __setup__security__fail2ban() {
  if [[ ${ENABLE_FAIL2BAN} -eq 1 ]]; then
    _log 'debug' 'Enabling and configuring Fail2Ban'

    if [[ -e /tmp/docker-mailserver/fail2ban-fail2ban.cf ]]; then
      _log 'trace' 'Custom fail2ban-fail2ban.cf found'
      cp /tmp/docker-mailserver/fail2ban-fail2ban.cf /etc/fail2ban/fail2ban.local
    fi

    if [[ -e /tmp/docker-mailserver/fail2ban-jail.cf ]]; then
      _log 'trace' 'Custom fail2ban-jail.cf found'
      cp /tmp/docker-mailserver/fail2ban-jail.cf /etc/fail2ban/jail.d/user-jail.local
    fi

    if [[ ${FAIL2BAN_BLOCKTYPE} != 'reject' ]]; then
      _log 'trace' "Setting fail2ban blocktype to 'drop'"
      echo -e '[Init]\nblocktype = drop' >/etc/fail2ban/action.d/nftables-common.local
    fi

    echo '[Definition]' >/etc/fail2ban/filter.d/custom.conf

    _log 'trace' 'Configuring fail2ban logrotate rotate count and interval'
    [[ ${LOGROTATE_COUNT} -ne 4 ]]          && sedfile -i "s|rotate 4$|rotate ${LOGROTATE_COUNT}|" /etc/logrotate.d/fail2ban
    [[ ${LOGROTATE_INTERVAL} != "weekly" ]] && sedfile -i "s|weekly$|${LOGROTATE_INTERVAL}|"       /etc/logrotate.d/fail2ban
  else
    _log 'debug' 'Fail2Ban is disabled'
    rm -f /etc/logrotate.d/fail2ban
  fi
}

# If `SPAM_SUBJECT` is not empty, we create a Sieve script that alters the `Subject`
# header, in order to prepend a user-defined string.
function _setup_spam_subject() {
  if [[ -z ${SPAM_SUBJECT} ]]
  then
    _log 'debug' 'Spam subject is not set - no prefix will be added to spam e-mails'
  else
    _log 'debug' "Spam subject is set - the prefix '${SPAM_SUBJECT}' will be added to spam e-mails"

    _log 'trace' "Enabling Sieve extension 'editheader'"
    sedfile -i -E 's|^( *editheader =).*|\1 yes|g' /etc/dovecot/conf.d/90-sieve.conf

    _log 'trace' "Adding global (before) Sieve script for subject rewrite"
    # This directory contains Sieve scripts that are executed before user-defined Sieve
    # scripts run.
    local DOVECOT_SIEVE_GLOBAL_BEFORE_DIR='/usr/lib/dovecot/sieve-global/before'
    local DOVECOT_SIEVE_FILE='spam_subject'
    readonly DOVECOT_SIEVE_GLOBAL_BEFORE_DIR DOVECOT_SIEVE_FILE

    mkdir -p "${DOVECOT_SIEVE_GLOBAL_BEFORE_DIR}"
    # ref: https://superuser.com/a/1502589
    cat >"${DOVECOT_SIEVE_GLOBAL_BEFORE_DIR}/${DOVECOT_SIEVE_FILE}.sieve" << EOF
require ["editheader","variables"];

if anyof (header :contains "X-Spam-Flag" "YES",
          header :contains "X-Spam" "Yes")
{
    # Match the entire subject ...
    if header :matches "Subject" "*" {
        # ... to get it in a match group that can then be stored in a variable:
        set "subject" "\${1}";
    }

    # We can't "replace" a header, but we can delete (all instances of) it and
    # re-add (a single instance of) it:
    deleteheader "Subject";

    # Note that the header is added ":last" (so it won't appear before possible
    # "Received" headers).
    addheader :last "Subject" "${SPAM_SUBJECT}\${subject}";
}
EOF

    sievec "${DOVECOT_SIEVE_GLOBAL_BEFORE_DIR}/${DOVECOT_SIEVE_FILE}.sieve"
    chown dovecot:root "${DOVECOT_SIEVE_GLOBAL_BEFORE_DIR}/${DOVECOT_SIEVE_FILE}."{sieve,svbin}

    cat >>/etc/dovecot/conf.d/90-sieve.conf <<EOF

sieve_script spam_subject {
    type = before
    path = ${DOVECOT_SIEVE_GLOBAL_BEFORE_DIR}/${DOVECOT_SIEVE_FILE}.sieve
}
EOF
  fi
}

# We can use Sieve to move spam emails to the "Junk" folder.
function _setup_spam_to_junk() {
  if [[ ${MOVE_SPAM_TO_JUNK} -eq 1 ]]; then
    _log 'debug' 'Spam emails will be moved to the Junk folder'
    mkdir -p /usr/lib/dovecot/sieve-global/after/
    cat >/usr/lib/dovecot/sieve-global/after/70-spam_to_junk.sieve << EOF
require ["fileinto","special-use"];

if anyof (header :contains "X-Spam-Flag" "YES",
          header :contains "X-Spam" "Yes") {
    fileinto :specialuse "\\\\Junk" "Junk";
}
EOF
    sievec /usr/lib/dovecot/sieve-global/after/70-spam_to_junk.sieve
    chown dovecot:root /usr/lib/dovecot/sieve-global/after/70-spam_to_junk.{sieve,svbin}

    cat >>/etc/dovecot/conf.d/90-sieve.conf <<"EOF"

# Moves e-mails marked with spam headers into Junk
sieve_script spam_to_junk {
    type = after
    path = /usr/lib/dovecot/sieve-global/after/70-spam_to_junk.sieve
}
EOF
  else
    _log 'debug' 'Spam emails will not be moved to the Junk folder'
  fi
}

function _setup_spam_mark_as_read() {
  if [[ ${MARK_SPAM_AS_READ} -eq 1 ]]; then
    _log 'debug' 'Spam emails will be marked as read'
    mkdir -p /usr/lib/dovecot/sieve-global/after/

    # Header support: `X-Spam-Flag` (SpamAssassin), `X-Spam` (Rspamd)
    cat >/usr/lib/dovecot/sieve-global/after/60-spam_mark_as_read.sieve << EOF
require ["mailbox","imap4flags"];

if anyof (header :contains "X-Spam-Flag" "YES",
          header :contains "X-Spam" "Yes") {
    setflag "\\\\Seen";
}
EOF
    sievec /usr/lib/dovecot/sieve-global/after/60-spam_mark_as_read.sieve
    chown dovecot:root /usr/lib/dovecot/sieve-global/after/60-spam_mark_as_read.{sieve,svbin}

    cat >>/etc/dovecot/conf.d/90-sieve.conf <<"EOF"

# Moves e-mails marked with spam headers into Junk
sieve_script spam_mark_as_read {
    type = after
    path = /usr/lib/dovecot/sieve-global/after/60-spam_mark_as_read.sieve
}
EOF
  else
    _log 'debug' 'Spam emails will not be marked as read'
  fi
}
