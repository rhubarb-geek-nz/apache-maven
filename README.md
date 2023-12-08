# apache-maven
Package apache-maven as native package

For platforms that don't have an existing package.

- [win/package.ps1](win/package.ps1) to make an `msi` for Windows
- [linux/package.sh](linux/package.sh) to make an `rpm` for Linux
- [osx/package.sh](osx/package.sh) to make a `pkg` for macOS

Windows build also includes `ARM64` version of `jansi` `JNI` library.
