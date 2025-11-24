ACS Unified PC/SC Driver Installer (MSI)
Advanced Card Systems Ltd.



Contents
----------------

   1. Release Notes
   2. Installation
   3. History
   4. File Contents
   5. Limitations
   6. Support



1. Release Notes
----------------

Version: 4.2.8.0
Release Date: 03/20/2018 

Supported Readers
-----------------

CCID Readers

VID  PID  Reader                  Reader Name
---- ---- ----------------------- -----------------------------
072F B301 ACR32-A1                ACS ACR32 ICC Reader
072F 8300 ACR33-A1                ACS ACR33U-A1 3SAM ICC Reader
072F 8302 ACR33-A2                ACS ACR33U-A2 3SAM ICC Reader
072F 8307 ACR33-A3                ACS ACR33U-A3 3SAM ICC Reader
072F 8301 ACR33XX-4SAM            ACS ACR33U 4SAM ICC Reader
072F 90CC ACR38U-CCID/ACR100F     ACS CCID USB Reader
072F 90D8 ACR3801                 ACS ACR3801
072F B100 ACR39U                  ACS ACR39 ICC Reader
072F B100 ACR39T-A3               ACS ACR39T-A3 ICC Reader
072F B000 ACR3901U                ACS ACR3901 ICC Reader
072F B001 ACR3901U Bootloader     ACS ACR3901U USB FW_Upgrade
072F 2500 ACR3901U Old Bootloader ACS ACR3901U USB FW_Upgrade
072F 90D2 ACR83U-A1               ACS ACR83U
072F 2010 ACR88U CCID             ACS ACR88
072F 8900 ACR89U-A1               ACS ACR89 ICC Reader
072F 8901 ACR89-A2/A3             ACS ACR89 Dual Reader
072F 8902 ACR89U FP               ACS ACR89 FP Reader
072F 1205 ACR100I                 ACS ACR100 ICC Reader
072F 1204 ACR101                  ACS ACR101 ICC Reader
072F 1206 ACR102                  ACS ACR102 ICC Reader
072F 2200 ACR122U/T               ACS ACR122
072F 2214 ACR1222U-C1             ACS ACR1222 1 SAM PICC Reader
072F 1280 ACR1222U-C3             ACS ACR1222 1 SAM Dual Reader
072F 2207 ACR1222U-C6             ACS ACR1222 Dual Reader
072F 2206 ACR1222L-D1             ACS ACR1222 3S PICC Reader
072F 2219 ACR123 Bootloader       ACS ACR123US_BL
072F 222E ACR123U-A1              ACS ACR123 3S Reader
072F 2237 ACR123U                 ACS ACR123 Reader
072F 224F ACM1251U-Z2             ACS ACR1251 CL Reader PICC
072F 221A ACR1251U-A1             ACS ACR1251 1S CL Reader
072F 2229 ACR1251U-A2             ACS ACR1251 CL Reader PICC
072F 221B ACR1251U-C              ACS ACR1251U Smart Card Reader
072F 2218 ACR1251U-C (SAM)        ACS ACR1251U-C Smart Card Reader
072F 2232 ACR1251U-K              ACS ACR1251K Dual Reader
072F 2242 ACR1251U-C3             ACS ACR1251 1S Dual Reader
072F 223B ACR1252U-A1             ACS ACR1252 1S CL Reader
072F 2259 ACR1252U-A1 (Imprivita) ACS ACR1252IMP 1S CL Reader
072F 223E ACR1252U-A2             ACS ACR1252 CL Reader PICC
072F 223D ACR1252U Bootloader     ACS ACR1252 USB FW_Upgrade v100
072F 223F ACR1255U-J1             ACS ACR1255U-J1 PICC Reader
072F 2239 ACR1256U                ACS ACR1256U PICC Reader
072F 2252 ACR1261U-A              ACS ACR1261 CL Reader PICC
072F 2211 ACR1261U-C1             ACS ACR1261 1S Dual Reader
072F 2100 ACR128U                 ACS ACR128U
072F 220B ACR1251U Bootloader     ACS ACR1281 USB FW_Upgrade v100
072F 2224 ACR1281U-C1             ACS ACR1281 1S Dual Reader
072F 220F ACR1281U-C2 (qPBOC)     ACS ACR1281 CL Reader
072F 2223 ACR1281U    (qPBOC)     ACS ACR1281 PICC Reader
072F 2208 ACR1281U-C3 (qPBOC)     ACS ACR1281 Dual Reader
072F 0901 ACR1281U-C4 (BSI)       ACS ACR1281 PICC Reader
072F 220A ACR1281U-C5 (BSI)       ACS ACR1281 Dual Reader
072F 2215 ACR1281U-C6             ACS ACR1281 2S CL Reader
072F 2220 ACR1281U-C7             ACS ACR1281 1S PICC Reader
072F 2233 ACR1281U-K (PICC)       ACS ACR1281U-K PICC Reader
072F 2234 ACR1281U-K (Dual)       ACS ACR1281U-K Dual Reader
072F 2235 ACR1281U-K (1S)         ACS ACR1281U-K 1S Dual Reader
072F 2236 ACR1281U-K (4S)         ACS ACR1281U-K 4S Dual Reader
072F 220C ACR1283 Bootloader      ACS ACR1283U FW Upgrade
072F 2213 ACR1283L-D1             ACS ACR1283 4S CL Reader
072F 2258 ACR1311                 ACS ACR1311 PICC Reader
072F 222C ACR1283L-D2             ACS ACR1283 CL Reader PICC
072F 0102 AET62                   ACS AET62 PICC Reader PICC
072F 0103 AET62 (1S)              ACS AET62 1SAM PICC Reader
072F 8002 AET63U                  ACS BioTRUSTKey
072F 0100 AET65                   ACS AET65 ICC Reader ICC
072F 224A AMR220                  ACS AMR220 Reader
072F 8201 APG8201                 ACS APG8201
072F 8206 APG8201-B2              ACS APG8201-B2
072F 90DB CryptoMate64            ACS CryptoMate64
072F B200 CryptoMate (T1)         ACS CryptoMate (T1)
072F B106 CryptoMate (T2)         ACS CryptoMate (T2)

