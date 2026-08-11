# Docker Mailserver (ironashram fork)

[![ci::status]][ci::github] [![documentation::badge]][documentation::web]

[ci::status]: https://img.shields.io/github/actions/workflow/status/ironashram/docker-mailserver/default_on_push.yml?branch=master&color=blue&label=CI&logo=github&logoColor=white&style=for-the-badge
[ci::github]: https://github.com/ironashram/docker-mailserver/actions
[documentation::badge]: https://img.shields.io/badge/DOCUMENTATION-GH%20PAGES-0078D4?style=for-the-badge&logo=googledocs&logoColor=white
[documentation::web]: https://docker-mailserver.github.io/docker-mailserver/latest/

This is a hard fork of
[docker-mailserver/docker-mailserver](https://github.com/docker-mailserver/docker-mailserver).
It has diverged deliberately and no longer tracks upstream. Reasons:

- Upstream's release cadence stalled (last release August 2025) while the base image
  stayed on Debian 12, which left regular security support in July 2026.
- This fork merged upstream's completed but unmerged Debian 13 + Dovecot 2.4 migration
  branch (upstream PR #4536) and builds on trixie.
- Images publish to `ghcr.io/ironashram/docker-mailserver` (`:edge`), amd64 only.
  A weekly scheduled rebuild pulls current Debian packages, and publishing is gated on
  the full test suite passing.
- CI is self-contained: local reusable workflows, all actions pinned by commit SHA,
  no DockerHub publishing, docs deploy and stale bot workflows removed.
- Maintained for personal infrastructure. Features beyond what the maintainer runs
  are still present but untested here - upstream's documentation still describes them.

## :page_with_curl: About

A production-ready fullstack but simple containerized mail server (SMTP, IMAP, LDAP, Anti-spam, Anti-virus, etc.).
- Only configuration files, no SQL database. Keep it simple and versioned. Easy to deploy and upgrade.
- Originally created by [@tomav](https://github.com/tomav), this project is now maintained by volunteers since January 2021.

## <!-- Adds a thin line break separator style -->

> [!TIP]
> Be sure to read [our documentation][documentation::web]. It provides guidance on initial setup of your mail server.

> [!IMPORTANT]
> If you have issues, please search through [the documentation][documentation::web] **for your version** before opening an issue.
> 
> The issue tracker is for issues, not for personal support.  
> Make sure the version of the documentation matches the image version you're using!

## :link: Links to Useful Resources

1. [FAQ](https://docker-mailserver.github.io/docker-mailserver/latest/faq/)
2. [Usage](https://docker-mailserver.github.io/docker-mailserver/latest/usage/)
3. [Examples](https://docker-mailserver.github.io/docker-mailserver/latest/examples/tutorials/basic-installation/)
4. [Issues and Contributing](https://docker-mailserver.github.io/docker-mailserver/latest/contributing/issues-and-pull-requests/)
5. [Release Notes](./CHANGELOG.md)
6. [Environment Variables](https://docker-mailserver.github.io/docker-mailserver/latest/config/environment/)
7. [Updating](https://docker-mailserver.github.io/docker-mailserver/latest/faq/#how-do-i-update-dms)

## :package: Included Services

- [Postfix](http://www.postfix.org) with SMTP or LDAP authentication and support for [extension delimiters](https://docker-mailserver.github.io/docker-mailserver/latest/config/account-management/overview/#aliases)
- [Dovecot](https://www.dovecot.org) with SASL, IMAP, POP3, LDAP, [basic Sieve support](https://docker-mailserver.github.io/docker-mailserver/latest/config/advanced/mail-sieve) and [quotas](https://docker-mailserver.github.io/docker-mailserver/latest/config/account-management/overview/#quotas)
- [Rspamd](https://rspamd.com/)
- [Amavis](https://www.amavis.org/)
- [SpamAssassin](http://spamassassin.apache.org/) supporting custom rules
- [ClamAV](https://www.clamav.net/) with automatic updates
- [OpenDKIM](http://www.opendkim.org) & [OpenDMARC](https://github.com/trusteddomainproject/OpenDMARC)
- [Fail2ban](https://www.fail2ban.org/)
- [Fetchmail](http://www.fetchmail.info/fetchmail-man.html)
- [Getmail6](https://getmail6.org/documentation.html)
- [Postscreen](http://www.postfix.org/POSTSCREEN_README.html)
- [Postgrey](https://postgrey.schweikert.ch/)
- Support for [LetsEncrypt](https://letsencrypt.org/), manual and self-signed certificates
- A [setup script](https://docker-mailserver.github.io/docker-mailserver/latest/config/setup.sh) for easy configuration and maintenance
- SASLauthd with LDAP authentication
- OAuth2 authentication (_via `XOAUTH2` or `OAUTHBEARER` SASL mechanisms_)
