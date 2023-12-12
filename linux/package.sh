#!/bin/sh -e
#
#  Copyright 2022, Roger Brown
#
#  This file is part of rhubarb pi.
#
#  This program is free software: you can redistribute it and/or modify it
#  under the terms of the GNU General Public License as published by the
#  Free Software Foundation, either version 3 of the License, or (at your
#  option) any later version.
# 
#  This program is distributed in the hope that it will be useful, but WITHOUT
#  ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
#  FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
#  more details.
#
#  You should have received a copy of the GNU General Public License
#  along with this program.  If not, see <http://www.gnu.org/licenses/>
#
# $Id: package.sh 289 2023-12-12 18:42:14Z rhubarb-geek-nz $
#

VERSION=3.9.6
INTDIR="$(pwd)"
SPECFILE="$INTDIR/rpm.spec"
TGTPATH="$INTDIR/rpm.dir"
BASEDIR="$INTDIR/root"
PKGROOT=usr/share/maven
RPMBUILD=rpm
RELEASE=1

trap "chmod -R +w root ; rm -rf root $SPECFILE $TGTPATH $BASEDIR" 0

if test ! -f "apache-maven-$VERSION-bin.tar.gz"
then
	curl --location --fail --silent --output "apache-maven-$VERSION-bin.tar.gz" "https://dlcdn.apache.org/maven/maven-3/$VERSION/binaries/apache-maven-$VERSION-bin.tar.gz"
fi

mkdir -p "$TGTPATH" $(dirname "$BASEDIR/$PKGROOT")

tar xfz  "apache-maven-$VERSION-bin.tar.gz"

mv "apache-maven-$VERSION" "$BASEDIR/$PKGROOT"

rm -rf *.rpm

if rpmbuild --help >/dev/null
then
    RPMBUILD=rpmbuild
fi

(
	cat << EOF
Summary: Apache Maven $VERSION
Name: maven
Version: $VERSION
BuildArch: noarch
Release: $RELEASE
Group: Applications/System
License: GPL
Prefix: /

%description
Apache Maven is a software project management and comprehension tool. Based on the concept of a project object model (POM), Maven can manage a project's build, reporting and documentation from a central piece of information.

%post
if test ! -L /etc/alternatives/mvn && test ! -e /etc/alternatives/mvn
then
	ln -s /usr/share/maven/bin/mvn /etc/alternatives/mvn	
fi
if test ! -L /usr/bin/mvn && test ! -e /usr/bin/mvn
then
	ln -s /etc/alternatives/mvn /usr/bin/mvn
fi

%postun
if test -L /etc/alternatives/mvn
then
	if test /usr/share/maven/bin/mvn = "\$(readlink /etc/alternatives/mvn)"
	then
		rm /etc/alternatives/mvn
		if test -L /usr/bin/mvn
		then
			if test /etc/alternatives/mvn = "\$(readlink /usr/bin/mvn)"
			then
				rm /usr/bin/mvn
			fi
		fi
	fi
fi

EOF

	echo "%files"
	echo "%defattr(-,root,root)"
	cd "$BASEDIR"

	find "$PKGROOT" | while read N
	do
		if test -L "$N"
		then
			echo "/$N"
		else
			if test -d "$N"
			then
				echo "%dir %attr(555,root,root) /$N"
			else
				if test -f "$N"
				then
					if test -x "$N"
					then
						echo "%attr(555,root,root) /$N"
					else
						echo "%attr(444,root,root) /$N"	
					fi
				fi
			fi
		fi
	done

	echo
	echo "%clean"
	echo echo clean "$\@"
	echo
) >$SPECFILE

"$RPMBUILD" --buildroot "$BASEDIR" --define "_build_id_links none" --define "_rpmdir $TGTPATH" -bb "$SPECFILE"

find  "$TGTPATH" -type f -name "*.rpm" | while read N
do
	mv "$N" .
done

rm "apache-maven-$VERSION-bin.tar.gz"
