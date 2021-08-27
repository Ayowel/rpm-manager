ARG BASE_IMAGE=centos
FROM $BASE_IMAGE

ARG ENABLED_REPO=powertools
ARG SHELLCHECK_VERSION=v0.7.2
ARG SHELLCHECK_SOURCE=https://github.com/koalaman/shellcheck/releases/download/${SHELLCHECK_VERSION}/shellcheck-${SHELLCHECK_VERSION}.linux.x86_64.tar.xz
ARG KCOV_VERSION=pre-v40
ARG KCOV_SOURCE=https://github.com/SimonKagstrom/kcov/releases/download/${KCOV_VERSION}/kcov-amd64.tar.gz

RUN dnf install -y epel-release && \
      dnf install -y --enablerepo "$ENABLED_REPO" xz git make doxygen npm libxml2 binutils diffutils yamllint 'dnf-command(download)' && \
      npm install --global bats && \
      curl -Lo shellcheck.tar.xz "${SHELLCHECK_SOURCE}" && \
      unxz shellcheck.tar.xz && \
      tar -xvf shellcheck.tar --strip-components 1 -C /usr/bin && \
      rm -f shellcheck.tar && \
      ln -sf /usr/lib64/libopcodes-2.30-*.el8.so /usr/lib64/libopcodes-2.30-system.so && \
      ln -sf /usr/lib64/libbfd-2.30-*.el8.so /usr/lib64/libbfd-2.30-system.so && \
      curl -Lo kcov.tar.gz "$KCOV_SOURCE" && \
      tar -xvzf kcov.tar.gz -C / && \
      rm -f kcov.tar.gz && \
      useradd -u 1000 dev

USER dev
WORKDIR /mnt
