#!/bin/bash

BUILDDIR=$(dirname "$0")
pushd "$BUILDDIR" >/dev/null
BUILDDIR=$(pwd)
popd >/dev/null

PKGVER="1.0.2"

cd "$BUILDDIR"

prompt() {
  echo "$1"
  if [ "$FORCE_INSTALL" != "1" ]; then
    read -p "Enter [Y]es to continue: " v
    if [ "$v" != "Y" ] && [ "$v" != "y" ]; then
      exit 1
    fi
  fi
}

updaterepo() {
  if [ ! -d "$2" ]; then
    git clone "$1" -b "$3" --depth=1 "$2" || exit 1
  fi
  pushd "$2" >/dev/null
  git pull || exit 1
  git rebase "origin/$3" || exit 1
  popd >/dev/null
}

package() {
  if [ ! -d "$1" ]; then
    echo "Missing package directory"
    exit 1
  fi

  pushd "$1" || exit 1
  rm -rf tmp || exit 1
  mkdir -p tmp/Tools || exit 1
  cp Shell_EA4BB293-2D7F-4456-A681-1F22F42CD0BC.efi tmp/Tools/Shell.efi || exit 1
  echo "$3" > tmp/UDK.hash || exit 1
  pushd tmp || exit 1
  zip -qry -FS ../"OpenCoreShell-${PKGVER}-${2}.zip" * || exit 1
  popd || exit 1
  rm -rf tmp || exit 1
  popd || exit 1
}

if [ "$BUILDDIR" != "$(printf "%s\n" $BUILDDIR)" ]; then
  echo "EDK2 build system may still fail to support directories with spaces!"
  exit 1
fi

if [ "$(which clang)" = "" ] || [ "$(which git)" = "" ] || [ "$(clang -v 2>&1 | grep "no developer")" != "" ] || [ "$(git -v 2>&1 | grep "no developer")" != "" ]; then
  echo "Missing Xcode tools, please install them!"
  exit 1
fi

if [ "$(nasm -v)" = "" ] || [ "$(nasm -v | grep Apple)" != "" ]; then
  echo "Missing or incompatible nasm!"
  echo "Download the latest nasm from http://www.nasm.us/pub/nasm/releasebuilds/"
  prompt "Install last tested version automatically?"
  pushd /tmp >/dev/null
  rm -rf nasm-mac64.zip
  curl -OL "https://github.com/acidanthera/ocbuild/raw/master/external/nasm-mac64.zip" || exit 1
  nasmzip=$(cat nasm-mac64.zip)
  rm -rf nasm-*
  curl -OL "https://github.com/acidanthera/ocbuild/raw/master/external/${nasmzip}" || exit 1
  unzip -q "${nasmzip}" nasm*/nasm nasm*/ndisasm || exit 1
  sudo mkdir -p /usr/local/bin || exit 1
  sudo mv nasm*/nasm /usr/local/bin/ || exit 1
  sudo mv nasm*/ndisasm /usr/local/bin/ || exit 1
  rm -rf "${nasmzip}" nasm-*
  popd >/dev/null
fi

if [ "$(which mtoc.NEW)" == "" ] || [ "$(which mtoc)" == "" ]; then
  echo "Missing mtoc or mtoc.NEW!"
  echo "To build mtoc follow: https://github.com/tianocore/tianocore.github.io/wiki/Xcode#mac-os-x-xcode"
  prompt "Install prebuilt mtoc and mtoc.NEW automatically?"
  pushd /tmp >/dev/null
  rm -f mtoc mtoc-mac64.zip
  curl -OL "https://github.com/acidanthera/ocbuild/raw/master/external/mtoc-mac64.zip" || exit 1
  unzip -q mtoc-mac64.zip mtoc || exit 1
  sudo mkdir -p /usr/local/bin || exit 1
  sudo cp mtoc /usr/local/bin/mtoc || exit 1
  sudo mv mtoc /usr/local/bin/mtoc.NEW || exit 1
  popd >/dev/null
fi

if [ ! -d "Binaries" ]; then
  mkdir Binaries || exit 1
  cd Binaries || exit 1
  ln -s ../UDK/Build/Shell/RELEASE_XCODE5/X64 RELEASE || exit 1
  ln -s ../UDK/Build/Shell/DEBUG_XCODE5/X64 DEBUG || exit 1
  cd .. || exit 1
fi

while true; do
  if [ "$1" == "--skip-tests" ]; then
    SKIP_TESTS=1
    shift
  elif [ "$1" == "--skip-build" ]; then
    SKIP_BUILD=1
    shift
  elif [ "$1" == "--skip-package" ]; then
    SKIP_PACKAGE=1
    shift
  else
    break
  fi
done

if [ "$1" != "" ]; then
  MODE="$1"
  shift
fi

if [ ! -f UDK/UDK.ready ]; then
  rm -rf UDK
fi

updaterepo "https://github.com/acidanthera/audk" UDK master || exit 1
cd UDK
HASH=$(git rev-parse origin/master)

source edksetup.sh || exit 1

if [ "$SKIP_TESTS" != "1" ]; then
  make -C BaseTools || exit 1
  touch UDK.ready
fi

if [ ! -f patches.ready ]; then
  for i in ../Patches/* ; do
    git apply "$i" --whitespace=fix || exit 1
    git add * || exit 1
    git commit -m "Applied patch $i" || exit 1
  done
  touch patches.ready
fi

if [ "$SKIP_BUILD" != "1" ]; then
  if [ "$MODE" = "" ] || [ "$MODE" = "DEBUG" ]; then
    build -a X64 -b DEBUG -t XCODE5 -p ShellPkg/ShellPkg.dsc || exit 1
  fi

  if [ "$MODE" = "" ] || [ "$MODE" = "RELEASE" ]; then
    build -a X64 -b RELEASE -t XCODE5 -p ShellPkg/ShellPkg.dsc || exit 1
  fi
fi

cd .. || exit 1

if [ "$SKIP_PACKAGE" != "1" ]; then
  if [ "$PACKAGE" = "" ] || [ "$PACKAGE" = "DEBUG" ]; then
    package "Binaries/DEBUG" "DEBUG" || exit 1
  fi

  if [ "$PACKAGE" = "" ] || [ "$PACKAGE" = "RELEASE" ]; then
    package "Binaries/RELEASE" "RELEASE" || exit 1
  fi
fi