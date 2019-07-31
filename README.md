OpenCoreShell
=============

[![Build Status](https://travis-ci.com/acidanthera/OpenCoreShell.svg?branch=master)](https://travis-ci.com/acidanthera/OpenCoreShell)

-----

This repository contains buildscript and patches for TianoCore [UDK ShellPkg](http://github.com/tianocore/edk2).
These patches are oriented to adding missing modules and fixing quirks of EFI and UEFI firmwares found in the wild.
While some of them were upstreamed, most are not production ready and unlikely will ever be, as certain issues
are not caused by ShellPkg itself, but rather omissions in firmwares. In other cases feel free to take the effort
to refactor and upstream the changes.

## Console size

It is not possible to reliably detect the largest console mode, as on some firmwares not all modes work or are
visible onscreen. Feel free to specify it yourself (`help mode`).

## Mac support

To boot into Shell on Mac you will have to save `Shell.efi` under the name of `EFI\BOOT\BOOTX64.EFI` on a FAT32
drive. It appears to be unimportant whether it is GPT or MBR.

Another approach is to bless `Shell.efi` on an HFS+ or APFS volume:
```
sudo bless --verbose --file /Volumes/VOLNAME/DIR/Shell.efi --folder /Volumes/VOLNAME/DIR/ --setBoot
```

- You may have to copy `/System/Library/CoreServices/BridgeVersion.bin` to `/Volumes/VOLNAME/DIR` in this case.
- To be able to use `bless` you have to [disable System Integrity Protection](https://developer.apple.com/library/archive/documentation/Security/Conceptual/System_Integrity_Protection_Guide/ConfiguringSystemIntegrityProtection/ConfiguringSystemIntegrityProtection.html).
- To be able to boot you may have to [disable Secure Boot](https://support.apple.com/HT208330) if present. 

## Credits
- [TianoCore](http://github.com/tianocore) for UDK
- [External contributors](https://github.com/acidanthera/OpenCoreShell/tree/Patches) for third party patches
- [vit9696](https://github.com/vit9696) for writing borked code
