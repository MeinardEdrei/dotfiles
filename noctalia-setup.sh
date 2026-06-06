#!/bin/bash
set -e

FILEPATH="/etc/xdg/quickshell/noctalia-shell/Modules/LockScreen/LockContext.qml"

if [ -f "$FILEPATH" ]; then
    echo "Configuring Noctalia screen lock dual-PAM logic..."

    sudo python3 -c '
filepath = "/etc/xdg/quickshell/noctalia-shell/Modules/LockScreen/LockContext.qml"
with open(filepath, "r") as f:
    content = f.read()

idx = content.find("  onPamReadyChanged:")
if idx != -1:
    header = content[:idx]
    replacement = """  onPamReadyChanged: {
    if (pamReady) {
      if (Settings.data.general.autoStartAuth && currentText === "") {
        pamFingerprint.start();
      }
    }
  }

  onShowInfoChanged: {
    if (showInfo) {
      showFailure = false;
    }
  }

  onShowFailureChanged: {
    if (showFailure) {
      showInfo = false;
    }
  }

  readonly property var activePam: (currentText !== "") ? pamPassword : pamFingerprint

  onCurrentTextChanged: {
    if (currentText !== "") {
      showInfo = false;
      showFailure = false;
      if (pamFingerprint.active) {
        pamFingerprint.abort();
      }
    } else {
      if (pamPassword.active) {
        pamPassword.abort();
      }
      if (pamReady && Settings.data.general.autoStartAuth) {
        pamFingerprint.start();
      }
    }
  }

  function tryUnlock() {
    if (!pamReady) {
      Logger.w("LockContext", "PAM not ready yet, ignoring unlock attempt");
      return;
    }

    const active = root.activePam;
    if (waitingForPassword) {
      active.respond(currentText);
      unlockInProgress = true;
      waitingForPassword = false;
      showInfo = false;
      return;
    }

    Logger.i("LockContext", "Starting PAM authentication for user:", active.user, "using config:", active.config);
    active.start();
  }

  Process {
    id: occupyFingerprintSensorProc
    command: ["fprintd-verify"]
  }

  PamContext {
    id: pamFingerprint
    configDirectory: root.pamConfigDirectory
    config: root.pamConfig
    user: HostService.username

    onPamMessage: {
      if (root.activePam === pamFingerprint) {
        Logger.i("LockContext", "Fingerprint PAM message:", message, "isError:", messageIsError, "responseRequired:", responseRequired);

        if (this.responseRequired) {
          Logger.i("LockContext", "Responding to Fingerprint PAM with password");
          if (root.currentText !== "") {
            this.respond(root.currentText);
            unlockInProgress = true;
          } else {
            root.waitingForPassword = true;
            infoMessage = I18n.tr("lock-screen.password");
            showInfo = true;
          }
        } else if (messageIsError) {
          errorMessage = message;
          showFailure = true;
        } else {
          infoMessage = message;
          showInfo = true;
        }
      }
    }

    onCompleted: result => {
                   if (root.activePam === pamFingerprint) {
                     Logger.i("LockContext", "Fingerprint PAM completed with result:", result);
                     if (result === PamResult.Success) {
                       Logger.i("LockContext", "Authentication successful via fingerprint");
                       root.unlocked();
                     } else {
                       Logger.i("LockContext", "Authentication failed via fingerprint");
                       root.currentText = "";
                       errorMessage = I18n.tr("authentication.failed");
                       showFailure = true;
                       root.failed();
                     }
                     root.unlockInProgress = false;
                   }
                 }

    onError: {
      if (root.activePam === pamFingerprint) {
        Logger.i("LockContext", "Fingerprint PAM error:", error, "message:", message);
        errorMessage = message || "Authentication error";
        showFailure = true;
        root.unlockInProgress = false;
        root.failed();
      }
    }
  }

  PamContext {
    id: pamPassword
    configDirectory: root.pamConfigDirectory
    config: "system-auth"
    user: HostService.username

    onPamMessage: {
      if (root.activePam === pamPassword) {
        Logger.i("LockContext", "Password PAM message:", message, "isError:", messageIsError, "responseRequired:", responseRequired);

        if (this.responseRequired) {
          Logger.i("LockContext", "Responding to Password PAM with password");
          if (root.currentText !== "") {
            this.respond(root.currentText);
            unlockInProgress = true;
          } else {
            root.waitingForPassword = true;
            infoMessage = I18n.tr("lock-screen.password");
            showInfo = true;
          }
        } else if (messageIsError) {
          errorMessage = message;
          showFailure = true;
        } else {
          infoMessage = message;
          showInfo = true;
        }
      }
    }

    onCompleted: result => {
                   if (root.activePam === pamPassword) {
                     Logger.i("LockContext", "Password PAM completed with result:", result);
                     if (result === PamResult.Success) {
                       Logger.i("LockContext", "Authentication successful via password");
                       root.unlocked();
                     } else {
                       Logger.i("LockContext", "Authentication failed via password");
                       root.currentText = "";
                       errorMessage = I18n.tr("authentication.failed");
                       showFailure = true;
                       root.failed();
                     }
                     root.unlockInProgress = false;
                   }
                 }

    onError: {
      if (root.activePam === pamPassword) {
        Logger.i("LockContext", "Password PAM error:", error, "message:", message);
        errorMessage = message || "Authentication error";
        showFailure = true;
        root.unlockInProgress = false;
        root.failed();
      }
    }
  }
}
"""
    with open(filepath, "w") as f:
        f.write(header + replacement)
    print("Successfully patched LockContext.qml")
else:
    print("Error: Could not find onPamReadyChanged in LockContext.qml")
'
else
    echo "Warning: Noctalia LockContext.qml not found at $FILEPATH. Skipping lock screen patch."
fi
