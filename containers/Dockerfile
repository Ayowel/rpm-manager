ARG BASE_IMAGE=rockylinux:8
FROM $BASE_IMAGE

RUN dnf install -y xz libxml2 diffutils findutils 'dnf-command(download)' && \
      dnf clean all

COPY --chown=0:0 build/rpm-manager /bin/rpm-manager

WORKDIR /mnt
ENTRYPOINT [ "/bin/rpm-manager" ]
CMD [ "--help" ]
