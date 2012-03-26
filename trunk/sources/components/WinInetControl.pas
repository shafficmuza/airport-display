unit WinInetControl;
{$define DEBUG}
{******************************************************************************}
{*                                                                            *}
{*   Author       : R. Garner         Version       : 0.9b                    *}
{*                                                                            *}
{*   Date Created : 07/04/99          Last Modified : 17/04/99                *}
{*                                                                            *}
{*   Description  : Base WinInet class to encapsulate common functionality    *}
{*                  such as proxy/authentication properties                   *}
{*                                                                            *}
{*   Revision History:                                                        *}
{*    10/05/99    : Fixed Cache Enable bug causing wininet to delete          *}
{*                  freshly-downloaded files                                  *}
{*    22/04/99    : Winshoes code freeze version                              *}
{*    17/04/99    : Added an 'abort' method which forcibly kills the          *}
{*                  Inet handle.  Possibly rather unstable - if so you may    *}
{*                  require a service pack to patch WinInet.dll               *}
{*                  (see MS article Q187770)                                  *}
{*                                                                            *}
{*    08/04/99    : Pre-beta release                                          *}
{*                                                                            *}
{******************************************************************************}

{$ifndef VER80}
  {$ifndef VER90}
    {$define D3ORHIGHER}
  {$endif}
{$endif}

{$ifdef VER130} // Delphi 5
{$else  VER130}
{$endif VER130}

{$ifdef VER140} // Delphi 6
{$else  VER140}
{$endif VER140}

{$ifdef VER150} // Delphi 7
{$else  VER150}
{$endif VER150}

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  {$ifdef D3ORHIGHER}WinInet{$else}WinInetMod{$endif}, comctrls,
  stdctrls;

const
  C_DEFAULT_TIMEOUT= 300000;
  C_DEFAULT_RETRIES= 3;
  // Use resourcestring only if Delphi3/4, otherwise, pretend we have constants.
{$ifdef D3ORHIGHER}
resourcestring
{$endif}
  S_ABOUT_BOX_MSG =
  'TWinInetControl and descendants v0.98b' + #13#10 +
  'By R. Garner' + #13#10 +
  '© 1998, 1999 Zephyros Systems Ltd.' + #13#10 +
  'mailto:zephyros.systems@virgin.net';

  S_CEFTP_ABOUT                         = 'Abou&t';
  S_CEFTP_ERROR                         = 'Whoops ... your CE has gone bang';
  S_INTERNETPAGE                        = 'Winshoes';

  S_STATE_DISCONNECTING               = 'Disconnecting from %s';
  S_STATE_NOCONNECTION                = 'No connection';
  S_STATE_CONNECTING                  = 'Connecting to %s';
  S_STATE_CONNECTED                   = 'Connected to %s';
  S_STATE_RESOLVING_NAME              = 'Resolving name %s';
  S_STATE_NAME_RESOLVED               = 'Resolved name %s';

  S_STATE_UNKNOWN                     = 'Unknown state!  Contact support ...';

  S_ERROR_INTERNET_GENERAL_ERROR      = 'General Connection Error to %s';
  S_ERROR_INTERNET_HANDLE_CLOSE       = 'Error %d (%s) closing Inet handle %x';
  S_ERROR_INTERNET_INCORRECT_USER_NAME=
    'Bad user name: ''%s'' connecting to %s';
  S_ERROR_INTERNET_INCORRECT_PASSWORD = 'Bad password connecting to %s';
  S_ERROR_INTERNET_CANNOT_CONNECT     = 'Unable to connect to %s';
  S_ERROR_INTERNET_LOGIN_FAILURE      = 'Unable to login to %s';
  S_ERROR_INTERNET_NAME_NOT_RESOLVED  = 'Unable to resolve host name ''%s''';
  S_ERROR_INTERNET_INTERNAL_ERROR     = 'Internal WININET error';
  S_ERROR_INTERNET_TIMEOUT            = 'Connection to %s timed out';
  S_ERROR_NOT_CONNECTED               = 'Not connected!';
  S_ERROR_NO_ERROR_STRING             = 'No error description available';

