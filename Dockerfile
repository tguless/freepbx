#FROM ../asterisk
#FROM flaviostutz/asterisk:16.18.0.1
FROM mybaseimage:latest

ENV RTP_START '18000'
ENV RTP_FINISH '18100'
ENV ADMIN_PASSWORD ''
ENV USE_CHAN_SIP 'false'
ENV ENABLE_AUTO_RESTORE 'true'
ENV BACKUP_TIMER '3600'
ENV FAIL2BAN_ENABLE 'true'
ENV FAIL2BAN_FINDTIME '600'
ENV FAIL2BAN_MAXRETRY '15'
ENV FAIL2BAN_BANTIME '259200'
ENV FAIL2BAN_WHITELIST ''
ENV ENABLE_DELETE_OLD_RECORDINGS 'true'
ENV DISABLE_SIGNATURE_CHECK 'false'
ENV MARIADB_REMOTE_ROOT_PASSWORD ''
ENV SIP_NAT_IP ''
ENV CERTIFICATE_DOMAIN ''

ARG FREEPBX_VERSION=17.0-latest-EDGE
ARG MARIAODBC_VERSION=2.0.19

# Pin libxml2 packages to Debian repositories
RUN echo "Package: libxml2*" > /etc/apt/preferences.d/libxml2 && \
    echo "Pin: release o=Debian,n=bookworm" >> /etc/apt/preferences.d/libxml2 && \
    echo "Pin-Priority: 501" >> /etc/apt/preferences.d/libxml2

# PHP 5.6
RUN apt-get update && \
    apt-get install -y curl wget sox lsb-release && \
    apt-get update && \
    apt-get install -y php8.2 php8.2-curl php8.2-cli php8.2-mysql php-pear php8.2-gd \
                       php8.2-xml php8.2-mbstring && \
    apt-get install -y libodbc1 odbcinst odbcinst1debian2 && \
    apt-get update  && \
    apt-get -o Dpkg::Options::="--force-confold" upgrade -y

RUN apt-get install -y build-essential apache2 mariadb-server mariadb-client bison flex

# MariaDB ODBC connector
RUN cd /usr/src && \
    mkdir -p mariadb-connector && \
    curl -sSL  https://downloads.mariadb.com/Connectors/odbc/connector-odbc-${MARIAODBC_VERSION}/mariadb-connector-odbc-${MARIAODBC_VERSION}-ga-debian-x86_64.tar.gz | tar xvfz - -C /usr/src/mariadb-connector && \
    mkdir -p /usr/lib/x86_64-linux-gnu/odbc/ && \
    cp mariadb-connector/lib/libmaodbc.so /usr/lib/x86_64-linux-gnu/odbc/ && \
    rm -rf mariadb-connector

# MariaDB bind config
RUN rm /etc/mysql/mariadb.conf.d/50-mysqld_safe.cnf && \
    sed -i 's/bind-address/#bind-address/' /etc/mysql/mariadb.conf.d/50-server.cnf

# FreePBX
RUN cd /usr/src && \
    wget http://mirror.freepbx.org/modules/packages/freepbx/freepbx-$FREEPBX_VERSION.tgz && \
    tar xfz freepbx-$FREEPBX_VERSION.tgz && \
    rm -f freepbx-$FREEPBX_VERSION.tgz

ADD odbc.ini /etc/
ADD odbcinst.ini /etc/

