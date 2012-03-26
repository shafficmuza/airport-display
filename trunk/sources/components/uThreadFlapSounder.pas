unit uThreadFlapSounder; //thread produtor de som, usando o bom e velho mmsystem
// (C)COPR 1997-2007 oMAR rEIS

interface

uses
  Classes,SysUtils,mmSystem, Windows;

type
  TTrupPlayState=(psSilent,psTup,psTrup,psTap); //sons produzidos pelo thread

  TThreadFlapSounder = class(TThread)
  private
    fPlayState:TTrupPlayState;
    procedure SetPlayState(const Value: TTrupPlayState);
  protected
    fTupSound:PChar;
    fTrupSound:PChar;
    fTapSound:PChar;
    
    fTupSize:integer;
    fTrupSize:integer;
    fTapSize:integer;
  public
    Constructor Create;
    Destructor  Destroy;   override;
    procedure   Execute;   override;

    Property    PlayState:TTrupPlayState read fPlayState write SetPlayState;
  end;

implementation

{ Important: Methods and properties of objects in visual components can only be
  used in a method called using Synchronize, for example,

      Synchronize(UpdateCaption);

  and UpdateCaption could look like,

    procedure TThreadFlapSounder.UpdateCaption;
    begin
      Form1.Caption := 'Updated in a thread';
    end; }

{ TThreadFlapSounder }

constructor TThreadFlapSounder.Create;
var aFS:TFileStream; ok:boolean;
begin
  fTupSize:=0;
  fTrupSize:=0;
  fTapSize:=0;
  inherited Create({suspended=} TRUE);   //Só dá resume aós setar campos

  ok:=false;
  try   //ignora erro na inicialização. Simplesmente não starta o thread de som, se não tiver os dois arquivos
      aFS:=TFileStream.Create('tup.wav',fmOpenRead);
      try
        fTupSize:=aFS.Size;
        GetMem(fTupSound,fTupSize);
        aFS.Position:=0;
        aFS.ReadBuffer(fTupSound[0],fTupSize);
        ok:=true;
      finally;
        aFS.Free;
      end;

      if ok then
        begin
          aFS:=TFileStream.Create('trup.wav',fmOpenRead);
          ok:=false;
          try
            fTrupSize:=aFS.Size;
            GetMem(fTrupSound,fTrupSize);
            aFS.Position:=0;
            aFS.ReadBuffer(fTrupSound[0],fTrupSize);
            ok:=true;
          finally;
            aFS.Free;
          end;
        end;

      if ok then
        begin
          aFS:=TFileStream.Create('tap.wav',fmOpenRead);
          ok:=false;
          try
            fTapSize:=aFS.Size;
            GetMem(fTapSound,fTapSize);
            aFS.Position:=0;
            aFS.ReadBuffer(fTapSound[0],fTapSize);
            ok:=true;
          finally;
            aFS.Free;
          end;
        end;
  except
    //TODO: reportar erro de carregamento dos arquivos de som..
  end;

  FreeOnTerminate:=false;  // TESTE: mar08: para ver se deixa de ocorrer erro após finalização...
  //era: true;             //mar08: Om: necessario pra liberar buffers de sons
  fPlayState:=psSilent; //starta em silencio, em sleep de 100 ms

  if ok then Resume;    //so inicia se dois arquivos carregados ok (caso contrário, se cala)
end;

destructor TThreadFlapSounder.Destroy;
begin
  if (fTupSize>0) then FreeMem(fTupSound,fTupSize);
  if (fTrupSize>0) then FreeMem(fTrupSound,fTrupSize);
  if (fTapSize>0) then FreeMem(fTapSound,fTapSize);
  inherited;
end;

procedure TThreadFlapSounder.Execute;
begin
  while not Terminated do
    begin
      case fPlayState of
        psSilent: Sleep(200); //sleep for a while
        psTup:  PlaySound(fTupSound,fTupSize, SND_MEMORY);
        psTrup: PlaySound(fTrupSound,fTrupSize, SND_MEMORY);
        psTap:  PlaySound(fTapSound,fTapSize, SND_MEMORY);
      end;
    end;
end;

procedure TThreadFlapSounder.SetPlayState(const Value: TTrupPlayState);
begin
  fPlayState := Value;
end;

end.