type
  EWinInetError = class(Exception);

  TWinInetControl = class;

  {
    Current connection status
  }
  TWinInetState = (
    fsDisconnecting,
    fsNoconnection,
    fsConnecting,
    fsConnected,
    fsResolvingName,
    fsNameResolved
  );

  // Resolve names from a) Hosts file, b) Registry DNS, or c) Proxy
  TResolveNames = (rnLocal, rnPreConfig, rnProxy);

  TStateChangeEvent = procedure (
    Sender:   TObject;
    NewState: TWinInetState
  ) of object;

  TInetAbortThread = class(TThread)
  private
    FOwner:     TWinInetControl;
  public
    constructor Create(AOwner: TWinInetControl);
    procedure   Execute; override;

    property    Owner: TWinInetControl read FOwner;
  end;

  TWinInetControl = class(TComponent)
  private
    { Private declarations }
    FOnConnected           : TNotifyEvent;
    FOnDisconnected        : TNotifyEvent;
    FOnStateChange         : TStateChangeEvent;
    FConnectRetries        : DWORD;
    FAPI_ResolveNames      : DWORD;
    FResolveNames          : TResolveNames;

    FPort                  : Integer;
    FConnectTimeOut        : DWORD;

    FState                 : TWinInetState;

    FQuickProgress         : Boolean;
    FQuickProgressMajor,
    FQuickProgressMinor    : TProgressBar;

    FQuickLabelMajor,
    FQuickLabelMinor       : TLabel;
    FQuickStatus           : TStatusBar;

    FSilentExceptions      : Boolean;
    FProxyBypassList       : TStrings;
    FEnableCache           : Boolean;

    procedure SetResolveNames(NewResolveNames: TResolveNames);
    procedure SetProxyBypassList(const Value: TStrings);
    procedure SetEnableCache(const Value: boolean);
  protected
    { Protected declarations }
    FAPI_CacheFlag   : DWORD;
    FhInet           : HINTERNET;

    FHostName,
    FUserName,
    FPassword        : string;

    FProxyName       : string;

    FAPI_ConnectFlags: DWORD;

    procedure DoQuickProgress; virtual; abstract;
    function  DoStateChange(NewState: TWinInetState): boolean;

    function  GetConnectTimeOut: DWORD;
    procedure SetConnectRetries(Value: DWORD);
    procedure SetConnectTimeout(const Value: DWORD);
    function  GetConnectRetries: DWORD;
    function  GetLastErrorString: string;
    procedure HandleConnectError(Err: DWORD); virtual;

    procedure HandleStatusCallback(
      dwInternetStatus:           DWORD;
      lpvStatusInfo:              Pointer;
      dwStatusInformationLength:  DWORD
    ); virtual;

    procedure RegisterStatusCallback;
    procedure SafeCloseHandle(var Handle: HINTERNET);

    property OnDisconnected: TNotifyEvent
      read FOnDisconnected write FOnDisconnected;

    property QuickLabelMajor: TLabel
      read FQuickLabelMajor write FQuickLabelMajor;

    property QuickLabelMinor: TLabel
      read FQuickLabelMinor write FQuickLabelMinor;

    property QuickProgressMajor: TProgressBar
      read FQuickProgressMajor write FQuickProgressMajor;
  public
    { Public declarations }
    fUserAgent:String;

    constructor Create(AOwner: TComponent); override;
    destructor  Destroy; override;

    property hInet: HINTERNET read FhInet;
    property LastError: string read GetLastErrorString;

    property State: TWinInetState read FState;
    function TranslateStateText(aState: TWinInetState): string;

    procedure Abort;

    function Connect:    Boolean; virtual;
    function Disconnect: Boolean; virtual;
  published
    { Published declarations }
    property ConnectRetries: DWORD
      read GetConnectRetries write SetConnectRetries;

    property EnableCache: boolean read FEnableCache write SetEnableCache;

    property HostName: string read FHostName write FHostName;
    property UserName: string read FUserName write FUserName;
    property Password: string read FPassword write FPassword;
    property Port: integer read FPort write FPort;

    property ProxyName: string read FProxyName write FProxyName;
    property ProxyBypassList: TStrings
      read FProxyBypassList write SetProxyBypassList;

    property QuickProgress: Boolean read FQuickProgress write FQuickProgress;

    property QuickProgressMinor: TProgressBar
      read FQuickProgressMinor write FQuickProgressMinor;

    property QuickStatus: TStatusBar read FQuickStatus write FQuickStatus;

    property ConnectTimeout: DWORD
      read GetConnectTimeOut write SetConnectTimeout;

    property ResolveNames: TResolveNames
      read FResolveNames write SetResolveNames default rnLocal;

    property SilentExceptions: boolean
      read FSilentExceptions write FSilentExceptions;

    property RequestFlags:Dword read FAPI_CacheFlag write FAPI_CacheFlag; //Omar: Para manipular flags...

    {
      Events
    }
    property OnConnected: TNotifyEvent read FOnConnected write FOnConnected;

    property OnStateChange: TStateChangeEvent read FOnStateChange write FOnStateChange;

  end;

