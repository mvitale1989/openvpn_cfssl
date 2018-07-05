# OpenVPN CA makefile

This repository provides a makefile that wraps cloudflare's cfssl tool to
provide an alternative to openvpn's easy-rsa.

It's a fork of <https://github.com/mivok/openvpn_cfssl>, which uses scripts
for providing the same functionality. A makefile is used here out of
convenience, to have a single, self-documenting, tunable file to quickly
copy into other repositories (e.g. ansible, puppet) for simple CA management.


## Usage

The makefile depends on the following software being present on the machine
using it: cfssl, openvpn (for PSK generation), envsubst, bash (for process
substitution features).

The full procedure to create certs for the CA and two client is as follows:

    # Create the CA and server certificates, plus an OpenVPN PSK for
    # additional security
    make ca-certs
    
    # Create client certificates for `myclient1` and `myclient2`
    CN=myclient1 make client-cert
    CN=myclient2 make client-cert

The above results in the creation of the following files:

    default_CA/ca-key.pem
    default_CA/ca.csr
    default_CA/ca.pem
    default_CA/myclient1-key.pem
    default_CA/myclient1.csr
    default_CA/myclient1.pem
    default_CA/myclient2-key.pem
    default_CA/myclient2.csr
    default_CA/myclient2.pem
    default_CA/ta.key
    default_CA/server-key.pem
    default_CA/server.csr
    default_CA/server.pem


The default values work well, but note that if required, you can optionally
tune a few parameters in the makefile before usage:
- Variables `TPL_CA` and `TPL_CSR`: the skeleton of the cfssl JSONs used for
cert generation. E.g. you can modify the country and organization, according to
the repository you're using the makefile into.
- Variable `CA_DIR`: the destination CA directory, which by default is
`default_CA`. The makefile is also able to read this from the shell env, so you
can specify it either at makefile invocation time
(e.g. `CA_DIR=./myCAdir make ca-certs`) or by exporting the variable before of
the makefile usage (e.g. `export CA_DIR=./myCAdir; make ca-certs`).


## OpenVPN configuration

On the server, you can use the following configuration snippet, after copying
the required CA and server certificates in OpenVPN's configuration directory:

    ca ca.pem
    cert server.pem
    key server-key.pem
    tls-auth ta.key 0

Note that it's not recommended nor needed to copy the `ca-key.pem` file, into
your server's OpenVPN config directory.

On the client, you can use the folowing configuration snippet, after copying
the required CA and client certificates in OpenVPN's configuration directory:

    ca ca.pem
    cert clientname.pem
    key clientname-key.pem
    tls-auth ta.key 1

Note: for both configuration, you might instead prefer to inline the
certificates in your OpenVPN's config file, instead of copying them separately.
See <https://community.openvpn.net/openvpn/wiki/IOSinline> for an example of
how to do this.
