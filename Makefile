### Templates and parameters for cfssl's JSONs. Definition at the bottom of the Makefile

export TPL_CA
export TPL_CSR


### Parameters for certificate generation, to be passed during the make invocation

export CA_DIR ?= .
export CN


### Makefile functions

RELEASE      := 0.1.0
RENDERED_CA  := <(echo "$$TPL_CA")
RENDERED_CSR := <(echo "$$TPL_CSR" | CN="$${CN}" envsubst '$${CN}')
CLIENTS_DIR  := $(CA_DIR)/clients
.PHONY: help ca-certs client-cert

help:
	@echo "$$USAGE_TEXT"

ca-certs: common
	@echo "# Creating directory for CA: $(CA_DIR)"
	mkdir -p $(CA_DIR)
	@echo "# Making CA certificate"
	CN=CA && \
		cfssl genkey --initca $(RENDERED_CSR) \
		| cfssljson -bare $(CA_DIR)/ca
	@echo "# Making server certificate"
	CN=server && \
		cfssl gencert -ca $(CA_DIR)/ca.pem \
		-ca-key $(CA_DIR)/ca-key.pem -config=$(RENDERED_CA) \
		-profile="server" -hostname="server" $(RENDERED_CSR) \
		| cfssljson -bare $(CA_DIR)/server
	@echo "# Making OpenVPN PSK"
	openvpn --genkey --secret $(CA_DIR)/ta.key

client-cert: common checkenv-CN
	@echo "# Creating directory for clients: $(CLIENTS_DIR)"
	mkdir -p $(CLIENTS_DIR)
	@[ ! -f "$(CLIENTS_DIR)/$${CN}.pem" ] || { \
		echo "ERROR: certificate already exists for client $${CN}. Aborting"; \
		echo "Certificate path: $(CLIENTS_DIR)/$${CN}.pem"; \
		exit 3; \
		}
	@echo "# Making client certificate"
	cfssl gencert -ca $(CA_DIR)/ca.pem -ca-key $(CA_DIR)/ca-key.pem \
    -config=$(RENDERED_CA) -profile="client" -hostname="$${CN}" \
    $(RENDERED_CSR) \
		| cfssljson -bare "$(CLIENTS_DIR)/$${CN}"





### Utility Makefile functions and definitions

SHELL         := /bin/bash
.DEFAULT_GOAL := help

.PHONY: common
common: checkcmd-cfssl checkcmd-openvpn checkcmd-envsubst

checkenv-%:
	@echo -n "Checking existence of var $*..."
	@[ -n "$$$*" ] && echo OK || { \
		echo "NOT FOUND"; \
		echo "ERROR: variable $* is required for this make goal."; \
		exit 1; \
		}

checkcmd-%:
	@echo -n "Checking existence of required executable, $*..."
	@which $* >/dev/null && echo OK || { \
		echo "NOT FOUND"; \
		echo "ERROR: command $* is required for this make goal."; \
		exit 2; \
		}

export USAGE_TEXT
define USAGE_TEXT
mvitale1989/openvpn_cfssl
Version: $(RELEASE)
Website: https://github.com/mvitale1989/openvpn_cfssl

Makefile to manage one or more OpenVPN CAs.
Available commands:
- 'make ca-certs': generate the CA and server certificate, and an OpenVPN PSK.
- 'CN=myClient make client-cert': generate a client certificate for myClient.

Available env var parameters:
- 'CA_DIR=my/CA/dir make ca-certs': change the directory where certificates are
  written to and read from. Default value is current directory.
endef





### Definitions of the CFSSL JSON templates

define TPL_CA
{
    "signing": {
        "profiles": {
            "server": {
                "expiry": "43800h",
                "usages": [
                    "digital signature",
                    "key encipherment",
                    "server auth"
                ]
            },
            "client": {
                "expiry": "43800h",
                "usages": [
                    "signing",
                    "client auth"
                ]
            }
        }
    }
}
endef
define TPL_CSR
{
    "key": {
        "algo": "rsa",
        "size": 2048
    },
    "cn": "$${CN}",
    "names": [
        {
            "C": "US",
            "O": "OpenVPN"
        }
    ]
}
endef
