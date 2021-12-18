#!/bin/sh

echo "Starting..."

restic snapshots &>/dev/null
status=$?
echo "Checking repo status $status"

if [ $status != 0 ]; then
  echo "restic repository '${RESTIC_REPOSITORY}' does not exist. Running restic init."
  restic init

  init_status=$?
  echo "Repo init status $init_status"

  if [ $init_status != 0 ]; then
    echo "Failed to init the repository: '${RESTIC_REPOSITORY}'"
    exit 1
  fi
fi

echo "Setting up backup cron job the expression '${BACKUP_CRON}'"
echo "${BACKUP_CRON} /usr/bin/flock -n /var/run/backup.lock /bin/backup >> /var/log/cron.log 2>&1" > /var/spool/cron/crontabs/root

# Make sure the file exists before we start tail
touch /var/log/cron.log

# Start cron daemon
crond

echo "Started."

exec "$@"