# FreePBX Hacks
RUN    sed -i -e "s/memory_limit = 128M/memory_limit = 256M/g" /etc/php/8.2/apache2/php.ini && \
    sed -i 's/\(^upload_max_filesize = \).*/\120M/' /etc/php/8.2/apache2/php.ini && \
    # Suppress deprecated warnings by adjusting error_reporting
    sed -i 's/^error_reporting = .*/error_reporting = E_ALL \& ~E_DEPRECATED \& ~E_USER_DEPRECATED/' /etc/php/8.2/apache2/php.ini && \
    # Suppress deprecated warnings for CLI SAPI
    sed -i 's/^error_reporting = .*/error_reporting = E_ALL \& ~E_DEPRECATED \& ~E_USER_DEPRECATED/' /etc/php/8.2/cli/php.ini && \
    a2disconf other-vhosts-access-log.conf && \
    a2enmod rewrite && \
    a2enmod headers && \
    rm -rf /var/log/* && \
    mkdir -p /var/log/asterisk && \
    mkdir -p /var/log/apache2 && \
    mkdir -p /var/log/httpd

# FreePBX dependencies
RUN apt-get update && \
    apt-get install -y pkgconf && \
    apt-get install -y nodejs yarn cron gettext libicu-dev pkg-config dbus npm

# Ensure machine-id is generated to prevent PHP shell_exec from returning null
RUN dbus-uuidgen > /etc/machine-id && \
    cp /etc/machine-id /var/lib/dbus/machine-id && \
    chmod 644 /etc/machine-id /var/lib/dbus/machine-id    

# FreePBX
RUN /etc/init.d/mariadb start && \
    cd /usr/src/freepbx && \
    echo "Starting Asterisk..." && \
    cp /etc/odbc.ini /usr/src/freepbx/installlib/files/odbc.ini && \
    ./start_asterisk start && \
    echo "Installing FreePBX (first attempt)..." && \
    # sleep 10 && \
    cd /usr/src/freepbx && \
    ./install -n || true && \
    echo "Updating FreePBX modules..." && \
    fwconsole chown && \
    echo "Installing backup module..." && \
    fwconsole ma downloadinstall backup  || true && \
    echo "Installing other modules..." && \
    fwconsole ma downloadinstall bulkhandler ringgroups timeconditions ivr restapi cel configedit asteriskinfo certman ucp webrtc  || true  && \
    echo "Running upgrade all..." && \
    fwconsole ma upgradeall  || true  && \
    # mysqldump -uroot -d -A -B --skip-add-drop-table > /mysql-freepbx.sql && \
    /etc/init.d/mariadb stop && \
    gpg --refresh-keys --keyserver hkp://keyserver.ubuntu.com:80 && \
    #gpg --import /var/www/html/admin/libraries/BMO/9F9169F4B33B4659.key && \
    #gpg --import /var/www/html/admin/libraries/BMO/3DDB2122FE6D84F7.key && \
    #gpg --import /var/www/html/admin/libraries/BMO/86CE877469D2EAD9.key && \
    #gpg --import /var/www/html/admin/libraries/BMO/1588A7366BD35B34.key && \
    chown asterisk:asterisk -R /var/www/html && \
    sed -i 's/www-data/asterisk/g' /etc/apache2/envvars && \
    rm -rf /usr/src/freepbx*

# Fail2Ban
RUN apt-get install -y fail2ban
ADD fail2ban-jail.conf /etc/fail2ban/jail.d/
ADD jail.local /etc/fail2ban/
RUN rm /etc/fail2ban/jail.d/defaults-debian.conf

# Optional tools
RUN apt-get install --no-install-recommends -y tcpdump tcpflow whois sipsak sngrep iptables


# Cleanup
RUN apt-get clean && \
    apt-get autoremove -y && \
    rm -rf /var/lib/apt/lists/* && \
    #mkdir /var/log/asterisk/ && \
    touch /var/log/asterisk/full

#ADD startup.sh /
ADD apply-initial-configs.sh /
ADD backup.sh /
ADD delete-old-recordings.sh /
COPY basic-config.tar.gz /
ADD generate-sha1.php /

ADD index.html /var/www/html/

#avoid taking too much to start by setting permissions (in container, no one will change files...)
ADD freepbx_chown.conf /etc/asterisk/

#enable https in admin
RUN a2ensite default-ssl && \
    a2enmod ssl

RUN sed -i 's/AllowOverride None/AllowOverride All/g' /etc/apache2/apache2.conf

CMD [ "/startup.sh" ]

EXPOSE 80 3306 5060/udp 5061/udp 5160/udp 5161/udp 10000-40000/udp

#recordings data
VOLUME [ "/var/spool/asterisk/monitor" ]

#automatic backup
VOLUME [ "/backup" ]

#lets encrypt and other certificate storage
VOLUME [ "/etc/asterisk/keys" ]