procedure RegisteredStatusCallback(
    hInet:                      HINTERNET;
    dwContext:                  DWORD;
    dwInternetStatus:           DWORD;
    lpvStatusInfo:              Pointer;
    dwStatusInformationLength:  DWORD
  ); stdcall;

implementation

procedure TWinInetControl.SafeCloseHandle(var Handle: HINTERNET);
begin
  if not(assigned(Handle)) then
    exit;

  try
    InternetCloseHandle(Handle);
  finally
    Handle := nil;
  end;
end;

constructor TWinInetControl.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FProxyBypassList  := TStringlist.Create;

  FState            := fsNoConnection;
  FConnectTimeOut   := C_DEFAULT_TIMEOUT;
  FConnectRetries   := C_DEFAULT_RETRIES;
  ResolveNames      := rnLocal;
  FSilentExceptions := True;
  FAPI_ConnectFlags := 0;
  FAPI_CacheFlag    := INTERNET_FLAG_RELOAD;
  fUserAgent:=Application.Title; //Omar:
end;


destructor TWinInetControl.Destroy;
begin
  Disconnect;
  FProxyBypassList.Free;
  inherited Destroy;
end;


function TWinInetControl.Connect: Boolean;
begin
  if FState = fsConnected then begin
    result := true;
    exit;
  end;

  result := false;

  if not assigned(FhInet) then
    if FResolveNames <> rnProxy then
      FhInet := InternetOpen (
        Pchar(fUserAgent), //Omar: era Application.Title),
        FAPI_ResolveNames,
        nil,
        PChar(FProxyBypassList.Text),
        0
      )
    else
      FhInet := InternetOpen (
        Pchar(fUserAgent), //Omar: era Application.Title),
        FAPI_ResolveNames,
        PChar(FProxyName),
        PChar(FProxyBypassList.Text),
        0
      );

  RegisterStatusCallback;

  // Set connection timeout & retries
  SetConnectRetries(FConnectRetries);
  SetConnectTimeOut(FConnectTimeOut);
end;


function TWinInetControl.Disconnect: Boolean;
begin
  SafeCloseHandle(FhInet);

  result := true;

  if not (csDestroying in ComponentState) then
    if DoStateChange(fsNoConnection) then
      if assigned(FOnDisconnected) then
        FOnDisconnected(Self);
end;


