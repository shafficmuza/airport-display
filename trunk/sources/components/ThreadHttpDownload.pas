unit ThreadHttpDownload; { Thread de download http usando WinInet }
// (c)copr 1999-2008 Omar Reis - all rights reserved

interface

uses
  Classes,
  SimpHttp,WinInetControl,SysUtils;

type
  TDownloadProgressEvent=Procedure(Sender:TObject; Progress:integer) of object;
  TDownloadMessageEvent =Procedure(Sender:TObject; const Msg:String) of object;

  TThreadHttpDownloadComWinInet = class(TThread)
  private
    fHttp:TSimpleHTTP;
    fURI:String;
    fAuthString:String;
    fHttpStatus:integer;
    fHostName: String;
    fPort:integer;
    fOnMessage: TDownloadMessageEvent;
    fOnProgress: TDownloadProgressEvent;

    fPercent:integer;
    fMessageText:String;
    fStream: TMemoryStream;
    //Eventos chamados gerados pelo TSimpleHTTP
    procedure DownloadConnected(Sender: TObject);
    procedure DownloadTransferProgress(Sender: TObject; ProgressInfo: THTTPProgressInfo);
    //Chamador de eventos no VCL thread (sincronizados)
    procedure DoMessage;
    procedure DoProgress;
    function  GetAuthHeader: String;
  protected
    procedure Execute; override;
  public
    Constructor Create;
    Destructor  Destroy; override;

    Procedure CancelaDownload;

    Property HttpStatus:integer   read fHttpStatus;
    Property Stream:TMemoryStream read fStream;

    Property URI:String           read fURI          write fURI;
    Property HostName:String      read fHostName     write fHostName;
    Property HostPort:integer     read fPort         write fPort;
    Property AuthString:String    read fAuthString   write fAuthString; //Tipo 'omar:xpto'
    Property MessageText:String   read fMessageText  write fMessageText;

    Property OnProgress:TDownloadProgressEvent read fOnProgress write fOnProgress;
    Property OnMessage:TDownloadMessageEvent   read fOnMessage  write fOnMessage;
  end;

implementation

uses
  Base64;

const
  CRLF=#13#10;

{ Important: Methods and properties of objects in VCL can only be used in a
  method called using Synchronize, for example,

      Synchronize(UpdateCaption);

  and UpdateCaption could look like,

    procedure TThreadHttpDownloadComWinInet.UpdateCaption;
    begin
      Form1.Caption := 'Updated in a thread';
    end; }

{ TThreadHttpDownloadComWinInet }

constructor TThreadHttpDownloadComWinInet.Create;
begin
  inherited Create({suspended=} TRUE);   //Só dá resume aós setar campos
  fURI:='';
  fAuthString:='';
  fHttpStatus:=0; //0=invalido
  fHostName:='';
  fHttp:=TSimpleHTTP.Create(nil);
  fOnMessage:=nil;
  fOnProgress:=nil;
  fPercent:=0;
  fMessageText:='';
  fStream:=nil;
  fPort:=80; //default

  FreeOnTerminate:=TRUE;
end;

destructor TThreadHttpDownloadComWinInet.Destroy;
begin
  fHttp.Free;
  fStream.Free;
  inherited;
end;

procedure TThreadHttpDownloadComWinInet.DoProgress;
begin
  if Assigned(fOnProgress) then fOnProgress(Self,fPercent);
end;

procedure TThreadHttpDownloadComWinInet.DownloadTransferProgress(Sender: TObject; ProgressInfo: THTTPProgressInfo);
begin
  if Assigned(fOnProgress) then with ProgressInfo do
    begin
      if (MinorMax<>0) then fPercent:=Trunc(Minor/MinorMax*100) else fPercent:=0;
      Synchronize(DoProgress);
    end;
end;

procedure TThreadHttpDownloadComWinInet.DoMessage;
begin
  if Assigned(fOnMessage) then fOnMessage(Self,fMessageText);
end;

procedure TThreadHttpDownloadComWinInet.DownloadConnected(Sender: TObject);
begin
  if Assigned(fOnMessage) then
    begin
      fMessageText:='Conectado';
      Synchronize(DoMessage);
    end;
end;

function TThreadHttpDownloadComWinInet.GetAuthHeader:String;
begin
  Result:='';
  if fAuthString<>'' then
    Result:='Authorization: Basic '+Base64Encode(fAuthString)+CRLF;
  //TODO: proxy authentication
end;

procedure TThreadHttpDownloadComWinInet.Execute;
var st:TFileStream; e:Exception;
begin
  with fHttp do
    begin
      ConnectRetries := 3;
      EnableCache:=False;
      QuickProgress:= False;
      ConnectTimeout:= 10000;
      SilentExceptions:=True;
      BlockSize:= 8192;
      EnableSSL := false;
      UseSSL := false;
      ResolveNames:= rnPreConfig;
      HostName:=fHostName;
      Port:=fPort;
      OnConnected:=DownloadConnected;
      OnTransferProgress:=DownloadTransferProgress;
    end;
  fStream:=TMemoryStream.Create;
  try
    fHttp.OptionalHeaders.Text:=GetAuthHeader;
    fHttp.Get(fURI,fStream);
    fHttpStatus:=fHttp.HTTPHeaderInfo.StatusCode;
  except
    fStream.Free;
    fStream:=nil;
    e:=Exception(ExceptObject);
    fMessageText:=e.Message;
    fHttpStatus:=-1;
  end;
  fMessageText:=''; //sinaliza que ok
end;

procedure TThreadHttpDownloadComWinInet.CancelaDownload;
begin
  if Assigned(fHttp) then fHttp.Disconnect;
end;

end.