non-CCID Readers

VID  PID  Reader                  Reader Name
---- ---- ----------------------- -----------------------------
072F 0001 ACR30                   ACS USB
072F 9000 ACR38 FW110             ACS ACR38U
072F 90CF ACR38USAM               ACS ACR38USB
072F 2011 ACR88                   ACS ACR88
072F 0101 AET65 (1S)              ACS AET65 1SAM ICC Reader
072F 9006 CryptoMate              ACS CryptoMate

1. Supported Operating Systems    
    Windows XP 32-bit
    Windows XP 64-bit
    Windows Server 2003 32-bit
    Windows Server 2003 64-bit
    Windows Vista 32-bit
    Windows Vista 64-bit
    Windows Server 2008 32-bit
    Windows Server 2008 64-bit
    Windows Server 2008 R2 64-bit
    Windows 7 32-bit
    Windows 7 64-bit
    Windows 8 32-bit
    Windows 8 64-bit
    Windows 8.1 32-bit
    Windows 8.1 64-bit
    Windows Server 2012 64-bit
    Windows Server 2012 R2 64-bit
    Windows 10 32-bit
    Windows 10 64-bit
    Windows Server 2016 64-bit    

2. Supported Languages
    Arabic
    Chinese (Simplified)
    Chinese (Traditional)
    Czech
    Danish
    Dutch
    English
    Finnish
    French
    German
    Greek
    Hebrew
    Hungarian
    Italian
    Japanese
    Korean
    Norwegian
    Polish
    Portuguese (Brazil)
    Portuguese (Portugal)
    Romanian (Romania)
    Russian
    Spanish
    Swedish
    Turkish
    Ukrainian

3. Driver Versions
    v4.2.8.0

4. Command Options

    Setup [option]

    /q          Quiet mode
    /x          Uninstall driver
    /norestart  Do not restart after driver installation/uninstallation

    Exit Codes:

    ERROR_SUCCESS                       0x00000000  Success
    ERROR_FILE_NOT_FOUND                0x00000002  File not found
    ERROR_NOT_ENOUGH_MEMORY             0x00000008  Not enough memory
    SETUP_ERROR_OS_NOT_SUPPORTED        0x20000001  Operating system is not supported
    SETUP_ERROR_WINNT4_SP6_REQUIRED     0x20000002  Windows NT 4.0 Service Pack 6 is required
    SETUP_ERROR_UNEXPECTED              0x20000003  Unexpected error
    SETUP_ERROR_MSI2_REQUIRED           0x20000004  Windows Installer 2.0 is required
    SETUP_ERROR_MSI_LOCATION_NOT_FOUND  0x20000005  Cannot find the location of Windows Installer

    Note: Other error codes are defined in Windows API and MSI.



2. Installation
---------------

1. Before running the Setup program, please unplug the reader first.
2. Double click the "Setup.exe" program icon to launch the installer. If your system does not have installed Windows Installer 2.0 or above, you will receive a warning message and you need to go to Windows Update to update your system.
3. Follow the on-screen instructions to install the driver to the system.
4. After the installation is completed, please plug the reader to the system.
5. To remove the driver, please go to "Add or Remove Programs" in Control Panel.



