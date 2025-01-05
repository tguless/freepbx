docker system prune
docker volume rm dlandinstall_backup
docker volume rm dlandinstall_certificates
docker volume rm dlandinstall_freepbx_db
docker volume rm dlandinstall_recordings
docker system prune -a --volumes
docker-compose  build --no-cache  freepbx