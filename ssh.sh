#!/bin/sh
ssh_options="-o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no"
if [ -z "$DEPLOY_KEY" ]; then
  ssh $ssh_options "$@"
else
  ssh -i "$DEPLOY_KEY" $ssh_options "$@"
fi
