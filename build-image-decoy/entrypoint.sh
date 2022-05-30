#!/usr/bin/env bash

echo "Stub for testing process."
echo "Entry Point started"

# this command gets run:
#  make build-qemu-ubuntu-2004
cat << EOF > Makefile
build-qemu-ubuntu-2004:
  touch output/test/test.fake.img
EOF

exec "$@"
