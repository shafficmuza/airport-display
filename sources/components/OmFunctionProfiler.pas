Unit OmFunctionProfiler;   { Profiler para cronometragem de funcoes }
interface

//modo de usar:
//  Profiler_Start;
//  Profiler_Profile(0);
//  SlowProcedure1;
//  Profiler_Profile(1);
//  SlowProcedure2;
//  Profiler_Profile(2);
//  SlowProcedure3;
//  Profiler_Profile(3);   //isso cronometra o tempo de acesso a SlowProcedure3
//  Profiler_End;          //isso grava o relatorio em OmProfiler.txt

uses
  Classes, Forms,Windows,SysUtils,
  Debug;

const
  MAXPROFILERS=100;

Type
  TProfilerRec=class
  private
    fNSamples:integer;
    fTotalTime:TDateTime;
  public
    Constructor Create;
    Procedure   AddProfileTime(D:TDateTime);
    function    AverageTimeMS:Real;
  end;

  TProfilerList=array[0..MAXPROFILERS-1] of TProfilerRec; //um array, para acesso rapido

  TOmFunctionProfiler=class
  private
    fLastTime:TDateTime;
    fProfilers:TProfilerList;
  public
    fProfilerAtivo:boolean;
    Constructor Create;
    Destructor  Destroy; override;
    Procedure   ClearProfilerRecs;
    Procedure   DoProfile(aID:integer);
    Procedure   Report;
  end;

var
  TheProfiler:TOmFunctionProfiler=nil;

Procedure Profiler_Start;
Procedure Profiler_Profile(aID:integer);  //o profiler aID retorna o tempo entre essa chamada e a anterior (i.e. a fn que está em cima)
Procedure Profiler_End;

implementation

Procedure Profiler_Start;
begin
  TheProfiler:=TOmFunctionProfiler.Create;
end;

Procedure Profiler_Profile(aID:integer);
begin
  TheProfiler.DoProfile(aID);
end;

Procedure Profiler_End;
begin
  TheProfiler.Report;
  TheProfiler.Free;
end;

{ TProfilerRec }

constructor TProfilerRec.Create;
begin
  inherited;
  fNSamples:=0;
  fTotalTime:=0;
end;

procedure TProfilerRec.AddProfileTime(D: TDateTime);
begin
  inc(fNSamples);
  fTotalTime:=fTotalTime+D;
end;

function TProfilerRec.AverageTimeMS: Real;
begin
  if fNSamples>0 then
    begin
      Result:=(fTotalTime/fNSamples)*24*3600*1000; //em ms
    end
    else Result:=0;
end;

{ TOmFunctionProfiler }

constructor TOmFunctionProfiler.Create;
begin
  inherited;
  fLastTime:=0;
  FillChar(fProfilers,SizeOf(fProfilers),#0);
  fProfilerAtivo:=TRUE;
end;

destructor TOmFunctionProfiler.Destroy;
begin
  ClearProfilerRecs;
  inherited;
end;

procedure TOmFunctionProfiler.ClearProfilerRecs;
var i:integer;
begin
  for i:=0 to MAXPROFILERS-1 do fProfilers[i].Free; //desaloca profilers anteriores
  FillChar(fProfilers,SizeOf(fProfilers),#0);
end;

procedure TOmFunctionProfiler.DoProfile(aID:integer);
var aPR:TProfilerRec; D,N:TDateTime;
begin
  if not fProfilerAtivo then exit;
  if (aID>=MAXPROFILERS) then
    Raise Exception.Create('max de 100 profilers');
  aPR:=fProfilers[aID];          //pega profiler
  if not Assigned(aPR) then
    begin
      fProfilers[aID]:=TProfilerRec.Create;
      aPR:=fProfilers[aID];
    end;
  N:=Now;
  if (fLastTime=0) then fLastTime:=N;
  D:=N-fLastTime;         //tempo decorrido desde a ultima chamada
  aPR.AddProfileTime(D);
  fLastTime:=N;
end;

procedure TOmFunctionProfiler.Report;
var S:String; aPR:TProfilerRec; i:integer; SL:TStringList; Tot,Avg:TDateTime;
begin
  SL:=TStringList.Create;
  try
    Tot:=0;
    for i:=0 to MAXPROFILERS-1 do
      begin
        aPR:=fProfilers[i];
        if Assigned(aPR) then
          begin
            Avg:=aPR.AverageTimeMS;
            Tot:=Tot+Avg;
            S:=IntToStr(i)+':'+Format('%8.3f',[Avg])+' ms - samples:'+IntToSTr(aPR.fNSamples);
            SL.Add(S);
          end;
      end;
    S:='Total:'+Format('%8.3f',[Tot])+' ms';
    SL.Add(S);
    SL.SaveToFile('OmProfile.txt');
  finally
    SL.Free;
  end;
end;

end.

