AirportDisplay version 2.3 - mar 2012
=====================================

AirportDisplay is a flight information display used by 
Infraero (brazilian airport authority) in two of 
the largest brazilian airports, since 2002
(Guarulhos-São Paulo and Congonhas-São Paulo)

It runs on Windows machines and can be used 
in single LCD displays or video walls (see screenshots)

Visually, it emulates old style mechanical plate displays
(where plates cascade sequencialy until the right
 information plate is reached), which it actually substituted. 
Flight information is obtained from http server and 
is parsed from html or xml. 

Using http server to deliver flight information to 
displays allows good isolation between airport information 
systems and displays. Also scales well to multiple displays.
Converting it to another http source and format is simple enough.

Other features:
- Arrival/departure and gate displays
- Embedded http server in each display allows remote monitoring
  of display status
- Dual language status messages 
- Configuration of airlines, messages, status etc using
  simple text files.

1- Compiling AirportDisplay
============================
- Files are for Delphi 7. Other versions of the compiler 
may require some changes to sources.

1) These componentes (included) must be installed 
in the Delphi IDE in order to edit the program forms:

   StateBox.pas 
   HttpSrv2.pas 
   AnimateBear.pas 
   OmFlapLabel.pas 

2) Source Folders:
=====================================
componentes\  - StateBox.pas, strToken.pas, httpMult.pas, 
	        OmColorFader.pas, Debug.pas, AnimGlob.pas,
	        OmFunctionProfiler.pas, Base64.pas,
		SockCmp.pas,Buftcp.pas, HttpSrv2.pas, 
                uThreadFlapSounder.pas,
     		ThreadHttpDownload.pas

htmlparser\   - Html parser component. Used for parsing html and XML
			 
Main source files:

AirportDisplay.dpr - Project file
fADSplash.pas - Splash form
fAirportDisplay.pas - Main display form (departures and arrivals)
fDisplayPortao.pas  - Gate display form (single flight mode)
fDownloadInformacaoDeVoo.pas - Control and configuration form 
OmFlapLabel.pas - Mechanical display visual component
uInformacaoDeVoo.pas - Flight information object

2- Data files (place in the program folder)
AirportDisplay.ini - Configuration (saved by display control form)


locais.txt - Location id --> Location name table
Status.txt - Status id --> Status message table
Airlines.txt - list of airline ids
For each airline provide 3 bitmaps in the following formats:
(example for TAM brazilian airline)

TAM.bmp - 20x60  256 color BMP
TAM_GR.bmp - 120x360 256 color BMP
TAM_VW.bmp - 40x100 256 color BMP
 
3- Program usage
================
- Program runs full screen in 1366x768 resolution 
- Windows XP/Vista/Windows 7
- Use Ctrl-F1 do show/hide mouse cursor
- Right click mouse button to open context menu (for editing config)

4- License
==========

Airport display is released by Omar Reis <omar@tecepe.com.br>
under Mozilla Public License. 

see http://www.mozilla.org/MPL/
