#!/usr/bin/env pwsh
#
#  Copyright 2023, Roger Brown
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
# $Id: package.ps1 276 2023-12-08 03:16:53Z rhubarb-geek-nz $
#

$MAVEN_VERSION = "3.8.8"
$JANSI_TAG = 'jansi-2.4.0'
$ZIPFILE = "apache-maven-$MAVEN_VERSION-bin.zip"
$URL = "https://dlcdn.apache.org/maven/maven-3/$MAVEN_VERSION/binaries/$ZIPFILE"
$SRCDIR = "src/apache-maven-$MAVEN_VERSION"
$JANSIARCH = "$JANSI_TAG-arm64"
$JANSIDLL = "$JANSIARCH\jansi.dll"
$JANSIDIR = "$SRCDIR\lib\jansi-native\Windows\arm64"
$JANSIURL = "https://github.com/rhubarb-geek-nz/jansi-msvc/releases/download/$JANSI_TAG/$JANSIARCH.zip"

$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"

trap
{
	throw $PSItem
}

dotnet tool restore

If ( $LastExitCode -ne 0 )
{
	Exit $LastExitCode
}

if (!(test-path -PathType container '$JANSIARCH'))
{
	Write-Host $JANSIURL

	Invoke-WebRequest -Uri $JANSIURL -OutFile "$JANSIARCH.zip"

	Expand-Archive -LiteralPath "$JANSIARCH.zip" -DestinationPath "$JANSIARCH"
}

$path = "src"

If(!(test-path -PathType container $path))
{
	$Null = New-Item -ItemType Directory -Path $path

	Write-Host "$URL"

	Invoke-WebRequest -Uri "$URL" -OutFile "$ZIPFILE"

	Expand-Archive -LiteralPath "$ZIPFILE" -DestinationPath "$path"

	$Null = New-Item -ItemType Directory -Path "$JANSIDIR"

	Copy-Item -Path "$JANSIDLL" -Destination "$JANSIDIR"
}

@'
<?xml version="1.0" encoding="UTF-8"?>
<Wix xmlns="http://schemas.microsoft.com/wix/2006/wi">
  <Product Id="*" Name="Apache Maven 3.8.8" Language="1033" Version="3.8.8" Manufacturer="maven.apache.org" UpgradeCode="66C107E1-0655-4DB5-8608-6B26C3EADD6A">
    <Package InstallerVersion="200" Compressed="yes" InstallScope="perMachine" Platform="x64" Description="Maven build tool" Comments="Maven 3.8.8" />
    <MediaTemplate EmbedCab="yes" />
    <Feature Id="ProductFeature" Title="setup" Level="1">
      <ComponentGroupRef Id="ProductComponents" />
    </Feature>
    <Upgrade Id="{66C107E1-0655-4DB5-8608-6B26C3EADD6A}">
      <UpgradeVersion Maximum="3.8.8" Property="OLDPRODUCTFOUND" OnlyDetect="no" IncludeMinimum="yes" IncludeMaximum="no" />
    </Upgrade>
    <InstallExecuteSequence>
      <RemoveExistingProducts After="InstallInitialize" />
    </InstallExecuteSequence>
    <UIRef Id="WixUI_Minimal" />
    <WixVariable Id="WixUILicenseRtf" Value="license.rtf" /> 
  </Product>
  <Fragment>
    <Directory Id="TARGETDIR" Name="SourceDir">
      <Directory Id="ProgramFiles64Folder">
        <Directory Id="INSTALLPARENT" Name="Apache Software Foundation">
          <Directory Id="INSTALLDIR" Name="Apache Maven 3.8.8">
          </Directory>
        </Directory>
      </Directory>
    </Directory>
  </Fragment>
  <Fragment>
    <ComponentGroup Id="ProductComponents">
      <Component Id="mvn.cmd" Guid="*" Directory="INSTALLDIR" Win64="yes" >
        <File Id="mvn.cmd" KeyPath="yes" />
      </Component>
    </ComponentGroup>
  </Fragment>
</Wix>
'@ | dotnet dir2wxs -o "maven.wxs" -s "$SRCDIR"

If ( $LastExitCode -ne 0 )
{
	Exit $LastExitCode
}

Get-Content "$SRCDIR\LICENSE" | dotnet txt2rtf "\fs20" > "license.rtf" 

If ( $LastExitCode -ne 0 )
{
	Exit $LastExitCode
}

& "$ENV:WIX/bin/candle.exe" -nologo "maven.wxs" -ext WixUtilExtension 

If ( $LastExitCode -ne 0 )
{
	Exit $LastExitCode
}

& "$ENV:WIX/bin/light.exe" -nologo -cultures:null -out "apache-maven-$MAVEN_VERSION.msi" "maven.wixobj" -ext WixUtilExtension -ext WixUIExtension

If ( $LastExitCode -ne 0 )
{
	Exit $LastExitCode
}

& signtool sign /a /sha1 601A8B683F791E51F647D34AD102C38DA4DDB65F /fd SHA256 /t http://timestamp.digicert.com "apache-maven-$MAVEN_VERSION.msi"

If ( $LastExitCode -ne 0 )
{
	Exit $LastExitCode
}
