unit OmHttpSrvCache;  //cache de HttpSrv2.pas (componente servidor http)
// thread unico e sincronizado (no job should hang me)
// projeto: HttpSrv component (versão 2) ©Copr 97-08 Omar Reis
//          main component file: HttpSrv2.pas
// Historico:
//     Om: mai08: inicio com objectos THttpSrvCacheFile e THttpSrvCache
//     Om: mar11: Correção na data retornada de arquivos recem abertos

interface
uses
  WinTypes,WinProcs,Classes,SysUtils;

const
  MAX_HTTP_CACHE_FILE_SIZE=1000000; //1 mb tops

type
  // the http srv cache file rec
  TOmHttpSrvCache_File=class
  private
    fFileName:String;
    fStream:TMemoryStream;
  public
    fFileDate:TDatetime;
    fFileSize:integer;
    fContentType:String;

    fHits:integer; //usage log
    // TODO: detailed usage log
    // TODO: authentication
    Constructor Create(const aFileName:String);
    Destructor  Destroy; override;
  end;

  TOmHttpSrvCache=class(TStringList)
  private
  public
    Constructor Create;
    Destructor  Destroy; override;
    procedure   ClearCache;
    function    Get_Add_File( const aFileName:string; aDiskFileDateTime:TDatetime; var aDateTime:TDatetime; var aContentType:String):TMemoryStream; //get a file stream (add if new)
    function    GetCacheMemorySize:int64;
  end;

// http srv utility funcs  
Function OmFileDatetime(const aFN:String):TDatetime;
Function File2ContentType(const aFileNm:String):String; // 'myfile.xml' --> 'text/xml'

implementation

// conversor de tipos mime
// aFileNm deve ser sempre em lowercase

Type
  PRecMimeExtensionDB=^TRecMimeExtensionDB;
  TRecMimeExtensionDB=record
    extension :String[10];     //p.e. 'xml'
    mimeType  :String[30];     //p.e. 'text/xml'
  end;

