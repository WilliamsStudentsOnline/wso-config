#!/bin/bash
##### WSO-Backend WSO 2.0 #####
# Automatically make backups.

#    (__)    )
#    (..)   /|\
#   (o_o)  / | \
#   ___) \/,-|,-\
# //,-/_\ )  '  '
#    (//,-'\
#    (  ( . \_
#     `._\(___`.
#      '---' _)/
#           `-'
# Hic sunt dracones. Understanding or editing this is not advised.
# Most of this was shamelessly stolen from Borg's documentation.
# Make sure to read that if you have any questions.

# define variables
export BORG_REPO=ssh://root@wso-backup:backup/wso

# error handling and pretty printing
info() { printf "\n%s %s\n\n" "$( date )" "$*" >&2; }
trap 'echo $( date ) Backup interrupted >&2; exit 2' INT TERM

info "Starting backup process"

# Back up the most important stuff
# TODO: make this more precise
borg create                         \
    --verbose                       \
    --filter AME                    \
    --list                          \
    --stats                         \
    --show-rc                       \
    --compression lz4               \
    --exclude-caches                \
    --exclude 'home/*/.cache/*'     \
    --exclude 'var/tmp/*'           \
                                    \
    ::'{hostname}-{now}'            \
    /etc                            \ #prob don't need, ansible's got it
    /home                           \
    /root                           \
    /var

backup_exit=$?

# maintain 7 daily, 4 weekly, and 6 monthly archives of this machine
borg prune                          \
    --list                          \
    --glob-archives '{hostname}-*'  \
    --show-rc                       \
    --keep-daily    7               \
    --keep-weekly   4               \
    --keep-monthly  6

prune_exit=$?

info "Compacting repository to save space"

borg compact

compact_exit=$?

# use highest exit code as global exit code
global_exit=$(( backup_exit > prune_exit ? backup_exit : prune_exit ))
global_exit=$(( compact_exit > global_exit ? compact_exit : global_exit ))

if [ ${global_exit} -eq 0 ]; then
    info "Backup, Prune, and Compact finished successfully"
elif [ ${global_exit} -eq 1 ]; then
    info "Backup, Prune, and/or Compact finished with warnings"
else
    info "Backup, Prune, and/or Compact finished with errors"
fi

exit ${global_exit}
