#!/bin/bash

# Pastikan script dijalankan sebagai root
if [ "$EUID" -ne 0 ]; then
  echo "Error: Script ini harus dijalankan sebagai root (gunakan sudo)."
  exit 1
fi

echo "=========================================="
echo "    SETUP USER BARU (AUTO MENU & ROOT)    "
echo "=========================================="

# 1. Input username baru
read -p "Masukkan username baru: " NEW_USER

if [ -z "$NEW_USER" ]; then
  echo "Error: Username tidak boleh kosong!"
  exit 1
fi

if id "$NEW_USER" &>/dev/null; then
  echo "Error: User '$NEW_USER' sudah terdaftar di VPS!"
  exit 1
fi

# 2. Input password baru
read -s -p "Masukkan password baru: " NEW_PASS
echo ""
read -s -p "Ulangi password baru: " CONFIRM_PASS
echo ""

if [ "$NEW_PASS" != "$CONFIRM_PASS" ]; then
  echo "Error: Konfirmasi password tidak cocok!"
  exit 1
fi

# 3. Buat user baru dengan shell bash
useradd -m -s /bin/bash "$NEW_USER"
echo "$NEW_USER:$NEW_PASS" | chpasswd

# 4. Berikan akses sudo grup
if getent group sudo >/dev/null; then
  usermod -aG sudo "$NEW_USER"
elif getent group wheel >/dev/null; then
  usermod -aG wheel "$NEW_USER"
fi

# 5. Berikan hak sudo tanpa perlu ketik password lagi
echo "$NEW_USER ALL=(ALL:ALL) NOPASSWD:ALL" > "/etc/sudoers.d/$NEW_USER"
chmod 0440 "/etc/sudoers.d/$NEW_USER"

# 6. Tambahkan alias 'menu' otomatis ke bashrc user baru
USER_HOME=$(eval echo "~$NEW_USER")
echo "alias menu='sudo menu'" >> "$USER_HOME/.bashrc"
chown "$NEW_USER:$NEW_USER" "$USER_HOME/.bashrc"

# 7. Pastikan PasswordAuthentication aktif di SSH
if grep -q "^PasswordAuthentication" /etc/ssh/sshd_config; then
  sed -i 's/^PasswordAuthentication.*/PasswordAuthentication yes/' /etc/ssh/sshd_config
else
  echo "PasswordAuthentication yes" >> /etc/ssh/sshd_config
fi

# Restart layanan SSH
systemctl restart ssh 2>/dev/null || systemctl restart sshd 2>/dev/null

echo "=========================================="
echo " Berhasil! User '$NEW_USER' siap digunakan."
echo " User bisa langsung mengetik 'menu' di terminal."
echo "=========================================="
