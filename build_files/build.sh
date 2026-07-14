#!/bin/bash

set -ouex pipefail

log() { echo "=== $* ==="; }
RELEASE="$(rpm -E %fedora)"

# Copy the contents of system_files/ of the git repo to /
cp -avf "/ctx/system_files"/. /

# enable COPR repos
log "Enabling COPR repos..."
COPR_REPOS=(
  avengemedia/danklinux
  rivenirvana/morewaita-icon-theme
  scottames/ghostty
  ulysg/xwayland-satellite
)
for repo in "${COPR_REPOS[@]}"; do
  dnf5 -y copr enable "$repo"
done

# Terra Repo
log "Adding Terra repo..."
curl -fsSL https://github.com/terrapkg/subatomic-repos/raw/main/terra.repo \
  -o /etc/yum.repos.d/terra.repo

# Repo priorities (lower = higher priority)
echo "priority=1" >>/etc/yum.repos.d/_copr:copr.fedorainfracloud.org:ulysg:xwayland-satellite.repo
echo "priority=1" >>/etc/yum.repos.d/_copr:copr.fedorainfracloud.org:scottames:ghostty.repo
echo "priority=2" >>/etc/yum.repos.d/_copr:copr.fedorainfracloud.org:avengemedia:danklinux.repo
dnf5 -y config-manager setopt '*danklinux*.exclude=ghostty*'
dnf5 -y config-manager setopt 'terra.enabled=1' 'terra*.priority=3' 'terra*.exclude=ghostty matugen*'

# Install packages
PKGS=(
  # Desktop
  xdg-desktop-portal-gnome
  xdg-desktop-portal-gtk
  xwayland-run

  # Niri
  cava
  cliphist
  dankcalendar-git
  danksearch
  dgop
  dms
  dms-cli
  dms-greeter
  niri
  qt6-qtmultimedia
  quickshell

  # Theming
  adw-gtk3-theme
  matugen
  morewaita-icon-theme
  nwg-look

  # Fonts
  maple-fonts
  material-symbols-fonts

  # Terminal
  ghostty
  ghostty-terminfo
  ghostty-shell-integration
  ghostty-fish-completion

  # Containers
  podman-compose
  podman-machine
  podman-tui
)

# REMOVE_PKGS=(
#   gnome-tweaks
#   jetbrains-mono-fonts-all
#   libappindicator-gtk3
#   libayatana-appindicator-gtk3
#   nautilus-gsconnect
#   opendyslexic-fonts
#   ptyxis
#   zsh
# )

log "Installing packages..."
dnf5 install -y --setopt=install_weak_deps=False "${PKGS[@]}"

# log "Removing unwanted packages..."
# dnf5 remove -y "${REMOVE_PKGS[@]}"

log "Cleaning up..."
dnf5 clean all

# make greeter-group-setup executable
chmod +x /usr/bin/greeter-group-setup

# setup services
systemctl disable gdm.service
systemctl enable greetd.service
systemctl enable podman.socket
systemctl enable greeter-group-setup.service
