FROM docker.io/drycc/base:bullseye

ENV GOSU_VERSION="1.14" \
    INI_FILE_VERSION="1.4.1" \
    MARIADB_VERSION="10.8.2"

COPY prebuildfs /

RUN install-packages libnss-wrapper psmisc \
    && install-stack mariadb $MARIADB_VERSION \
    && install-stack ini-file $INI_FILE_VERSION \
    && install-stack mariadb $MARIADB_VERSION \
    && echo "export NSS_WRAPPER_LIB=/usr/lib/`echo $(uname -m)`-linux-gnu/libnss_wrapper.so" >> /opt/drycc/mariadb/profile.d/mariadb.sh \
    && . init-stack \
    && rm -rf \
    /usr/share/doc \
    /usr/share/man \
    /usr/share/info \
    /usr/share/locale \
    /var/lib/apt/lists/* \
    /var/log/* \
    /var/cache/debconf/* \
    /etc/systemd \
    /lib/lsb \
    /lib/udev \
    /usr/lib/`echo $(uname -m)`-linux-gnu/gconv/IBM* \
    /usr/lib/`echo $(uname -m)`-linux-gnu/gconv/EBC* \
    && mkdir -p /usr/share/man/man{1..8} \
    && mkdir /docker-entrypoint-initdb.d /docker-entrypoint-startdb.d

COPY rootfs /
RUN /opt/drycc/scripts/mariadb/postunpack.sh

EXPOSE 3306

USER 1001
ENTRYPOINT [ "init-stack", "/opt/drycc/scripts/mariadb/entrypoint.sh" ]
CMD [ "/opt/drycc/scripts/mariadb/run.sh" ]
