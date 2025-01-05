#!/bin/bash
VER="17.0"
while /bin/true; do
  echo "Waiting $BACKUP_TIMER seconds for the next automatic backup..."
  sleep $BACKUP_TIMER
  echo "Running backup and storing to /backup/$VER/new.tgz..."
  mkdir -p /backup/$VER
  cd /backup
  fwconsole backup --backup 2dad0248-ca89-43a3-b761-82848399d903
  if [ "$?" != "0" ]; then
    echo "Error creating automatic backup"
  else
    if [ -f $VER/new.tar.gz ]; then 
      mv $VER/new.tar.gz $VER/old.tar.gz
    fi
    ls *.tar.gz -tr | tail -n 1 | xargs -I{} mv {} $VER/new.tar.gz
    echo "Backup saved to /backup/$VER/new.tar.gz"
  fi
done
