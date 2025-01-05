#!/bin/bash

if [ ! -e  /usr/sbin/fwconsole ]; then
  /etc/init.d/mariadb start
  cd /usr/src/freepbx
  echo "Starting Asterisk..."
  #cp /etc/odbc.ini /usr/src/freepbx/installlib/files/odbc.ini
  ./start_asterisk start
  echo "Installing FreePBX..."
  cd /usr/src/freepbx
  ./install -n || true
  chown asterisk:asterisk -R /var/www/html
  chown asterisk:asterisk -R /var/log/asterisk
  echo "Updating FreePBX modules..."
  fwconsole chown 
  #sudo sed -i 's/$options = array()/$options = array("verify"=>false)/' /var/www/html/admin/libraries/BMO/Curl.class.php
  echo "Installing backup module..."
  fwconsole ma downloadinstall backup || true
  echo "Installing other modules..."
  fwconsole ma downloadinstall bulkhandler ringgroups timeconditions ivr restapi cel configedit asteriskinfo certman ucp webrtc  || true  && \
  echo "Running upgrade all..."
  fwconsole ma upgradeall  || true
  /etc/init.d/mariadb stop
  gpg --refresh-keys --keyserver hkp://keyserver.ubuntu.com:80
  gpg --import /var/www/html/admin/libraries/BMO/1588A7366BD35B34.key
  gpg --import /var/www/html/admin/libraries/BMO/3DDB2122FE6D84F7.key
  gpg --import /var/www/html/admin/libraries/BMO/86CE877469D2EAD9.key
  gpg --import /var/www/html/admin/libraries/BMO/9F9169F4B33B4659.key
  gpg --import /var/www/html/admin/libraries/BMO/B53D215A755231A3.key

  sed -i 's/www-data/asterisk/g' /etc/apache2/envvars
  rm -rf /usr/src/freepbx*
fi 


set -e

if [ "$ADMIN_PASSWORD" == "" ]; then
  echo "ADMIN_PASSWORD is required"
  exit 1
fi

#https://docs.docker.com/engine/admin/multi-service_container/

chown -R asterisk:asterisk /backup

#Fail2Ban
if [ "$FAIL2BAN_ENABLE" == "true" ]; then
  if [ -e /var/run/fail2ban ]; then
    rm -r /var/run/fail2ban
  fi
  set +e
  mkdir /var/run/fail2ban
  iptables-legacy -L
  if [ "$?" != "0" ]; then
    echo "For enabling fail2ban you have to run this container with 'privileged: true'"
    exit 1
  fi
  set -e
  echo "Enabling fail2ban for asterisk logs at /var/log/asterisk/full"
  sed -i "s|\$FAIL2BAN_IGNOREIPS|$FAIL2BAN_IGNOREIPS|g" /etc/fail2ban/jail.local
  sed -i "s|\$FAIL2BAN_FINDTIME|$FAIL2BAN_FINDTIME|g" /etc/fail2ban/jail.d/fail2ban-jail.conf
  sed -i "s|\$FAIL2BAN_MAXRETRY|$FAIL2BAN_MAXRETRY|g" /etc/fail2ban/jail.d/fail2ban-jail.conf
  sed -i "s|\$FAIL2BAN_BANTIME|$FAIL2BAN_BANTIME|g" /etc/fail2ban/jail.d/fail2ban-jail.conf
  echo "Starting fail2ban server"
  fail2ban-server
fi

echo "Starting MySQL..."
/etc/init.d/mariadb start
status=$?
if [ $status -ne 0 ]; then
  echo "Failed to start mysql: $status"
  exit $status
fi

echo "Starting Apache..."
if [ -f /etc/asterisk/keys/$CERTIFICATE_DOMAIN.pem ]; then
  echo "Found certificate at /etc/asterisk/keys/$CERTIFICATE_DOMAIN.pem (possibly LetsEncrypt cert). Setting Apache to use it."
  sed -i 's|/etc/ssl/certs/ssl-cert-snakeoil.pem|/etc/asterisk/keys/'$CERTIFICATE_DOMAIN'.pem|g' /etc/apache2/sites-enabled/default-ssl.conf
  sed -i 's|/etc/ssl/private/ssl-cert-snakeoil.key|/etc/asterisk/keys/'$CERTIFICATE_DOMAIN'.key|g' /etc/apache2/sites-enabled/default-ssl.conf
fi

/etc/init.d/apache2 start
status=$?
if [ $status -ne 0 ]; then
  echo "Failed to start apache2: $status"
  exit $status
fi

echo "Starting FreePBX..."
fwconsole start
status=$?
if [ $status -ne 0 ]; then
  echo "Failed to start fwconsole: $status"
  exit $status
fi

# Apply configurations on initial startup
if [ ! -f /init ]; then
  #restore previous backup if exists
  VER="15.0"
  if [ "$ENABLE_AUTO_RESTORE" == "true" ] && [ -f /backup/$VER/new.tar.gz ]; then
    echo "Restoring backup from /backup/$VER/new.tar.gz"
    fwconsole backup --restore /backup/$VER/new.tar.gz
    echo "Done"

  #apply initial configurations
  else
    echo "Applying initial configurations..."
    /apply-initial-configs.sh

  fi

  touch /init
fi

#echo "Starting automatic backups..."
/backup.sh &
status=$?
if [ $status -ne 0 ]; then
  echo "Failed to start backup.sh: $status"
  exit $status
fi

if [ "$ENABLE_DELETE_OLD_RECORDINGS" == "true" ]; then
  echo "Starting automatic deletion of old recordings..."
  /delete-old-recordings.sh &
  status=$?
  if [ $status -ne 0 ]; then
    echo "Failed to start delete-old-recordings: $status"
    exit $status
  fi
fi

if [ "$MARIADB_REMOTE_ROOT_PASSWORD" != "" ]; then
  echo "Enabling remote access to MySQL. Be aware."
  QUERY="GRANT ALL ON *.* TO 'root'@'%' IDENTIFIED BY '$MARIADB_REMOTE_ROOT_PASSWORD' WITH GRANT OPTION; FLUSH PRIVILEGES;"
  mysql -u root -e "$QUERY"
fi

echo "STARTUP COMPLETED"

#Check if all processes are OK
while /bin/true; do
  ps aux |grep mysqld |grep -q -v grep
  MYSQL_STATUS=$?
  ps aux |grep asterisk |grep -q -v grep
  ASTERISK_STATUS=$?
  ps aux |grep '/backup.sh' |grep -q -v grep
  BACKUPSCRIPT_STATUS=$?

  if [ $ASTERISK_STATUS -ne 0 -o $BACKUPSCRIPT_STATUS -ne 0 -o $MYSQL_STATUS -ne 0 ]; then
    echo "One of the processes has exited."
    exit 1
  fi
  sleep 60
done

