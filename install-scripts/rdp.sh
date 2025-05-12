#!/bin/zsh
source "$UTILS_DIR/print.sh"

PASSWORD="12345678"

if [ -n "$SUDO_USER" ]; then
  CURRENT_USER="$SUDO_USER"
else
  CURRENT_USER=$(whoami)
fi

# Create a certificate, decide, if you want to use user-based certs or machine-based. (I guess user based is better, as "grdctl" is configured on a user basis
# These commands are meant to be run for each user individually (and not(!) as root or with sudo):
export CERT_DIR=~/.cert
mkdir -p ${CERT_DIR}
openssl genrsa -out ${CERT_DIR}/rds-tls.key 4096
openssl req -new -key ${CERT_DIR}/rds-tls.key -out ${CERT_DIR}/rds-tls.csr -subj "/C=DE/ST=Private/L=Home/O=Family/OU=IT Department/CN=ubuntu-serv-rds"
openssl x509 -req -days 100000 -signkey ${CERT_DIR}/rds-tls.key -in ${CERT_DIR}/rds-tls.csr -out ${CERT_DIR}/rds-tls.crt
# Now the actual enable process:
sudo grdctl rdp enable
sudo grdctl rdp set-credentials $CURRENT_USER $PASSWORD
# more on the $PASSWORD later
sudo grdctl rdp disable-view-only
sudo grdctl rdp set-tls-cert ${CERT_DIR}/rds-tls.crt
sudo grdctl rdp set-tls-key ${CERT_DIR}/rds-tls.key
sudo systemctl --user enable gnome-remote-desktop.service
sudo systemctl --user restart gnome-remote-desktop.service