3. History
----------

v4.0.0.0 (11/11/2013)
1. New release.

v4.0.1.0 (12/2/2014)
1. Updated drivers to v4.0.0.1.

v4.0.2.0 (26/3/2014)
1. Updated drivers to v4.0.0.2.

v4.0.3.0 (15/5/2014)
1. Updated drivers to v4.0.0.3.

v4.0.4.0 (21/8/2014)
1. Updated drivers to v4.0.0.4.

v4.0.5.0 (30/10/2014)
1. Updated drivers to v4.0.0.5.

v4.0.6.0 (14/11/2014)
1. Updated drivers to v4.0.0.6.

v4.0.7.0 (02/6/2015)
1. Updated drivers to v4.0.0.7.

v4.0.7.1 (24/8/2015)
1. Updated drivers to v4.0.0.7.

v4.1.0.0 (05/10/2015)
1. Updated drivers to v4.1.0.0.

v4.1.2.0 (23/11/2015)
1. Updated drivers to v4.1.2.0.

v4.1.4.0 (07/03/2016)
1. Updated drivers to v4.1.4.0.

v4.1.5.0 (22/03/2016)
1. Updated drivers to v4.1.5.0.

v4.1.6.0 (15/06/2016)
1. Updated drivers to v4.1.6.0.

v4.1.7.0 (24/10/2016)
1. Updated drivers to v4.1.7.0.

v4.2.0.0 (28/11/2016)
1. Updated drivers to v4.2.0.0.

v4.2.1.0 (14/12/2016)
1. Updated drivers to v4.2.1.0.

v4.2.2.0 (26/01/2017)
1. Updated drivers to v4.2.2.0.

v4.2.3.0 (17/04/2017)
1. Updated drivers to v4.2.3.0.

v4.2.4.0 (25/05/2017)
1. Updated drivers to v4.2.4.0.

v4.2.5.0 (03/07/2017)
1. Updated drivers to v4.2.5.0.

v4.2.6.0 (15/09/2017)
1. Updated drivers to v4.2.6.0.

v4.2.7.0 (03/01/2018)
1. Updated drivers to v4.2.7.0.

v4.2.8.0 (03/20/2018)
1. Updated drivers to v4.2.8.0.


4. File Contents
----------------

|   ReadMe.txt
|   Setup.exe
|   Setup.ini
|
+---redist
|       InstMsiW.exe
|
+---x64
|       ACS_Unified_PCSC_Driver-4.2.8.0.msi
|       Arabic.mst
|       Chinese (Simplified).mst
|       Chinese (Traditional).mst
|       Czech.mst
|       Danish.mst
|       Dutch.mst
|       Finnish.mst
|       French.mst
|       German.mst
|       Greek.mst
|       Hebrew.mst
|       Hungarian.mst
|       Italian.mst
|       Japanese.mst
|       Korean.mst
|       Norwegian.mst
|       Polish.mst
|       Portuguese (Brazil).mst
|       Portuguese (Portugal).mst
|       Romanian (Romania).mst
|       Russian.mst
|       Spanish.mst
|       Swedish.mst
|       Turkish.mst
|       Ukrainian.mst
|
\---x86
        ACS_Unified_PCSC_Driver-4.2.8.0.msi
        Arabic.mst
        Chinese (Simplified).mst
        Chinese (Traditional).mst
        Czech.mst
        Danish.mst
        Dutch.mst
        Finnish.mst
        French.mst
        German.mst
        Greek.mst
        Hebrew.mst
        Hungarian.mst
        Italian.mst
        Japanese.mst
        Korean.mst
        Norwegian.mst
        Polish.mst
        Portuguese (Brazil).mst
        Portuguese (Portugal).mst
        Romanian (Romania).mst
        Russian.mst
        Spanish.mst
        Swedish.mst
        Turkish.mst
        Ukrainian.mst



5. Limitations
--------------



6. Support
----------

In case of problem, please contact ACS through:

Web Site: http://www.acs.com.hk/
E-mail: info@acs.com.hk
Tel: +852 2796 7873
Fax: +852 2796 1286



-----------------------------------------------------------------


Copyright
Copyright by Advanced Card Systems Ltd. (ACS) No part of this reference manual may be reproduced or transmitted in any from without the expressed, written permission of ACS.

Notice
Due to rapid change in technology, some of specifications mentioned in this publication are subject to change without notice. Information furnished is believed to be accurate and reliable. ACS assumes no responsibility for any errors or omissions, which may appear in this document.
