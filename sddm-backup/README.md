# SDDM Backup (SilentSDDM - current setup)

Backed up on 2026-06-08. Restore with:

```bash
sudo cp sddm.conf /etc/sddm.conf
sudo cp sddm-fingerprint.pam /etc/pam.d/sddm-fingerprint
sudo cp silent-default.conf /usr/share/sddm/themes/silent/configs/default.conf
sudo cp LoginScreen.qml /usr/share/sddm/themes/silent/components/LoginScreen.qml
sudo systemctl restart sddm
```