const
  NUM_MIME_DB=155; //tabela de tipos mime
  MimeExtensionRecs:Array[1..NUM_MIME_DB] of TRecMimeExtensionDB=(
    //          123456789                         123456789012345678901234567890
    ( extension:     '.ai';           mimeType  :'application/postscript'       ),
    ( extension:    '.aif';           mimeType  :'audio/x-aiff'                 ),
    ( extension:   '.aifc';           mimeType  :'audio/x-aiff'                 ),
    ( extension:   '.aiff';           mimeType  :'audio/x-aiff'                 ),
    ( extension:    '.asc';           mimeType  :'text/plain'                   ),
    ( extension:     '.au';           mimeType  :'audio/basic'                  ),
    ( extension:    '.avi';           mimeType  :'video/x-msvideo'              ),
    ( extension:  '.bcpio';           mimeType  :'application/x-bcpio'          ),
    ( extension:    '.bin';           mimeType  :'application/octet-stream'     ),
    ( extension:      '.c';           mimeType  :'text/plain'                   ),
    ( extension:     '.cc';           mimeType  :'text/plain'                   ),
    ( extension:   '.ccad';           mimeType  :'application/clariscad'        ),
    ( extension:    '.cdf';           mimeType  :'application/x-netcdf'         ),
    ( extension:  '.class';           mimeType  :'application/octet-stream'     ),
    ( extension:   '.cpio';           mimeType  :'application/x-cpio'           ),
    ( extension:    '.cpt';           mimeType  :'application/mac-compactpro'   ),
    ( extension:    '.csh';           mimeType  :'application/x-csh'            ),
    ( extension:    '.css';           mimeType  :'text/css'                     ),
    ( extension:    '.dcr';           mimeType  :'application/x-director'       ),
    ( extension:    '.dir';           mimeType  :'application/x-director'       ),
    ( extension:    '.dms';           mimeType  :'application/octet-stream'     ),
    ( extension:    '.doc';           mimeType  :'application/msword'           ),
    ( extension:    '.drw';           mimeType  :'application/drafting'         ),
    ( extension:    '.dvi';           mimeType  :'application/x-dvi'            ),
    ( extension:    '.dwg';           mimeType  :'application/acad'             ),
    ( extension:    '.dxf';           mimeType  :'application/dxf'              ),
    ( extension:    '.dxr';           mimeType  :'application/x-director'       ),
    ( extension:    '.eps';           mimeType  :'application/postscript'       ),
    ( extension:    '.etx';           mimeType  :'text/x-setext'                ),
    ( extension:    '.exe';           mimeType  :'application/octet-stream'     ),
    ( extension:     '.ez';           mimeType  :'application/andrew-inset'     ),
    ( extension:      '.f';           mimeType  :'text/plain'                   ),
    ( extension:    '.f90';           mimeType  :'text/plain'                   ),
    ( extension:    '.fli';           mimeType  :'video/x-fli'                  ),
    ( extension:    '.gif';           mimeType  :'image/gif'                    ),
    ( extension:   '.gtar';           mimeType  :'application/x-gtar'           ),
    ( extension:     '.gz';           mimeType  :'application/x-gzip'           ),
    ( extension:      '.h';           mimeType  :'text/plain'                   ),
    ( extension:    '.hdf';           mimeType  :'application/x-hdf'            ),
    ( extension:     '.hh';           mimeType  :'text/plain'                   ),
    ( extension:    '.hqx';           mimeType  :'application/mac-binhex40'     ),
    ( extension:    '.htm';           mimeType  :'text/html'                    ),
    ( extension:   '.html';           mimeType  :'text/html'                    ),
    ( extension:    '.ice';           mimeType  :'x-conference/x-cooltalk'      ),
    ( extension:    '.ief';           mimeType  :'image/ief'                    ),
    ( extension:   '.iges';           mimeType  :'model/iges'                   ),
    ( extension:    '.igs';           mimeType  :'model/iges'                   ),
    ( extension:    '.ips';           mimeType  :'application/x-ipscript'       ),
    ( extension:    '.ipx';           mimeType  :'application/x-ipix'           ),
    ( extension:    '.jpe';           mimeType  :'image/jpeg'                   ),
    ( extension:   '.jpeg';           mimeType  :'image/jpeg'                   ),
    ( extension:    '.jpg';           mimeType  :'image/jpeg'                   ),
    ( extension:     '.js';           mimeType  :'application/x-javascript'     ),
    ( extension:    '.kar';           mimeType  :'audio/midi'                   ),
    ( extension:  '.latex';           mimeType  :'application/x-latex'          ),
    ( extension:    '.lha';           mimeType  :'application/octet-stream'     ),
    ( extension:    '.lsp';           mimeType  :'application/x-lisp'           ),
    ( extension:    '.lzh';           mimeType  :'application/octet-stream'     ),
    ( extension:      '.m';           mimeType  :'text/plain'                   ),
    ( extension:    '.man';           mimeType  :'application/x-troff-man'      ),
    ( extension:     '.me';           mimeType  :'application/x-troff-me'       ),
    ( extension:   '.mesh';           mimeType  :'model/mesh'                   ),
    ( extension:    '.mid';           mimeType  :'audio/midi'                   ),
    ( extension:   '.midi';           mimeType  :'audio/midi'                   ),
    ( extension:    '.mif';           mimeType  :'application/vnd.mif'          ),
    ( extension:   '.mime';           mimeType  :'www/mime'                     ),
    ( extension:    '.mov';           mimeType  :'video/quicktime'              ),
    ( extension:  '.movie';           mimeType  :'video/x-sgi-movie'            ),
    ( extension:    '.mp2';           mimeType  :'audio/mpeg'                   ),
    ( extension:    '.mp3';           mimeType  :'audio/mpeg'                   ),
    ( extension:    '.mpe';           mimeType  :'video/mpeg'                   ),
    ( extension:   '.mpeg';           mimeType  :'video/mpeg'                   ),
    ( extension:    '.mpg';           mimeType  :'video/mpeg'                   ),
    ( extension:   '.mpga';           mimeType  :'audio/mpeg'                   ),
    ( extension:     '.ms';           mimeType  :'application/x-troff-ms'       ),
    ( extension:    '.msh';           mimeType  :'model/mesh'                   ),
    ( extension:     '.nc';           mimeType  :'application/x-netcdf'         ),
    ( extension:    '.oda';           mimeType  :'application/oda'              ),
    ( extension:    '.pbm';           mimeType  :'image/x-portable-bitmap'      ),
    ( extension:    '.pdb';           mimeType  :'chemical/x-pdb'               ),
    ( extension:    '.pdf';           mimeType  :'application/pdf'              ),
    ( extension:    '.pgm';           mimeType  :'image/x-portable-graymap'     ),
    ( extension:    '.pgn';           mimeType  :'application/x-chess-pgn'      ),
    ( extension:    '.png';           mimeType  :'image/png'                    ),
    ( extension:    '.pnm';           mimeType  :'image/x-portable-anymap'      ),
    ( extension:    '.pot';           mimeType  :'application/mspowerpoint'     ),
    ( extension:    '.ppm';           mimeType  :'image/x-portable-pixmap'      ),
    ( extension:    '.pps';           mimeType  :'application/mspowerpoint'     ),
    ( extension:    '.ppt';           mimeType  :'application/mspowerpoint'     ),
    ( extension:    '.ppz';           mimeType  :'application/mspowerpoint'     ),
    ( extension:    '.pre';           mimeType  :'application/x-freelance'      ),
    ( extension:    '.prt';           mimeType  :'application/pro_eng'          ),
    ( extension:     '.ps';           mimeType  :'application/postscript'       ),
    ( extension:     '.qt';           mimeType  :'video/quicktime'              ),
    ( extension:     '.ra';           mimeType  :'audio/x-realaudio'            ),
    ( extension:    '.ram';           mimeType  :'audio/x-pn-realaudio'         ),
    ( extension:    '.ras';           mimeType  :'image/cmu-raster'             ),
    ( extension:    '.rgb';           mimeType  :'image/x-rgb'                  ),
    ( extension:     '.rm';           mimeType  :'audio/x-pn-realaudio'         ),
    ( extension:   '.roff';           mimeType  :'application/x-troff'          ),
    ( extension:    '.rtf';           mimeType  :'text/rtf'                     ),
    ( extension:    '.rtx';           mimeType  :'text/richtext'                ),
    ( extension:    '.set';           mimeType  :'application/set'              ),
    ( extension:    '.sgm';           mimeType  :'text/sgml'                    ),
    ( extension:   '.sgml';           mimeType  :'text/sgml'                    ),
    ( extension:     '.sh';           mimeType  :'application/x-sh'             ),
    ( extension:   '.shar';           mimeType  :'application/x-shar'           ),
    ( extension:   '.silo';           mimeType  :'model/mesh'                   ),
    ( extension:    '.sit';           mimeType  :'application/x-stuffit'        ),
    ( extension:    '.skd';           mimeType  :'application/x-koan'           ),
    ( extension:    '.skm';           mimeType  :'application/x-koan'           ),
    ( extension:    '.skp';           mimeType  :'application/x-koan'           ),
    ( extension:    '.skt';           mimeType  :'application/x-koan'           ),
    ( extension:    '.smi';           mimeType  :'application/smil'             ),
    ( extension:   '.smil';           mimeType  :'application/smil'             ),
    ( extension:    '.snd';           mimeType  :'audio/basic'                  ),
    ( extension:    '.sol';           mimeType  :'application/solids'           ),
    ( extension:    '.spl';           mimeType  :'application/x-futuresplash'   ),
    ( extension:    '.src';           mimeType  :'application/x-wais-source'    ),
    ( extension:   '.step';           mimeType  :'application/STEP'             ),
    ( extension:    '.stl';           mimeType  :'application/SLA'              ),
    ( extension:    '.stp';           mimeType  :'application/STEP'             ),
    ( extension:    '.swf';           mimeType  :'application/x-shockwave-flash'),
    ( extension:      '.t';           mimeType  :'application/x-troff'          ),
    ( extension:    '.tar';           mimeType  :'application/x-tar'            ),
    ( extension:    '.tcl';           mimeType  :'application/x-tcl'            ),
    ( extension:    '.tex';           mimeType  :'application/x-tex'            ),
    ( extension:   '.texi';           mimeType  :'application/x-texinfo'        ),
    ( extension:    '.tif';           mimeType  :'image/tiff'                   ),
    ( extension:   '.tiff';           mimeType  :'image/tiff'                   ),
    ( extension:     '.tr';           mimeType  :'application/x-troff'          ),
    ( extension:    '.tsi';           mimeType  :'audio/TSP-audio'              ),
    ( extension:    '.tsp';           mimeType  :'application/dsptype'          ),
    ( extension:    '.tsv';           mimeType  :'text/tab-separated-values'    ),
    ( extension:    '.txt';           mimeType  :'text/plain'                   ),
    ( extension:    '.unv';           mimeType  :'application/i-deas'           ),
    ( extension:  '.ustar';           mimeType  :'application/x-ustar'          ),
    ( extension:    '.vcd';           mimeType  :'application/x-cdlink'         ),
    ( extension:    '.vda';           mimeType  :'application/vda'              ),
    ( extension:    '.viv';           mimeType  :'video/vnd.vivo'               ),
    ( extension:   '.vivo';           mimeType  :'video/vnd.vivo'               ),
    ( extension:   '.vrml';           mimeType  :'model/vrml'                   ),
    ( extension:    '.wav';           mimeType  :'audio/x-wav'                  ),
    ( extension:    '.wrl';           mimeType  :'model/vrml'                   ),
    ( extension:    '.xbm';           mimeType  :'image/x-xbitmap'              ),
    ( extension:    '.xlc';           mimeType  :'application/vnd.ms-excel'     ),
    ( extension:    '.xll';           mimeType  :'application/vnd.ms-excel'     ),
    ( extension:    '.xlm';           mimeType  :'application/vnd.ms-excel'     ),
    ( extension:    '.xls';           mimeType  :'application/vnd.ms-excel'     ),
    ( extension:    '.xlw';           mimeType  :'application/vnd.ms-excel'     ),
    ( extension:    '.xml';           mimeType  :'text/xml'                     ),
    ( extension:    '.xpm';           mimeType  :'image/x-xpixmap'              ),
    ( extension:    '.xwd';           mimeType  :'image/x-xwindowdump'          ),
    ( extension:    '.xyz';           mimeType  :'chemical/x-pdb'               ),
    ( extension:    '.zip';           mimeType  :'application/zip'              ));

