#FROM ../asterisk
#FROM flaviostutz/asterisk:16.18.0.1
FROM myfreepbxbaseimage:latest

#Bad idea hardcoding DB connection in the container
#ADD odbc.ini /etc/
#ADD odbcinst.ini /etc/

#RUN rm /etc/odbx.ini ; rm /usr/src/freepbx/installlib/files/odbc.ini

# FreePBX
# This set up should never happen in the container as it will be different, especially database connection, from installation to installation.  
#RUN /etc/init.d/mariadb start && \
#    cd /usr/src/freepbx && \
#    echo "Starting Asterisk..." && \
#    cp /etc/odbc.ini /usr/src/freepbx/installlib/files/odbc.ini && \
#    ./start_asterisk start && \
#   echo "Installing FreePBX..." && \
#    cd /usr/src/freepbx && \
#    ./install -n || true && \
#    echo "Updating FreePBX modules..." && \
#    fwconsole chown && \
#    echo "Installing backup module..." && \
#    fwconsole ma downloadinstall backup && \
#    echo "Installing other modules..." && \
#    fwconsole ma downloadinstall bulkhandler ringgroups timeconditions ivr restapi cel configedit asteriskinfo certman ucp webrtc  || true  && \
#    echo "Running upgrade all..." && \
#    fwconsole ma upgradeall  || true  && \
#    # mysqldump -uroot -d -A -B --skip-add-drop-table > /mysql-freepbx.sql && \
#    /etc/init.d/mariadb stop && \
#    gpg --refresh-keys --keyserver hkp://keyserver.ubuntu.com:80 && \
#    gpg --import /var/www/html/admin/libraries/BMO/9F9169F4B33B4659.key && \
#    gpg --import /var/www/html/admin/libraries/BMO/3DDB2122FE6D84F7.key && \
#    gpg --import /var/www/html/admin/libraries/BMO/86CE877469D2EAD9.key && \
#    gpg --import /var/www/html/admin/libraries/BMO/1588A7366BD35B34.key && \
#    chown asterisk:asterisk -R /var/www/html && \
#    sed -i 's/www-data/asterisk/g' /etc/apache2/envvars && \
#    rm -rf /usr/src/freepbx*

EXPOSE 80 3306 5060/udp 5061/udp 5160/udp 5161/udp 10000-40000/udp

#recordings data
VOLUME [ "/var/spool/asterisk/monitor" ]

#automatic backup
VOLUME [ "/backup" ]

#lets encrypt and other certificate storage
VOLUME [ "/etc/asterisk/keys" ]

CMD [ "/startup.sh" ]