### Templates and parameters for cfssl's JSONs. Definition at the bottom of the Makefile

export TPL_CA
export TPL_CSR



### Parameters for certificate generation, to be passed during the make invocation

export CA_DIR ?= default_CA
export CN



### Makefile functions

RENDERED_CA  := <(echo "$$TPL_CA")
RENDERED_CSR := <(echo "$$TPL_CSR" | CN="$${CN}" envsubst '$${CN}')
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
	@[ ! -f "$(CA_DIR)/$${CN}.pem" ] || { \
		echo "ERROR: certificate already exists for client $${CN}. Aborting"; \
		echo "Certificate path: $(CA_DIR)/$${CN}.pem"; \
		exit 3; \
		}
	@echo "# Making client certificate"
	cfssl gencert -ca $(CA_DIR)/ca.pem -ca-key $(CA_DIR)/ca-key.pem \
    -config=$(RENDERED_CA) -profile="client" -hostname="$${CN}" \
    $(RENDERED_CSR) \
		| cfssljson -bare "$(CA_DIR)/$${CN}"



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
Makefile to manage one or more OpenVPN CAs.

Available commands:
- 'make ca-certs': generate the CA and server certificate, and an OpenVPN PSK
- 'CN=myClient make client-certs': generate a client certificate for myClient

You can control the CA directory location with the CA_DIR variable. E.g.:
- 'CA_DIR=myCAdir make ca-certs'

Default CA_DIR is 'default_CA'
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
