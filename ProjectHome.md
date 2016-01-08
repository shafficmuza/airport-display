**AirportDisplay** is a flight information display used in some of the largest Brazilian airports.It runs on Windows machines (2k/XP/Vista/W7) and can be used in single LCD displays or video walls (see screenshot in downloads section).

Visually, it emulates old style mechanical plate displays (where plates cascade sequentially until the right information plate is reached), which it actually substituted. Flight information is obtained from http server and is parsed from html or xml.

Using http server to deliver flight information to displays allows good isolation between airport information systems and displays. Also scales well to multiple displays. Converting it to another http source and format is simple enough.

## Other features ##
  * Arrival/departure and gate displays.
  * Embedded http server in each display allows remote monitoring of display status.
  * Dual language status messages.
  * Configuration of airlines, messages, status etc using simple text files.

## Compiling AirportDisplay ##
Source files are for Delphi 7. Other versions of the compiler may require some changes to sources.

1) These components (included) must be installed in the Delphi IDE in order to edit the program forms:

  * StateBox pas
  * HttpSrv2 pas
  * AnimateBear pas
  * OmFlapLabel pas
  * OmColorFader pas

2) Source Folders:
  * componentes\
  * htmlparser\

Main source files:
  * AirportDisplay dpr - Project file
  * fADSplash pas - Splash form
  * fAirportDisplay pas - Main display form (departures and arrivals)
  * fDisplayPortao pas  - Gate display form (single flight mode)
  * fDownloadInformacaoDeVoo pas - Control and configuration form
  * OmFlapLabel pas - Mechanical display visual component
  * uInformacaoDeVoo pas - Flight information object

## Data files (place in the program folder) ##
  * AirportDisplay.ini - Configuration (saved by display control form)
  * locais.txt - Location id --> Location name table
  * Status.txt - Status id --> Status message table
  * Airlines.txt - list of airline ids

For each airline provide 3 bitmaps in the following formats:
(sample files provided for TAM brazilian airline)

  1. TAM.bmp - 20x60  256 color BMP.
  1. TAM\_GR.bmp - 120x360 256 color BMP.
  1. TAM\_VW.bmp - 40x100 256 color BMP.

Files vstaff.041.html and vstaff.031.html contain sample data.

## Program usage ##
  * Program runs full screen in 1366x768 resolution
  * Windows XP/Vista/Windows 7
  * Use Ctrl-F1 do show/hide mouse cursor (cursor initially hidden)
  * Right click mouse button to open context menu (for editing config)

## License ##
> Mozilla Public License.
> see http://www.mozilla.org/MPL/