function TWinInetControl.DoStateChange(NewState: TWinInetState): boolean;
begin
  {
    Deal with a state change in terms of updating status bars, calling
    events (if it's a real state change)
  }
  If NewState = FState then begin
    result := false;
    exit;
  end;

  FState := NewState;
  result := True;

  If assigned(FOnStateChange) then
    FOnStateChange(Self, FState);

  If FQuickProgress and assigned(FQuickStatus) then begin
    If FQuickStatus.SimplePanel then
      FQuickStatus.SimpleText := TranslateStateText(NewState)
    else
      FQuickStatus.Panels[0].Text := TranslateStateText(NewState);
  end;
end;


function TWinInetControl.GetConnectTimeOut: DWORD;
var
  bOpOk     : BOOL;
  iBufLength: DWORD;
begin
  If not assigned(FhInet) then begin
    result := FConnectTimeOut;
    exit;
  end;

  bOpOk := InternetQueryOption(
    FhInet, INTERNET_OPTION_CONNECT_TIMEOUT, @Result, iBufLength
  );

  if not bOpOk then
    result := C_DEFAULT_TIMEOUT;
end;


function TWinInetControl.GetLastErrorString: string;
{
  Returns last error string, strangely enough.
}
var
  nLastError,
  nBufLength:   DWORD;
  pLastError:   PChar;
begin
  nBufLength := INTERNET_MAX_PATH_LENGTH;
  pLastError := StrAlloc(INTERNET_MAX_PATH_LENGTH);
  try
    If not(InternetGetLastResponseInfo(nLastError, pLastError, nBufLength))
    or (StrLen(pLastError) = 0) then
      result := S_ERROR_NO_ERROR_STRING
    else
      result := StrPas(pLastError);
  finally
    StrDispose(pLastError);
  end;
end;


procedure TWinInetControl.HandleConnectError(Err: DWORD);
begin
  {
    ***TODO: Bring back all connection errors that can be handled by base class
  }
  DoStateChange(fsNoConnection);

  if FSilentExceptions then
    exit;

  Case Err of
    ERROR_INTERNET_INCORRECT_USER_NAME:
      raise EWinInetError.CreateFmt(
        S_ERROR_INTERNET_INCORRECT_USER_NAME, [FUserName, FHostName]
      );

    ERROR_INTERNET_CANNOT_CONNECT:
      raise EWinInetError.CreateFmt(
        S_ERROR_INTERNET_CANNOT_CONNECT, [FHostName]
      );

    ERROR_INTERNET_LOGIN_FAILURE:
      raise EWinInetError.CreateFmt(
        S_ERROR_INTERNET_CANNOT_CONNECT, [FHostName]
      );

    ERROR_INTERNET_NAME_NOT_RESOLVED:
      raise EWinInetError.CreateFmt(
        S_ERROR_INTERNET_NAME_NOT_RESOLVED, [FHostName]
      );

    ERROR_INTERNET_INTERNAL_ERROR:
      raise EWinInetError.Create(
        S_ERROR_INTERNET_INTERNAL_ERROR
      );

    ERROR_INTERNET_TIMEOUT:
      raise EWinInetError.CreateFmt(
        S_ERROR_INTERNET_TIMEOUT, [FHostName]
      );

  else
    raise EWinInetError.CreateFmt(
      S_ERROR_INTERNET_GENERAL_ERROR, [FHostName]
    );
  end;
end;



procedure TWinInetControl.SetConnectTimeout(const Value: DWORD);
// See caveat - Microsoft bug, this is ignored < IE5
begin
  FConnectTimeOut := Value;

  if FConnectTimeOut = 0 then
    FConnectTimeOut := C_DEFAULT_TIMEOUT;

  if assigned(FhInet) then
    InternetSetOption(
      FhInet,
      INTERNET_OPTION_CONNECT_TIMEOUT ,
      @FConnectTimeOut,
      sizeof(DWORD)
    );
end;


function TWinInetControl.TranslateStateText(aState: TWinInetState): string;
// Give a meaningful string state descriptor from a state variable
begin
  case FState of
    fsNoconnection:  result := S_STATE_NOCONNECTION;
    fsDisconnecting: result := Format(S_STATE_DISCONNECTING,  [FHostName]);
    fsConnecting:    result := Format(S_STATE_CONNECTING,     [FHostName]);
    fsConnected:     result := Format(S_STATE_CONNECTED,      [FHostName]);
    fsResolvingName: result := Format(S_STATE_RESOLVING_NAME, [FHostName]);
    fsNameResolved:  result := Format(S_STATE_NAME_RESOLVED,  [FHostName]);
  else
    result := S_STATE_UNKNOWN;
  end;
end;


procedure TWinInetControl.SetResolveNames(NewResolveNames: TResolveNames);
{
  Translator of Delphi ordinal types for name resolution to
  WinInet API types.
}
begin
  FResolveNames := NewResolveNames;
  Case NewResolveNames of
    rnLocal:
      FAPI_ResolveNames := INTERNET_OPEN_TYPE_DIRECT;
    rnPreConfig:
      FAPI_ResolveNames := INTERNET_OPEN_TYPE_PRECONFIG;
    rnProxy:
      FAPI_ResolveNames := INTERNET_OPEN_TYPE_PROXY;
  end;
end;


procedure TWinInetControl.SetConnectRetries(Value: DWORD);
begin
  FConnectRetries := Value;

  if assigned(FhInet) then
    InternetSetOption(
    FhInet,
    INTERNET_OPTION_CONNECT_RETRIES,
    @FConnectRetries,
    sizeof(DWORD)
  );
end;


function TWinInetControl.GetConnectRetries: DWORD;
var
  bOpOk     : BOOL;
  iBufLength: DWORD;
begin
  If not assigned(FhInet) then begin
    result := FConnectRetries;
    exit;
  end;

  bOpOk := InternetQueryOption(
    FhInet, INTERNET_OPTION_CONNECT_RETRIES, @Result, iBufLength
  );

  if not bOpOk then
    result := C_DEFAULT_RETRIES;
end;


procedure TWinInetControl.HandleStatusCallback(dwInternetStatus: DWORD;
  lpvStatusInfo: Pointer; dwStatusInformationLength: DWORD);
begin
  Case dwInternetStatus of

    INTERNET_STATUS_RESOLVING_NAME:
      DoStateChange(fsResolvingName);

    INTERNET_STATUS_NAME_RESOLVED:
      DoStateChange(fsNameResolved);

    INTERNET_STATUS_CONNECTING_TO_SERVER:
      DoStateChange(fsConnecting);

    INTERNET_STATUS_CONNECTED_TO_SERVER:
      DoStateChange(fsConnected);

    INTERNET_STATUS_CLOSING_CONNECTION:
      DoStateChange(fsDisconnecting);

    INTERNET_STATUS_CONNECTION_CLOSED:
      DoStateChange(fsNoConnection);
  {$ifdef DEBUG}
  else
    OutputDebugString(PChar('Unhandled status ' + IntToStr(dwInternetStatus)));
  {$endif}
  end; {case}
end;



procedure RegisteredStatusCallback(
  hInet:                      HINTERNET;
  dwContext:                  DWORD;
  dwInternetStatus:           DWORD;
  lpvStatusInfo:              Pointer;
  dwStatusInformationLength:  DWORD
); stdcall;
{
  This is the non-class callback registered with SetInternetStatusCallback.
  The dwContext variable holds a pointer to the instance of the TSimpleFTP
  component that registered it, so we just delegate it to the protected
  method 'HandleStatusCallback' - which is callable from here via Delphi's
  odd 'friend function if you're in the same unit' feature.
}
var
  InetInstance: TWinInetControl;
begin
  InetInstance := TWinInetControl(dwContext);
  InetInstance.HandleStatusCallback(
    dwInternetStatus,
    lpvStatusInfo,
    dwStatusInformationLength
  );
end;


procedure TWinInetControl.RegisterStatusCallback;
begin
  {
    Register callback function so we can get some information on
    functions in progress and/or be notified of state changes.
  }
  InternetSetStatusCallback(
    FhInet,
    @RegisteredStatusCallback
  );
end;

procedure TWinInetControl.SetProxyBypassList(const Value: TStrings);
begin
  FProxyBypassList.Assign(Value);
end;

{ TInetAbortThread }

constructor TInetAbortThread.Create(AOwner: TWinInetControl);
begin
  inherited Create(True);
  FOwner := AOwner;
end;


procedure TInetAbortThread.Execute;
begin
  Owner.Disconnect;
end;


procedure TWinInetControl.Abort;
var
  AbortThread: TInetAbortThread;
begin
  AbortThread := TInetAbortThread.Create(Self);
  AbortThread.Resume;
  try
    while assigned(FhInet) do
      ;
  finally
    AbortThread.Free;
  end;
end;


procedure TWinInetControl.SetEnableCache(const Value: boolean);
begin
  FEnableCache := Value;

  If FEnableCache then
    FAPI_CacheFlag := FAPI_CacheFlag and (not INTERNET_FLAG_RELOAD)
  else
    FAPI_CacheFlag := FAPI_CacheFlag or INTERNET_FLAG_RELOAD;
end;

end.
