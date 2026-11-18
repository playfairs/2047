2048
====

A native SwiftUI 2048 game for iOS and macOS.

The game tracks elapsed time and keeps a persistent statistics page.

Use ``just build`` to build both apps, ``just launch-macos`` to run the Mac
app, or ``just install-ios DEVICE_ID`` to install on a connected iPhone. (Run `xcrun devicectl list devices` to get the device id)
Create a Mac installer with ``just pkg`` or a disk image with ``just dmg``.

Device installation requires an Xcode development team. Enter the development
environment with ``nix develop``.