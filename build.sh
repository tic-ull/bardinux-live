#!/bin/sh

set -xe

export DISPLAY=

NAME=Bardinux
VERSION=3.4
SUBVERSION=Beta3
DESCRIPTION="Precise Pangolin"
ARCH=i386

DATE=$(date +%Y%m%d%H%M)

usage() {
    cat << _EOF_
Builds an iso.

Usage: $0 [-a|--arch|--architecture ARCH] [-d|--description DESC] [-r|--release] [-n|--name NAME]
    -a, --architecture  Defines the distribution architecture
    -d, --description   Defines the distribution description
    -n, --name          Defines the distribution name
    -r, --release       Sets a final version of the distribution
_EOF_
	exit $1
}

check_n_umount() {
	VOLATILE=$(cat /proc/mounts|grep -e "chroot.*generic/volatile"|awk '{print $2}')
	if [ ! -z "$VOLATILE" ]
	then
		umount $VOLATILE
	fi 
}

if [ $(id -u) != 0 ]; then
	# Needs root permissions
	sudo $0 $*
	exit
fi

while [ $1 ]; do
	case $1 in
		-a|--arch|--architecture)
			shift
			ARCH=${1}
			;;
		-d|--description)
			shift
			DESCRIPTION=${1}
			;;
	   	-r|--release)
			RELEASE=true
			SUBVERSION="final"
			;;
		-n|--name)
			shift
			NAME=${1}
			;;
        *)  
            usage 0
            ;; 
	esac
	shift
done

echo "${NAME} ${VERSION} ${SUBVERSION} \"${DESCRIPTION}\" - Build ${ARCH} LIVE Binary" > config/binary_local-includes/.disk/info

sed "s/\(^#define DISKNAME\).*/\1  ${NAME} ${VERSION} \"${DESCRIPTION}\" - Release ${ARCH} (${SUBVERSION})/gi" -i config/binary_local-includes/README.diskdefines
sed "s/\(^#define ARCH\) \+.*/\1  ${ARCH}/gi" -i config/binary_local-includes/README.diskdefines
sed "s/\(^#define ARCH\).*1$/\1${ARCH}  1/gi" -i config/binary_local-includes/README.diskdefines

sed "s/\(^LB_ARCHITECTURES\).*/\1=\"${ARCH}\"/g" -i config/bootstrap

check_n_umount

lb clean && lb build && lb binary_local-includes --force && lb binary_iso --force
if [ -e binary.iso ]; then
	rename "s/binary\./${NAME}-${VERSION}-${SUBVERSION}-${ARCH}${RELEASE:--${DATE}}./;y/A-Z/a-z/" binary.*
fi
