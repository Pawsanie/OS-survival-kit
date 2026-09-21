#!/usr/bin/bash
# The script clears the DNS cache.

printf '\033[34mmacOS DNS cache clearing script has been launched.\033[0m\n'

sudo dscacheutil \
  -flushcache

sudo killall \
  -HUP mDNSResponder

printf '\033[34mmacOSs DNS cache clearing scenario completed.\033[0m\n'
