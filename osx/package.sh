#!/bin/sh -e
#
# Copyright 2023, Roger Brown
#
# This file is part of rhubarb pi.
#
# This program is free software: you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by the
# Free Software Foundation, either version 3 of the License, or (at your
# option) any later version.
# 
# This program is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
# FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
# more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>
#
# $Id: package.sh 280 2023-12-08 13:35:41Z rhubarb-geek-nz $
#

VERSION=3.8.8
PKGNAME=maven
ZIPFILE="apache-$PKGNAME-$VERSION-bin.tar.gz"
IDENTIFIER=nz.geek.rhubarb.maven

trap "rm -rf root $PKGNAME.pkg distribution.xml $ZIPFILE" 0

if test ! -f "$ZIPFILE"
then
	curl --silent --location --fail --output "$ZIPFILE" "https://dlcdn.apache.org/maven/maven-3/$VERSION/binaries/$ZIPFILE"
fi

mkdir -p root/share root/bin

(
	set -e

	cd root/share

	tar xfz "../../$ZIPFILE"

	mv "apache-$PKGNAME-$VERSION" "$PKGNAME"

	rm -rf "$PKGNAME/src"

	cd "$PKGNAME/bin"
	rm *.cmd
)

cat > "root/bin/mvn" <<EOF
#!/bin/sh -e
#
# Copyright 2022, Roger Brown
#
# This file is part of rhubarb pi.
#
# This program is free software: you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by the
# Free Software Foundation, either version 3 of the License, or (at your
# option) any later version.
# 
# This program is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
# FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
# more details.
#
# See <http://www.gnu.org/licenses/>
#

JAVA_HOME=\$(/usr/libexec/java_home) exec /usr/local/share/$PKGNAME/bin/mvn "\$@"
EOF

tail -1 "root/bin/mvn" 

chmod +x "root/bin/mvn" 

pkgbuild \
	--identifier $IDENTIFIER \
	--version "$VERSION" \
	--root root \
	--install-location /usr/local \
	--timestamp \
	--sign "Developer ID Installer: $APPLE_DEVELOPER" \
	"$PKGNAME.pkg"

cat > distribution.xml <<EOF
<?xml version="1.0" encoding="utf-8"?>
<installer-gui-script minSpecVersion="1">
    <pkg-ref id="$IDENTIFIER"/>
    <options customize="never" require-scripts="false" hostArchitectures="x86_64,arm64"/>
    <choices-outline>
        <line choice="default">
            <line choice="$IDENTIFIER"/>
        </line>
    </choices-outline>
    <choice id="default"/>
    <choice id="$IDENTIFIER" visible="false">
        <pkg-ref id="$IDENTIFIER"/>
    </choice>
    <pkg-ref id="$IDENTIFIER" version="$VERSION" onConclusion="none">$PKGNAME.pkg</pkg-ref>
    <title>Apache Maven - $VERSION</title>
</installer-gui-script>
EOF

productbuild --distribution ./distribution.xml --package-path . ./$PKGNAME-$VERSION.pkg --sign "Developer ID Installer: $APPLE_DEVELOPER" --timestamp
