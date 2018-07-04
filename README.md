# OpenVPN CA makefile

This repository provides a makefile that wraps cloudflare's cfssl tool to
provide an alternative to openvpn's easy-rsa.

It's a fork of <https://github.com/mivok/openvpn_cfssl>, which uses scripts
for providing the same functionality. A makefile is used here out of
convenience, to have a ready-to-copy single file to manage CAs in other
repositories (e.g. ansible, puppet).

## Usage

First, install cfssl and openvpn. On a mac with homebrew, you would run:

    brew install cfssl openvpn

Optional: edit `config/csr.json` and change the country and org values for
your certificates. They can be safely left at the defaults however.

Run `./init.sh`. This will generate the ca certificate, a server certificate,
and a tls-auth static key file inside `certs/`:

* ca.pem
* ca-key.pem
* server.pem
* server-key.pem
* ta.key

Copy these files (except for ca-key.pem) to your openvpn server and reference
them in your openvpn config. For example:

    ca ca.pem
    cert server.pem
    key server-key.pem
    tls-auth ta.key 0

## Creating a client

Run `./client.sh CLIENTNAME`. This will create a client certificate and key
inside of `certs/`:

* clientname.pem
* clientname-key.pem

Copy these files, along with `ca.pem` and `ta.key` to your openvpn client and
reference them in your config:

    ca ca.pem
    cert clientname.pem
    key clientname-key.pem
    tls-auth ta.key 1

Note: you can include certificates directly in your client config. See
<https://community.openvpn.net/openvpn/wiki/IOSinline> for an example of how
to do this.
