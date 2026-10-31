#!/usr/bin/env python3
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

import datetime
import os
import subprocess
import sys

# backup repository environment variable
os.environ["BORG_REPO"] = "/wsobackup"


def get_timestamp():
  # Returns a formatted timestamp matching standard system date output.
  try:
    return subprocess.check_output(["date"]).decode("utf-8").strip()
  except Exception:
    return datetime.datetime.now().strftime("%a %b %d %H:%M:%S %Z %Y")


def info(message):
  # error handling and pretty printing
  print(f"\n{get_timestamp()} {message}\n", file=sys.stderr)


def run_command(cmd_list):
  # Run a borg command list and return its exit code.
  try:
    result = subprocess.run(cmd_list)
    return result.returncode
  except Exception as e:
    print(f"Error executing command {' '.join(cmd_list)}: {e}", file=sys.stderr)
    return 1


def main():
  info("Starting backup process")

  # Back up the most important stuff
  # TODO: make this more precise
  create_cmd = [
      "borg",
      "create",
      "--verbose",
      "--filter",
      "AME",
      "--list",
      "--stats",
      "--show-rc",
      "--compression",
      "lz4",
      "--exclude-caches",
      "--exclude",
      "home/*/.cache/*",
      "--exclude",
      "var/tmp/*",
      "::{hostname}-{now}",
      "/etc",
      "/home",
      "/root",
      "/var",
  ]
  backup_exit = run_command(create_cmd)

  # maintain 7 daily, 4 weekly, and 6 monthly archives of this machine
  prune_cmd = [
      "borg",
      "prune",
      "--list",
      "--glob-archives",
      "{hostname}-*",
      "--show-rc",
      "--keep-daily",
      "7",
      "--keep-weekly",
      "4",
      "--keep-monthly",
      "6",
  ]
  prune_exit = run_command(prune_cmd)

  info("Compacting repository to save space")
  compact_cmd = ["borg", "compact"]
  compact_exit = run_command(compact_cmd)

  # use highest exit code as global exit code
  global_exit = max(backup_exit, prune_exit, compact_exit)

  if global_exit == 0:
    info("Backup, Prune, and Compact finished successfully")
  elif global_exit == 1:
    info("Backup, Prune, and/or Compact finished with warnings")
  else:
    info("Backup, Prune, and/or Compact finished with errors")

  sys.exit(global_exit)


if __name__ == "__main__":
  try:
    main()
  except KeyboardInterrupt:
    print(f"\n{get_timestamp()} Backup interrupted\n", file=sys.stderr)
    sys.exit(2)