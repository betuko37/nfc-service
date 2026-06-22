ACS CCID PC/SC Driver Installer for Mac OS X
Advanced Card Systems Ltd.



Introduction
------------

acsccid is a PC/SC driver for Linux/Mac OS X and it supports ACS CCID smart card
readers. This library provides a PC/SC IFD handler implementation and
communicates with the readers through the PC/SC Lite resource manager (pcscd).

acsccid is based on ccid. See CCID free software driver [1] for more
information.

[1] https://ccid.apdu.fr/



System Requirements
-------------------

Mac OS X 10.7 or above



Supported Readers
-----------------

CCID Readers

VID  PID  Reader              Reader Name
---- ---- ------------------- -----------------------------
072F B301 ACR32-A1            ACS ACR32 ICC Reader
072F B304 ACR3201-A1          ACS ACR3201 ICC Reader
072F B305 ACR3201             ACS ACR3201 ICC Reader
072F 8300 ACR33U-A1           ACS ACR33U-A1 3SAM ICC Reader
072F 8302 ACR33U-A2           ACS ACR33U-A2 3SAM ICC Reader
072F 8307 ACR33U-A3           ACS ACR33U-A3 3SAM ICC Reader
072F 8301 ACR33U              ACS ACR33U 4SAM ICC Reader
072F 90CC ACR38U-CCID         ACS ACR38U-CCID
072F 90CC ACR100-CCID         ACS ACR38U-CCID
072F 90D8 ACR3801             ACS ACR3801
072F B100 ACR39U              ACS ACR39U ICC Reader
072F B500 ACR39 BL            ACS ACR39 FW_Upgrade
072F B101 ACR39K              ACS ACR39K ICC Reader
072F B102 ACR39T              ACS ACR39T ICC Reader
072F B103 ACR39F              ACS ACR39F ICC Reader
072F B104 ACR39U-SAM          ACS ACR39U-SAM ICC Reader
072F B10C ACR39U-U1           ACS ACR39U ID1 Card Reader
072F B113 ACR39U-W1           ACS ACR39U-W1 Top ICC Reader
072F B114 ACR39U-W1           ACS ACR39U-W1 Edge ICC Reader
072F B116 ACR39U-W1           Z_ACS ACR39U-W1 Top Reader
072F B117 ACR39U-W1           Z_ACS ACR39U-W1 Edge Reader
072F B000 ACR3901U            ACS ACR3901 ICC Reader
072F B501 ACR40T              ACS ACR40T ICC Reader
072F B504 ACR40T BL           ACS ACR40 FW_Upgrade
072F B506 ACR40U              ACS ACR40U ICC Reader
072F B505 ACR40U BL           ACS SCR FW_Upgrade
072F 90D2 ACR83U-A1           ACS ACR83U
072F 8306 ACR85               ACS ACR85 PINPad Reader
072F 2011 ACR88U              ACS ACR88U
072F 8900 ACR89U-A1           ACS ACR89 ICC Reader
072F 8901 ACR89U-A2           ACS ACR89 Dual Reader
072F 8902 ACR89U-FP           ACS ACR89 FP Reader
072F 1205 ACR100I             ACS ACR100 ICC Reader
072F 1204 ACR101              ACS ACR101 ICC Reader
072F 1206 ACR102              ACS ACR102 ICC Reader
072F 2200 ACR122U             ACS ACR122U
072F 2200 ACR122U-SAM         ACS ACR122U
072F 2200 ACR122T             ACS ACR122U
072F 2214 ACR1222U-C1         ACS ACR1222 1SAM PICC Reader
072F 1280 ACR1222U-C3         ACS ACR1222 1SAM Dual Reader
072F 2207 ACR1222U-C6         ACS ACR1222 Dual Reader
072F 222B ACR1222U-C8         ACS ACR1222 1SAM PICC Reader
072F 2206 ACR1222L-D1         ACS ACR1222 3S PICC Reader
072F 222E ACR123U             ACS ACR123 3S Reader
072F 2237 ACR123U             ACS ACR123 PICC Reader
072F 2219 ACR123U Bootloader  ACS ACR123US_BL
072F 2203 ACR125              ACS ACR125 nPA plus
072F 221A ACR1251U-A1         ACS ACR1251 1S CL Reader
072F 2229 ACR1251U-A2         ACS ACR1251 CL Reader
072F 222D [OEM Reader]        [OEM Reader Name]
072F 2218 ACR1251U-C (SAM)    ACS ACR1251U-C Smart Card Reader
072F 221B ACR1251U-C          ACS ACR1251U-C Smart Card Reader
072F 2232 ACR1251UK           ACS ACR1251K Dual Reader
072F 2242 ACR1251U-C3         ACS ACR1251 1S Dual Reader
072F 2238 ACR1251U-C9         ACS ACR1251 Reader
072F 225F ACR1251T-E2         ACS ACR1251T CL Reader
072F 224F ACM1251U-Z2         ACS ACR1251 CL Reader
072F 223B ACR1252U-A1         ACS ACR1252 1S CL Reader
072F 223B ACR1252U-M1         ACS ACR1252 1S CL Reader
072F 223E ACR1252U-A2         ACS ACR1252 CL Reader
072F 223D ACR1252U BL         ACS ACR1252 USB FW_Upgrade v100
072F 2244 ACR1252U-A1 (PICC)  ACS ACR1252U BADANAMU MAGIC READER
072F 2259 ACR1252U-A1         ACS ACR1252IMP 1S CL Reader
072F 225B ACM1252U-Z2ACE      ACS ACR1252 CL Reader
072F 225C ACM1252U-Z2ACE BL   ACS ACR1252 USB FW_Upgrade v100
072F 226B ACR1252U-MW/MV      ACS WalletMate 1S CL Reader
072F 226A ACR1252U-MW/MV BL   ACS WalletMate USB FW_Upgrade
072F 223F ACR1255U-J1         ACS ACR1255U-J1 PICC Reader
072F 2239 ACR1256U            ACS ACR1256U PICC Reader
072F 2211 ACR1261U-C1         ACS ACR1261 1S Dual Reader
072F 2252 ACR1261U-A          ACS ACR1261 CL Reader
072F 2100 ACR128U             ACS ACR128U
072F 2224 ACR1281U-C1         ACS ACR1281 1S Dual Reader
072F 220F ACR1281U-C2 (qPBOC) ACS ACR1281 CL Reader
072F 2217 ACR1281U-C2 (UID)   ACS ACR1281 Dual Reader
072F 2223 ACR1281U    (qPBOC) ACS ACR1281 PICC Reader
072F 2208 ACR1281U-C3 (qPBOC) ACS ACR1281 Dual Reader
072F 0901 ACR1281U-C4 (BSI)   ACS ACR1281 PICC Reader
072F 220A ACR1281U-C5 (BSI)   ACS ACR1281 Dual Reader
072F 2215 ACR1281U-C6         ACS ACR1281 2S CL Reader
072F 2220 ACR1281U-C7         ACS ACR1281 1S PICC Reader
072F 2233 ACR1281U-K          ACS ACR1281U-K PICC Reader
072F 2234 ACR1281U-K          ACS ACR1281U-K Dual Reader
072F 2235 ACR1281U-K          ACS ACR1281U-K 1S Dual Reader
072F 2236 ACR1281U-K          ACS ACR1281U-K 4S Dual Reader
072F 2213 ACR1283L-D1         ACS ACR1283 4S CL Reader
072F 222C ACR1283L-D2         ACS ACR1283 CL Reader
072F 220C ACR1283 Bootloader  ACS ACR1283U FW Upgrade
072F 2258 ACR1311U-N1         ACS ACR1311 PICC Reader
072F 2303 ACR1552U-M1         ACS ACR1552 1S CL Reader
072F 2308 ACR1552U-M2         ACS ACR1552 CL Reader
072F 2302 ACR1552U BL         ACS ACR1552 USB FW_Upgrade
072F 2307 ACR1552U-ZW         ACS WalletMate II 1S CL Reader
072F 2306 ACR1552U-ZW BL      ACS WalletMate II V2 Upgrade
072F 230A ACR1555U            ACS ACR1555 1S CL Reader
072F 2309 ACR1555U BL         ACS ACR1555 USB FW_Upgrade
072F 2301 ACR1581U-C1         ACS ACR1581 1S Dual Reader
072F 2300 ACR1581U-C1 BL      ACS ACR1581 USB FW_Upgrade
072F 0102 AET62               ACS AET62 PICC Reader
072F 0103 AET62               ACS AET62 1SAM PICC Reader
072F 0100 AET65               ACS AET65 ICC Reader
072F 224A AMR220-C            ACS AMR220 Reader
072F 8201 APG8201-A1          ACS APG8201
072F 8206 APG8201-B2          ACS APG8201-B2
072F 8207 APG8201-B2RO        ACS ACR83U
072F 8202 [OEM Reader]        [OEM Reader Name]
072F 8205 [OEM Reader]        [OEM Reader Name]
072F 90DB CryptoMate64        ACS CryptoMate64
072F B200 ACOS5T1             ACS CryptoMate (T1)
072F B106 ACOS5T2             ACS CryptoMate (T2)
072F B112 ACOS5T2             ACS CryptoMate EVO

