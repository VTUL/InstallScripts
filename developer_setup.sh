#! /bin/bash
set -o errexit -o nounset -o xtrace -o pipefail

# Install developer conveinience files when present.
# This file should be changed to suit the developer.

PLATFORM=$1
BOOTSTRAP_DIR=$2
# Read settings and environmental overrides
[ -f "${BOOTSTRAP_DIR}/config.sh" ] && . "${BOOTSTRAP_DIR}/config.sh"
[ -f "${BOOTSTRAP_DIR}/config_${PLATFORM}.sh" ] && . "${BOOTSTRAP_DIR}/config_${PLATFORM}.sh"

if [ -f "${BOOTSTRAP_DIR}/files/.vimrc" ]; then
    apt-get update
    apt-get install -y git vim

    $RUN_AS_INSTALLUSER cp "${BOOTSTRAP_DIR}/files/.vimrc" "${INSTALL_DIR}"
    $RUN_AS_INSTALLUSER git clone https://github.com/gmarik/Vundle.vim.git ~/.vim/bundle/Vundle.vim
    $RUN_AS_INSTALLUSER vim +PluginInstall +qall > /dev/null
fi
if [ -f "${BOOTSTRAP_DIR}/files/.bashrc" ]; then
    $RUN_AS_INSTALLUSER cp "${BOOTSTRAP_DIR}/files/.bashrc" "${INSTALL_DIR}"
fi
if [ -f "${BOOTSTRAP_DIR}/files/.inputrc" ]; then
    $RUN_AS_INSTALLUSER cp "${BOOTSTRAP_DIR}/files/.inputrc" "${INSTALL_DIR}"
fi
if [ -f "${BOOTSTRAP_DIR}/files/.gitconfig" ]; then
    $RUN_AS_INSTALLUSER cp "${BOOTSTRAP_DIR}/files/.gitconfig" "${INSTALL_DIR}"
fi
