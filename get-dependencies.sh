#!/bin/sh

set -eu

ARCH=$(uname -m)

echo "Installing package dependencies..."
echo "---------------------------------------------------------------"
pacman -Syu --noconfirm \
	git           \
	jdk25-openjdk \
	libxrender    \
	libxtst

echo "Installing debloated packages..."
echo "---------------------------------------------------------------"
get-debloated-pkgs --add-common --prefer-nano

echo "Building AB Download Manager..."
echo "---------------------------------------------------------------"
git clone https://github.com/amir1376/ab-download-manager ./ab-download-manager && (
	cd ./ab-download-manager

	git fetch --tags origin
	TAG=$(git tag --sort=-v:refname | grep -vi 'rc\|preview\|alpha\|beta' | head -1)
	git checkout "$TAG"

	# no self-updating, self-updater.hook handles updates
	git apply ../patches/*.patch

	# desktop app-image only
	SKIP_ANDROID_BUILD=true ./gradlew --no-daemon :desktop:app:createReleaseDistributable

	echo "${TAG#v}" > ~/version
)

APP=./ab-download-manager/desktop/app/build/compose/binaries/main-release/app/ABDownloadManager

# keep lib next to bin, the jpackage launcher expects it
mkdir -p ./AppDir/bin ./AppDir/lib
cp -r "$APP"/bin/. ./AppDir/bin/
cp -r "$APP"/lib/. ./AppDir/lib/
ln -s ../lib ./AppDir/bin/lib

cp "$APP"/lib/ABDownloadManager.png ./AppDir/ABDownloadManager.png
