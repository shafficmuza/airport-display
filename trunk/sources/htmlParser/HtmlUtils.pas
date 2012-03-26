Unit HtmlUtils; {miscelaneous objects and procedures, for use with HtmlParser}
interface
uses
  Classes, SysUtils,
  HtmlParser;

const
  MAXROWS=200;    //tamanho maximo da tabela (dá exception se passar)
  MAXCOLS=50;

type
  TTableNodeParser=class
  private
    fCells: Array[0..MAXCOLS-1,0..MAXROWS-1] of String;
    fColCount:integer;
    fRowCount:integer;

    function  GetCells(ACol, ARow: Integer): string;
    function  GetColumnName(ACol: Integer): string;
    procedure SetCells(ACol, ARow: Integer; const Value: string);
    procedure WriteColumnName(ACol: Integer; const Value: string);
    procedure CheckMaxs(ACol, ARow: Integer);
    procedure ClearCells;
    function  GetCellByColname(const aColName: String; ARow: Integer): String;
  public
    Constructor Create;
    Destructor  Destroy; override;
    Procedure   ParseNode(aTableNode:TTagNode);
    procedure   ParseNode2(aTableNode: TTagNode);

    property    Cells[ACol, ARow: Integer]: string read GetCells write SetCells;
    property    ColumnName[ACol:Integer]: string   read GetColumnName write WriteColumnName;
    property    RowCount:integer read fRowCount;
    property    ColCount:integer read fColCount;

    Property    CellByColname[const aColName:String; ARow: Integer]:String read GetCellByColname;
  end;

  function FirstTagThatContains(aRootNode:TTagNode; const TagName, aText:String): TTagNode;

implementation

function FirstTagThatContains(aRootNode:TTagNode; const TagName, aText:String): TTagNode;
var i:integer; aNode:TTagNode; sPCDATA,sParams:String; sText:String; aNodes:TTagNodeList;
begin
  Result:=nil;
  aNodes:=TTagNodeList.Create;
  try
    aRootNode.GetTags(TagName,aNodes);
    sText:=Lowercase(aText);
    for i:=0 to aNodes.Count-1 do
      begin
        aNode := aNodes[i];
        If Assigned(aNode) then
          begin
            sPCData:=Lowercase(aNode.GetPCData);    //isso é demorado! Melhorar a eficiencia aqui...
            //Talvez separa busca no texto e nos parametros em duas funcoes diferentes
            sParams:=Lowercase(aNode.Params.Text);
            if (Pos(sText,sPCDATA)>0) or (Pos(sText,sParams)>0) then //procura no text e nos parametros..
              begin
                Result:=aNode;
                break;
              end;
          end;
      end;
  finally
    aNodes.Free;
  end;
end;

{ TTableNodeParser }

constructor TTableNodeParser.Create;
begin
  inherited;
  fRowCount:=0;
  fColCount:=0;
end;

destructor TTableNodeParser.Destroy;
begin
  inherited;
end;

Procedure TTableNodeParser.ClearCells;
var r,c:integer;
begin
  for r:=0 to MAXROWS-1 do for C:=0 to MAXCOLS-1 do
    fCells[C,R]:='';
end;

procedure TTableNodeParser.CheckMaxs(ACol, ARow: Integer); //pára se pssando os limites maximos
begin
  if (ACol<0) or (aCol>=MAXCOLS) or
     (ARow<0) or (aRow>=MAXROWS) then
       Raise Exception.Create('table too big');
end;

procedure TTableNodeParser.ParseNode(aTableNode: TTagNode);
var aNode,aTR,aTD:TTagNode; aRow,aCol,i,j:integer;  aNL:TTagNodeList; S:String;
begin
  fRowCount:=0;
  fColCount:=0;
  aRow:=0;
  for i:=0 to aTableNode.ChildCount-1 do
    begin
      aNode:=aTableNode[i];
      if (CompareText(aNode.Caption,'TR')=0)  then //..é um <TR>
        begin
          aTR:=aNode;
          aNL:=TTagNodeList.Create;
          aTR.GetTags('td',aNL);                        //pega os TDs dentro do TR
          if (aNL.Count=0) then aTR.GetTags('th',aNL);  //Se nao tem <td>s, pode ter <th>s...
          aCol:=0;
          for j:=0 to aNL.Count-1 do
            begin
              aTD:=aNL.Items[j];
              S:=aTD.GetPCData;
              S:=StringReplace(S,'&nbsp;','',[rfReplaceAll,rfIgnoreCase]);
              Cells[aCol,aRow]:=S;          //saca valor
              inc(aCol);
            end;
          aNL.Free;
          inc(aRow);
        end;
    end;
end;

procedure TTableNodeParser.ParseNode2(aTableNode: TTagNode);
var aNode,aTR,aTD:TTagNode; aRow,aCol,i,j:integer;  aNL,aTRL:TTagNodeList; S:String;
begin
  fRowCount:=0;
  fColCount:=0;
  aRow:=0;
  aTRL:=TTagNodeList.Create;
  aTableNode.GetTags('tr',aTRL);
  for i:=0 to aTRL.Count-1 do
    begin
      aTR:=aTRL.Items[i];
      aNL:=TTagNodeList.Create;
      aTR.GetTags('td',aNL);                        //pega os TDs dentro do TR
      aCol:=0;
      if aNL.Count<=5 then     //gambiarra
      for j:=0 to aNL.Count-1 do
        begin
          aTD:=aNL.Items[j];
          S:=aTD.GetPCData;
          S:=StringReplace(S,'&nbsp;','',[rfReplaceAll,rfIgnoreCase]);
          Cells[aCol,aRow]:=S;          //saca valor
          inc(aCol);
        end;
      aNL.Free;
      inc(aRow);
    end;
  aTRL.Free;
end;

function TTableNodeParser.GetCells(ACol, ARow: Integer): string;
begin
  CheckMaxs(ACol, ARow);
  Result:=fCells[aCol,aRow];
end;

function TTableNodeParser.GetColumnName(ACol: Integer): string;
var C:integer;
begin
  C:=aCol+1; if (C>fColCount) then fColCount:=C; //ajusta contagens
  CheckMaxs(ACol, 0);
  Result:=fCells[ACol,0];
end;

procedure TTableNodeParser.SetCells(ACol, ARow: Integer;  const Value: string);
var C,R:integer;
begin
  CheckMaxs(ACol, ARow);
  C:=aCol+1; if (C>fColCount) then fColCount:=C; //ajusta contagens
  R:=aRow+1; if (R>fRowCount) then fRowCount:=R;
  fCells[ACol, ARow]:=Trim(Value);
end;

procedure TTableNodeParser.WriteColumnName(ACol: Integer; const Value: string);
begin
  CheckMaxs(ACol, 0);
end;

function TTableNodeParser.GetCellByColname(const aColName: String; ARow: Integer): String;
var ic:integer;
begin
  Result:='';
  CheckMaxs(0,aRow);
  for ic:=0 to fColCount-1 do
    if CompareText(aColName,fCells[ic,0])=0 then //procura a coluna com header aColName
      begin
        Result:=fCells[ic,aRow];   //achou, retorna celula selecionada
        exit;
      end;
end;

end.
