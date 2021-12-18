#!/bin/sh

lastLogFile="/var/log/backup-last.log"
lastMailLogFile="/var/log/mail-last.log"

copyErrorLog() {
  cp ${lastLogFile} /var/log/backup-error-last.log
}

logLast() {
  echo "$1" >> ${lastLogFile}
}

start=$(date +%s)
rm -f ${lastLogFile} ${lastMailLogFile}
echo "Starting backup at $(date +"%Y-%m-%d %H:%M:%S")"
echo "Starting backup at $(date)" >> ${lastLogFile}
logLast "BACKUP_CRON: ${BACKUP_CRON}"
logLast "RESTIC_TAG: ${RESTIC_TAG}"
logLast "RESTIC_REPOSITORY: ${RESTIC_REPOSITORY}"
logLast "RESTIC_FORGET_ARGS: ${RESTIC_FORGET_ARGS}"
logLast "RESTIC_JOB_ARGS: ${RESTIC_JOB_ARGS}"

restic backup /data "${RESTIC_JOB_ARGS}" >> ${lastLogFile} 2>&1
backupRC=$?
logLast "Finished backup at $(date)"
if [ $backupRC = 0 ]; then
  echo "Backup successful!"
else
  echo "Backup failed with status ${backupRC}"
  restic unlock
  copyErrorLog
fi

if [ $backupRC = 0 ] && [ -n "${RESTIC_FORGET_ARGS}" ]; then
    echo "Forget about old snapshots based on RESTIC_FORGET_ARGS = ${RESTIC_FORGET_ARGS}"
    restic forget "${RESTIC_FORGET_ARGS}" >> ${lastLogFile} 2>&1
    rc=$?
    logLast "Finished forget at $(date)"
    if [ $rc = 0 ]; then
        echo "Forget Successful"
    else
        echo "Forget Failed with Status ${rc}"
        restic unlock
        copyErrorLog
    fi
fi

end=$(date +%s)
echo "Finished Backup at $(date +"%Y-%m-%d %H:%M:%S") after $((end-start)) seconds"

if [ -n "${MAILX_ARGS}" ]; then
  sh -c "mailx -v -s "Backups "$(date +"%Y-%m-%d %H:%M:%S")"" -S sendwait ${MAILX_ARGS} < ${lastLogFile} > ${lastMailLogFile} 2>&1"
  if [ $? = 0 ]; then
    echo "Mail notification successfully sent."
  else
    echo "Sending mail notification FAILED. Check ${lastMailLogFile} for further information."
  fi
fi