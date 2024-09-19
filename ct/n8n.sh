#!/usr/bin/env bash
set -x
exec 2>&1 | tee /tmp/n8n_install_debug.log

source <(curl -s https://raw.githubusercontent.com/tteck/Proxmox/main/misc/build.func) 2>&1 | tee /tmp/source_debug.log
# Copyright (c) 2021-2024 tteck
# Author: tteck (tteckster)
# License: MIT
# https://github.com/tteck/Proxmox/raw/main/LICENSE
function header_info {
clear
cat <<"EOF"
         ___        
        / _ \       
  *_* | (_) |____  
 |  * \ > * <|  _ \ 
 | | | | (_) | | | |
 |_| |_|\___/|_| |_|
 
EOF
}
header_info
echo -e "Loading..."
APP="n8n"
var_disk="6"
var_cpu="2"
var_ram="2048"
var_os="debian"
var_version="12"
variables
color
catch_errors
function default_settings() {
  CT_TYPE="1"
  PW=""
  CT_ID=$NEXTID
  HN=$NSAPP
  DISK_SIZE="$var_disk"
  CORE_COUNT="$var_cpu"
  RAM_SIZE="$var_ram"
  BRG="vmbr0"
  NET="dhcp"
  GATE=""
  APT_CACHER=""
  APT_CACHER_IP=""
  DISABLEIP6="no"
  MTU=""
  SD=""
  NS=""
  MAC=""
  VLAN=""
  SSH="no"
  VERB="no"
  echo_default
}
function update_script() {
header_info
if [[ ! -f /etc/systemd/system/n8n.service ]]; then msg_error "No ${APP} Installation Found!"; exit; fi
  if [[ "$(node -v | cut -d 'v' -f 2)" == "18."* ]]; then
    if ! command -v npm >/dev/null 2>&1; then
      echo "Installing NPM..."
      apt-get install -y npm
      echo "Installed NPM..."
    fi
  fi
msg_info "Updating ${APP} LXC"
npm update -g n8n
systemctl restart n8n
msg_ok "Updated Successfully"
exit
}
start
echo "Starting container build process"
build_container
echo "Container build process completed"
description

echo "Installing dependencies..."
apt-get update
apt-get install -y curl sudo mc ca-certificates gnupg
echo "Dependencies installed"

echo "Setting up Node.js repository..."
mkdir -p /etc/apt/keyrings
curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg
echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_20.x nodistro main" >/etc/apt/sources.list.d/nodesource.list
echo "Node.js repository set up"

echo "Installing Node.js..."
apt-get update
apt-get install -y nodejs
echo "Node.js installed"

echo "Installing n8n..."
npm install --global patch-package --verbose
npm install --global n8n --verbose
echo "n8n installed"

echo "Creating n8n service file..."
cat <<EOF >/etc/systemd/system/n8n.service
[Unit]
Description=n8n
[Service]
Type=simple
Environment="N8N_SECURE_COOKIE=false"
ExecStart=n8n start
[Install]
WantedBy=multi-user.target
EOF
echo "n8n service file created"

echo "Enabling and starting n8n service..."
systemctl enable --now n8n
echo "n8n service enabled and started"

msg_ok "Completed Successfully!\n"
echo -e "${APP} should be reachable by going to the following URL.
         ${BL}http://${IP}:5678${CL} \n"

echo "Collecting system information..."
df -h
free -m
node --version
npm --version
systemctl status n8n

echo "Installation process completed. Debug log available at /tmp/n8n_install_debug.log"
