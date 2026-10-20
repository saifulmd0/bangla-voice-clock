import 'dart:io';

/// The desktop the app runs on.
enum HostOs { macos, windows, linux }

/// Where the app runs. Screenshots of another desktop's version set it.
HostOs hostOs = Platform.isWindows
    ? HostOs.windows
    : Platform.isLinux
    ? HostOs.linux
    : HostOs.macos;