var
  MimeExtensionDB:TStringList=nil; //banco de daods de tipos mime do srv

Function File2ContentType(const aFileNm:String):String;
var i,ix:integer;  aext:string; aRec:PRecMimeExtensionDB;
begin
  if not Assigned(MimeExtensionDB) then  //no primeiro acesso cria db
    begin
      MimeExtensionDB:=TStringList.Create;
      MimeExtensionDB.Duplicates :=dupIgnore;
      MimeExtensionDB.Sorted     :=true;
      for i:=1 to NUM_MIME_DB do
        begin
          aRec:=@MimeExtensionRecs[i];
          MimeExtensionDB.AddObject(aRec.extension, TObject(aRec));
        end;
    end;
  //busca binária no bd
  aext:=ExtractFileExt(aFileNm);
  if MimeExtensionDB.Find(aext,ix) then
    begin
      aRec:=PRecMimeExtensionDB(MimeExtensionDB.Objects[ix]);
      Result:=aRec.mimeType;
    end
    else Result:='application/custom';
end;

Function OmFileDatetime(const aFN:String):TDatetime;
var fileDate   : Integer;
begin
  Result:=0; //=invalid
  fileDate := FileAge(aFN);
  if (fileDate > -1) then           // -1 --> file does not exist
    Result:=FileDateToDateTime(fileDate);
