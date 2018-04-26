FROM golang:1.10-alpine
MAINTAINER Ron Arts <ron.arts@gmail.com>

# install terraform
RUN apk --update add git bash openssh

ENV TERRAFORM_VERSION=0.11.7
ENV TF_DEV=true
ENV TF_RELEASE=true

WORKDIR $GOPATH/src/github.com/hashicorp/terraform
RUN git clone https://github.com/hashicorp/terraform.git ./ \
 && git checkout v${TERRAFORM_VERSION} \
 && /bin/bash scripts/build.sh \
 && mv pkg/linux_amd64/terraform /usr/local/bin \
 && mkdir -p ~/.terraform.d/plugins \
 && terraform version

# install provider drivers
RUN apk --update add make

# Hetzner cloud
WORKDIR $GOPATH/src/github.com/hetznercloud/terraform-provider-hcloud
RUN git clone https://github.com/hetznercloud/terraform-provider-hcloud ./ \
 && make build \
 && mv $GOPATH/bin/terraform-provider-hcloud  ~/.terraform.d/plugins/terraform-provider-hcloud_v1.2.0 \
 && cd \
 && rm -rf $GOPATH/src/github.com/hetznercloud/terraform-provider-hcloud

# Vultr
WORKDIR $GOPATH/src/github.com/squat/terraform-provider-vultr
RUN git clone https://github.com/squat/terraform-provider-vultr ./ \
 && make \
 && mv $GOPATH/bin/terraform-provider-vultr  ~/.terraform.d/plugins/terraform-provider-vultr_v1.0.0 \
 && cd \
 && rm -rf $GOPATH/src/github.com/squat/terraform-provider-vultr

# Linode
WORKDIR $GOPATH/src/github.com/LinodeContent/terraform-provider-linode
RUN go get -u golang.org/x/crypto/sha3
RUN go get -u github.com/taoh/linodego
RUN git clone https://github.com/LinodeContent/terraform-provider-linode ./ \
 && cd bin/terraform-provider-linode \
 && go build -o terraform-provider-linode \
 && mv terraform-provider-linode  ~/.terraform.d/plugins/terraform-provider-linode_v1.0.0 \
 && cd \
 && rm -rf $GOPATH/src/github.com/squat/terraform-provider-linode

# ProxMox
WORKDIR $GOPATH/src/github.com/raarts/terraform-provider-proxmox
RUN go get -u github.com/Telmate/proxmox-api-go
RUN git clone https://github.com/raarts/terraform-provider-proxmox.git ./ \
 && git checkout remote-api-changes \
 && sed -i -e 's/Telmate/raarts/g' main.go \
 && go build -o terraform-provider-proxmox \
 && cp terraform-provider-proxmox  ~/.terraform.d/plugins/terraform-provider-proxmox_v0.1.0 \
 && cd \
 && rm -rf $GOPATH/src/github.com/raarts/terraform-provider-proxmox

# No longer need the source trees
RUN rm -rf $GOPATH/src/* 

WORKDIR /root

ADD provider.tf .
RUN terraform init

# ------------------------------- Stage 2 --------------------------

FROM alpine:3.7
RUN apk --update add bash

COPY --from=0 /root /root
COPY --from=0 /usr/local/bin/terraform /usr/local/bin

ENTRYPOINT ["terraform"]

