#!/usr/bin/bash
# The script clears the DNS cache.

sudo dscacheutil \
  -flushcache

sudo killall \
  -HUP mDNSResponder