end;

{ TOmHttpSrvCache_File }

constructor TOmHttpSrvCache_File.Create(const aFileName: String);
var aFile:TFileStream; S:String;
begin
  inherited Create;
  fFileName:=aFileName;
  fStream:=TMemoryStream.Create;

  aFile:=TFileStream.Create(fFileName,fmOpenRead);
  try
    fFileSize:=aFile.Size;
    fFileDate:=FileDateToDateTime(FileGetDate(aFile.Handle));
    if (fFileSize>MAX_HTTP_CACHE_FILE_SIZE) then
      begin
        fFileSize:=MAX_HTTP_CACHE_FILE_SIZE;  //limit very large files...(truncate to 1MB)
      end;
    SetLength(S,fFileSize);
    aFile.Position:=0;
    aFile.ReadBuffer(S[1],fFileSize);
    fStream.Write(S[1],fFileSize);
    fStream.Position:=0;           //keep stream rewinded at all times
    SetLength(S,0);                //desaloca string
  finally
    aFile.Free;
  end;
  fFileDate    := FileDateToDateTime(FileAge(aFileName));
  fContentType := File2ContentType(aFileName);
end;

destructor TOmHttpSrvCache_File.Destroy;
begin
  fStream.Free;
  fStream:=nil;
  inherited;
