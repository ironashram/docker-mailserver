# Docker Mailserver (ironashram fork)

[![ci::status]][ci::github]

[ci::status]: https://img.shields.io/github/actions/workflow/status/ironashram/docker-mailserver/default_on_push.yml?branch=master&color=blue&label=CI&logo=github&logoColor=white&style=for-the-badge
[ci::github]: https://github.com/ironashram/docker-mailserver/actions

Hard fork of
[docker-mailserver/docker-mailserver](https://github.com/docker-mailserver/docker-mailserver),
diverged deliberately and no longer tracking upstream. It is stripped down to the
feature subset the maintainer actually runs, on a Debian 13 (trixie) base with
Dovecot 2.4.

## What is inside

- Postfix (SMTP, submission, submissions) with postscreen and spoof protection
- Dovecot (IMAP, LMTP, Sieve, optional ManageSieve)
- Rspamd (with optional embedded Redis) for spam filtering and DKIM signing
- Fail2Ban
- File-based account provisioning and the `setup` CLI
- TLS via provided certificates (`SSL_TYPE`), logrotate, logwatch, pflogsumm
- Release update check against this repository's releases

## What was removed from upstream

ClamAV, Amavis, SpamAssassin, Postgrey, PostSRSd, OpenDKIM, OpenDMARC,
policyd-spf, MTA-STS, Fetchmail, Getmail, LDAP, OAuth2, SASLAuthd, POP3, FTS,
and the upstream docs/demo tooling. If you need any of that, use
[upstream](https://github.com/docker-mailserver/docker-mailserver) instead.

## Images

Published to `ghcr.io/ironashram/docker-mailserver` (amd64 only):

- `:edge` - weekly scheduled rebuild on current Debian packages, publish gated
  on the full test suite passing
- Release tags use a year-based scheme (`v26.0.0` = first release of 2026),
  unrelated to upstream's versioning

[Upstream's documentation](https://docker-mailserver.github.io/docker-mailserver/latest/)
still applies to the retained features and their environment variables.