non-CCID Readers

VID  PID  Reader              Reader Name
---- ---- ------------------- -----------------------------
072F 9000 ACR38U              ACS ACR38U
072F 90CF ACR38U-SAM          ACS ACR38U-SAM
072F 90CE [OEM Reader]        [OEM Reader Name]
072F 0101 AET65               ACS AET65 1SAM ICC Reader
072F 9006 CryptoMate          ACS CryptoMate



Installation
------------

1. Double click "acsccid_installer-x.y.z.dmg" to mount the disk image file.

2. To install the driver, double click "acsccid_installer.pkg" and follow
   onscreen instructions. It will install acsccid driver package,
   ccid_remove_acs package and pcscd_autostart package from OpenSC project
   (http://www.opensc-project.org/sca/).

3. To uninstall the driver, double click "acsccid_uninstaller.pkg" and follow
   onscreen instructions.



History
-------

v1.1.11.1 (26/8/2024)
- Rebuild the driver v1.1.11.
- Sign the driver and the installer with the latest Developer ID certificates.

v1.1.11 (25/3/2024)
- Update the driver to v1.1.11.

v1.1.10 (4/8/2023)
- Update the driver to v1.1.10.

v1.1.9 (15/3/2023)
- Update the driver to v1.1.9.
- Require Mac OS X 10.7 or above.

v1.1.8.5 (8/2/2023)
- Add the following readers support:
  ACR40T ICC Reader
  ACR40 FW_Upgrade
  WalletMate 1S CL Reader
  WalletMate USB FW_Upgrade

v1.1.8.4 (30/9/2022)
- Add ACR39U-W1 support.

v1.1.8.3 (12/10/2021)
- Add APG8201-B2RO support.
- Fix invalid digital signature issue on Mac OS X 10.11 or earlier.

v1.1.8.2 (5/1/2021)
- Fix segmentation fault for multi-slot readers on macOS Big Sur.

v1.1.8.1 (8/12/2020)
- Rebuild the driver v1.1.8 with arm64 and x86_64 architectures.
- Require Mac OS X 10.6 or above.
- Set host architectures to arm64 and x86_64 in the installer.

v1.1.8 (9/1/2020)
- Update the driver to v1.1.8.

v1.1.7.1 (12/12/2019)
- Remove response timeout fix for APG8201 and APG8201Z.

v1.1.7 (29/7/2019)
- Update the driver to v1.1.7.
- Submit the installer to Apple for notarization.

v1.1.6.3 (11/4/2019)
- Fix APG8201 response timeout issue (Update 2).

v1.1.6.2 (4/4/2019)
- Fix configuration descriptor issue.
- Fix APG8201 response timeout issue.

v1.1.6.1 (27/11/2018)
- Fix card detection issue for multi-slot readers.

v1.1.6 (29/10/2018)
- Update the driver to v1.1.6.

v1.1.5.1 (30/11/2017)
- Fix ACR39U T=0 APDU problem.

v1.1.5 (23/10/2017)
- Update the driver to v1.1.5.

v1.1.4 (7/12/2016)
- Update the driver to v1.1.4.

v1.1.3 (22/6/2016)
- Update the driver to v1.1.3.

v1.1.2 (18/2/2016)
- Update the driver to v1.1.2.

v1.1.1 (9/11/2015)
- Update the driver to v1.1.1.

v1.1.0.1 (14/10/2015)
- Update the driver location to "/usr/local/libexec/SmartCardServices/drivers".
- Rebuild the driver v1.1.0 with i386 and x86_64 architectures.
- Convert the installer to flat package format.
- Replace uninstallation scripts with uninstaller package.
- Sign the installer with Developer ID Installer certificate.
- Remove pcscd_autostart package on Mac OS X 10.10 after installation.
- Install ccid_remove_acs package if Mac OS X version is less than 10.11.
- Restart the system after installation.

v1.1.0 (17/12/2014)
- Update the driver to v1.1.0.
- Install pcscd_autostart package if Mac OS X version is less than 10.10.

v1.0.8 (3/7/2014)
- Update the driver to v1.0.8.

v1.0.7 (16/6/2014)
- Update the driver to v1.0.7.

v1.0.6 (17/4/2014)
- Update the driver to v1.0.6.
- Fix ccid_remove_acs installation problem.

v1.0.5 (11/9/2013)
- Update the driver to v1.0.5.

v1.0.4 (15/6/2012)
- Update the driver to v1.0.4.

v1.0.3 (13/1/2012)
- Update the driver to v1.0.3.

v1.0.2 (10/8/2011)
- Fix pcscd autostart problem on Mac OS X 10.7.
- Remove ACS readers from Apple CCID driver.

v1.0.2 (16/3/2011)
- Update the driver to v1.0.2.

v1.0.1 (9/11/2009)
- Update the driver to v1.0.1.

v1.0.0 (14/10/2009)
- Test the driver on Mac OS X 10.6.
- Update uninstall script.

v1.0.0 (18/9/2009)
- New release.
- Based on ccid-1.3.11 (http://pcsclite.alioth.debian.org/ccid.html).
- Include pcscd_autostart package from OpenSC project
  (http://www.opensc-project.org/sca/). It will make pcscd to run at startup.
- There is a pcscd problem supporting multi-slot readers on Mac OS X. It will
  create duplicate reader name for each slot. ACR88U and ACR128U readers are
  affected by this bug. For more information, please refer to
  http://www.opensc-project.org/sca/wiki/LeopardBugs.



Support
-------

In case of problem, please contact ACS through:

Web Site: http://www.acs.com.hk/
E-mail: info@acs.com.hk
Tel: +852 2796 7873
Fax: +852 2796 1286



-------------------------------------------------------------------------------
Copyright (C) 2009-2024 Advanced Card Systems Ltd.
Copyright (C) 2003-2011 Ludovic Rousseau
Copyright (C) 2000-2001 Carlos Prados
Copyright (C) 2003 Olaf Kirch
Copyright (C) 1999-2002 Matthias Bruestle

This library is free software; you can redistribute it and/or
modify it under the terms of the GNU Lesser General Public
License as published by the Free Software Foundation; either
version 2.1 of the License, or (at your option) any later version.

This library is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
Lesser General Public License for more details.

You should have received a copy of the GNU Lesser General Public
License along with this library; if not, write to the Free Software
Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301  USA
