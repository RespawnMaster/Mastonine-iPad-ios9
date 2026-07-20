# Mastonine-iPad-iOS9

> A native Mastodon client for jailbroken iOS 9 devices.

Mastonine is a modern Mastodon client designed specifically for legacy iOS devices. Built entirely in Objective-C using Theos, it provides a fast, native Mastodon experience for devices that can no longer run current applications.

## AI Generated Project

Mastonine is an AI-generated open-source project created to bring Mastodon support back to legacy iOS devices. The project explores what can be achieved by combining AI-generated code with legacy Apple development tools, Theos, and jailbroken hardware.

---

## Installing Release

1. Download the latest `.deb` release.
2. Transfer it to your iPad using SSH or USB.
3. Open the `.deb` file with **Filza** (recommended file manager available from default jailbreak repositories).
4. Select **Install**.
5. Open the installation popup actions menu.
6. Run **uicache** and **Respring**.
7. Mastonine should now appear on your Home Screen.

To remove Mastonine, uninstall it through Cydia or your preferred jailbreak package manager.

---

## Features

* Native iOS 9 interface
* OAuth authentication
* Home, Local, Federated, List, and Hashtag timelines
* Rich HTML post rendering
* Compose, reply, edit, and delete posts
* Poll support
* Drafts and scheduled posts
* Notifications
* User profiles and search
* Thread viewer
* Manual dark mode
* Image caching
* Core Spotlight integration

---

## Requirements

### Device

* Jailbroken iOS 9 device

### Development

* Linux
* Theos
* iOS 9.3 SDK
* iOS toolchain (armv7)
* Git

---

## Tested Devices

Currently tested on:

* iPad 3 running iOS 9.3.6

Additional iOS 9 devices may work but have not been fully tested.

---

## Building

```bash
# 1. Install Theos
git clone --recursive https://github.com/theos/theos.git ~/theos

# 2. Install iOS 9 SDK + toolchain
# Place iPhoneOS9.3.sdk in ~/theos/sdks/
# Place arm64/ and armv7/ toolchain binaries in ~/theos/toolchain/linux/iphone/

# 3. Extract source
unzip Mastonine-src.zip -d Mastonine
cd Mastonine

# 4. Set environment
export THEOS=~/theos

# 5. Build
make package FINALPACKAGE=1

# 6. Deploy over SSH
make package install THEOS_DEVICE_IP=<device-ip> THEOS_DEVICE_PORT=22

# USB deployment
make package install THEOS_DEVICE_IP=127.0.0.1 THEOS_DEVICE_PORT=2222
```

---

## USB Deployment

For USB installation, start `iproxy` first:

```bash
iproxy 22 2222
```

The device will then be available at:

```text
127.0.0.1:2222
```

---

## After Installation (SSH)

Refresh the application cache and restart SpringBoard:

```bash
uicache -p /Applications/Mastonine.app
killall -HUP SpringBoard
```

---

## Project Status

🚧 **In Development**

Mastonine is actively being developed. Features and compatibility may change as development continues.

---

## Screenshots

*Coming soon.*

---

## Contributing

Contributions are welcome!

Feel free to:

* Open issues for bugs or feature requests
* Submit pull requests
* Help test on additional iOS 9 devices

---

## License

Copyright © 2026 Mastonine Contributors.

This project is licensed under the **GNU Affero General Public License v3.0 (AGPL-3.0)**.

You may use, modify, and redistribute this software under the terms of the AGPL-3.0. If you modify the software and make it available over a network, you must provide access to the corresponding source code under the same license.

See the `LICENSE` file for the complete license text.