end;

{ TOmHttpSrvCache }

constructor TOmHttpSrvCache.Create;
begin
  inherited;
  Duplicates:=dupIgnore;
  Sorted:=true; //keep sorted list for fast lookup using Find()
end;

Procedure TOmHttpSrvCache.ClearCache;
var i:integer;
begin
  for i:=0 to Count-1 do
    TOmHttpSrvCache_File(Objects[i]).Free;
  Clear;
end;

destructor TOmHttpSrvCache.Destroy;
begin
  ClearCache;
  inherited;
end;

// get ou add file to cache... returns nil if file not found (neither in cache or disk)
function TOmHttpSrvCache.Get_Add_File(const aFileName: string; aDiskFileDateTime:TDatetime; var aDateTime:TDateTime; var aContentType:String):TMemoryStream;
var aFile:TOmHttpSrvCache_File; ix:integer;
begin
  Result:=nil;
  if Find(aFileName,ix) then //search cache for file
    begin
      aFile := TOmHttpSrvCache_File(Objects[ix]);    // the stream belongs to the cache. Its readonly (most of the time)
      if (aFile.fFileDate>=aDiskFileDateTime) then   // file did not change
        begin
          Result       := aFile.fStream;     // ok, have the file, but don't mess with it
          aDateTime    := aFile.fFileDate;
          aContentType := aFile.fContentType;
          exit;
        end
        else begin     //cached file was changed since it was cached, dispose entry
          Delete(ix);
          aFile.Free;
        end;
    end;
  if FileExists(aFileName) then
    begin
      aFile := TOmHttpSrvCache_File.Create(aFileName); //load file and save to mem stream ..
      AddObject(aFileName,aFile);                      //add to cache
      Result       := aFile.fStream;
      aDateTime    := aFile.fFileDate;     //mar11: antes retornava data zerada!!
      aContentType := aFile.fContentType;
    end;
end;

function TOmHttpSrvCache.GetCacheMemorySize: int64;
var i:integer; aFile:TOmHttpSrvCache_File;
begin
  Result:=0;
  for i:=0 to Count-1 do
    begin
      aFile:=TOmHttpSrvCache_File(Objects[i]);
      inc(Result,aFile.fFileSize);
    end;
end;

end.
