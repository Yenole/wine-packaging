{{ __filename = __filename if package_boot else None }}
{{
	output = "%s-%s" % (package, package_version)
	output += "-%s" % package_release if package_release != "" else ""
}}
#!/bin/bash
set -e -x

apt-get update
apt-get upgrade -y
apt-get install -y git devscripts build-essential cmake

{{ =include("../macosx-common.sh") }}

{{
	url = "https://github.com/kcat/openal-soft/archive"
	version = "master" if package_daily else "openal-soft-%s" % package_version
	version = "bce20d1f6be43dcf3a5be0ec97b35cbe335844e7" # HACK
	download("libopenal-soft.tar.gz", "%s/%s.tar.gz" % (url, version), sha)
}}

{{ for (host, arch) in [("i686-apple-darwin12", ""), ("x86_64-apple-darwin12", "64")] }}

su builder -c "mkdir build{{ =arch }}"
cd build{{ =arch }}
su builder -c "tar -xvf ../libopenal-soft.tar.gz --strip-components 1"

su builder -c "cat ../*.patch | patch -p1"

cd build
su builder -c "cmake -D CMAKE_INSTALL_PREFIX=/usr -D CMAKE_INSTALL_NAME_DIR=/usr/lib \
				-D CMAKE_BUILD_TYPE=Release \
				-D CMAKE_TOOLCHAIN_FILE=../../toolchain-{{ =host }}.cmake ../"
cp CMakeCache.txt /build/CMakeCache{{ =arch }}.txt
su builder -c "make VERBOSE=1"
su builder -c "mkdir /build/tmp{{ =arch }}"
su builder -c "make install DESTDIR=/build/tmp{{ =arch }}/"
su builder -c "mkdir -p /build/tmp{{ =arch }}/usr/share/doc/openal-soft"
su builder -c "cp -a ../COPYING /build/tmp{{ =arch }}/usr/share/doc/openal-soft"
su builder -c "/build/source/fixup-import.py --destdir /build/tmp{{ =arch }} --verbose"

cd ../..

{{ endfor }}

su builder -c "(cd /build/tmp; fakeroot tar -cvzf /build/{{ =output }}-osx.tar.gz .)"
su builder -c "./make-universal.py --dir32 /build/tmp --dir64 /build/tmp64"
su builder -c "(cd /build/tmp64; fakeroot tar -cvzf /build/{{ =output }}-osx64.tar.gz .)"
