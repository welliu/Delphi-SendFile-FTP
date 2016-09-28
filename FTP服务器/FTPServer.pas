{*******************************************************}
{                                                       }
{       ϵͳ���� FTP��������                            }
{       ��Ȩ���� (C) http://blog.csdn.net/akof1314      }
{       ��Ԫ���� FTPServer.pas                          }
{       ��Ԫ���� ��Delphi 7��TIdFTPServerʵ��FTP������  }
{                                                       }
{*******************************************************}
unit FTPServer;

interface

uses
  Classes,  Windows,  Sysutils,  IdFTPList,  IdFTPServer,  Idtcpserver,  IdSocketHandle,  Idglobal,  IdHashCRC, IdStack;
{-------------------------------------------------------------------------------
  ����:  �Զ�����Ϣ�������봰�������Ϣ����
-------------------------------------------------------------------------------}
  type
    TFtpNotifyEvent = procedure (ADatetime: TDateTime;AUserIP, AEventMessage: string) of object;
{-------------------------------------------------------------------------------
  ����:  FTP��������
-------------------------------------------------------------------------------}
  type
  TFTPServer = class
  private
    FUserName,FUserPassword,FBorrowDirectory: string;
    FBorrowPort: Integer;
    IdFTPServer: TIdFTPServer;
    FOnFtpNotifyEvent: TFtpNotifyEvent;
    procedure IdFTPServer1UserLogin( ASender: TIdFTPServerThread; const AUsername, APassword: string; var AAuthenticated: Boolean ) ;
    procedure IdFTPServer1ListDirectory( ASender: TIdFTPServerThread; const APath: string; ADirectoryListing: TIdFTPListItems ) ;
    procedure IdFTPServer1RenameFile( ASender: TIdFTPServerThread; const ARenameFromFile, ARenameToFile: string ) ;
    procedure IdFTPServer1RetrieveFile( ASender: TIdFTPServerThread; const AFilename: string; var VStream: TStream ) ;
    procedure IdFTPServer1StoreFile( ASender: TIdFTPServerThread; const AFilename: string; AAppend: Boolean; var VStream: TStream ) ;
    procedure IdFTPServer1RemoveDirectory( ASender: TIdFTPServerThread; var VDirectory: string ) ;
    procedure IdFTPServer1MakeDirectory( ASender: TIdFTPServerThread; var VDirectory: string ) ;
    procedure IdFTPServer1GetFileSize( ASender: TIdFTPServerThread; const AFilename: string; var VFileSize: Int64 ) ;
    procedure IdFTPServer1DeleteFile( ASender: TIdFTPServerThread; const APathname: string ) ;
    procedure IdFTPServer1ChangeDirectory( ASender: TIdFTPServerThread; var VDirectory: string ) ;
    procedure IdFTPServer1CommandXCRC( ASender: TIdCommand ) ;
    procedure IdFTPServer1DisConnect( AThread: TIdPeerThread ) ;
  protected
    function TransLatePath( const APathname, homeDir: string ) : string;
  public
    constructor Create; reintroduce;
    destructor Destroy; override;
    procedure Run;
    procedure Stop;
    function GetBindingIP():string;
    property UserName: string read FUserName write FUserName;
    property UserPassword: string read FUserPassword write FUserPassword;
    property BorrowDirectory: string read FBorrowDirectory write FBorrowDirectory;
    property BorrowPort: Integer read FBorrowPort write FBorrowPort;
    property OnFtpNotifyEvent: TFtpNotifyEvent read FOnFtpNotifyEvent write FOnFtpNotifyEvent;
  end;

implementation

{-------------------------------------------------------------------------------
  ������:    TFTPServer.Create
  ����:      ��������
  ����:      ��
  ����ֵ:    ��
-------------------------------------------------------------------------------}
constructor TFTPServer.Create;
begin
  IdFTPServer := tIdFTPServer.create( nil ) ;
  IdFTPServer.DefaultPort := 21;               //Ĭ�϶˿ں�
  IdFTPServer.AllowAnonymousLogin := False;   //�Ƿ�����������¼
  IdFTPServer.EmulateSystem := ftpsUNIX;
  IdFTPServer.HelpReply.text := '������δʵ�֣�';
  IdFTPServer.OnChangeDirectory := IdFTPServer1ChangeDirectory;
  IdFTPServer.OnGetFileSize := IdFTPServer1GetFileSize;
  IdFTPServer.OnListDirectory := IdFTPServer1ListDirectory;
  IdFTPServer.OnUserLogin := IdFTPServer1UserLogin;
  IdFTPServer.OnRenameFile := IdFTPServer1RenameFile;
  IdFTPServer.OnDeleteFile := IdFTPServer1DeleteFile;
  IdFTPServer.OnRetrieveFile := IdFTPServer1RetrieveFile;
  IdFTPServer.OnStoreFile := IdFTPServer1StoreFile;
  IdFTPServer.OnMakeDirectory := IdFTPServer1MakeDirectory;
  IdFTPServer.OnRemoveDirectory := IdFTPServer1RemoveDirectory;
  IdFTPServer.Greeting.Text.Text := '��ӭ����FTP������';
  IdFTPServer.Greeting.NumericCode := 220;
  IdFTPServer.OnDisconnect := IdFTPServer1DisConnect;
  with IdFTPServer.CommandHandlers.add do
  begin
    Command := 'XCRC';   //����Ѹ����֤�����ص��ĵ��Ƿ��Դ�ĵ�һ��
    OnCommand := IdFTPServer1CommandXCRC;
  end;
end;
{-------------------------------------------------------------------------------
  ������:    CalculateCRC
  ����:      ����CRC        
  ����:      const path: string
  ����ֵ:    string
-------------------------------------------------------------------------------}
function CalculateCRC( const path: string ) : string;
var
  f: tfilestream;
  value: dword;
  IdHashCRC32: TIdHashCRC32;
begin
  IdHashCRC32 := nil;
  f := nil;
  try
    IdHashCRC32 := TIdHashCRC32.create;
    f := TFileStream.create( path, fmOpenRead or fmShareDenyWrite ) ;
    value := IdHashCRC32.HashValue( f ) ;
    result := inttohex( value, 8 ) ;
  finally
    f.free;
    IdHashCRC32.free;
  end;
end;

{-------------------------------------------------------------------------------
  ������:    TFTPServer.IdFTPServer1CommandXCRC
  ����:      XCRC����        
  ����:      ASender: TIdCommand
  ����ֵ:    ��
-------------------------------------------------------------------------------}
procedure TFTPServer.IdFTPServer1CommandXCRC( ASender: TIdCommand ) ;
// note, this is made up, and not defined in any rfc.
var
  s: string;
begin
  with TIdFTPServerThread( ASender.Thread ) do
  begin
    if Authenticated then
    begin
      try
        s := ProcessPath( CurrentDir, ASender.UnparsedParams ) ;
        s := TransLatePath( s, TIdFTPServerThread( ASender.Thread ) .HomeDir ) ;
        ASender.Reply.SetReply( 213, CalculateCRC( s ) ) ;
      except
        ASender.Reply.SetReply( 500, 'file error' ) ;
      end;
    end;
  end;
end;

{-------------------------------------------------------------------------------
  ������:    TFTPServer.Destroy
  ����:      ��������        
  ����:      ��
  ����ֵ:    ��
-------------------------------------------------------------------------------}
destructor TFTPServer.Destroy;
begin
  IdFTPServer.free;
  inherited destroy;
end;

function StartsWith( const str, substr: string ) : boolean;
begin
  result := copy( str, 1, length( substr ) ) = substr;
end;

{-------------------------------------------------------------------------------
  ������:    TFTPServer.Run
  ����:      ��������        
  ����:      ��
  ����ֵ:    ��
-------------------------------------------------------------------------------}
procedure TFTPServer.Run;
begin
  IdFTPServer.DefaultPort := BorrowPort;
  IdFTPServer.Active := True;
end;

{-------------------------------------------------------------------------------
  ������:    TFTPServer.Stop
  ����:      �رշ���        
  ����:      ��
  ����ֵ:    ��
-------------------------------------------------------------------------------}
procedure TFTPServer.Stop;
begin 
  IdFTPServer.Active := False;
end;

{-------------------------------------------------------------------------------
  ������:    TFTPServer.GetBindingIP
  ����:      ��ȡ�󶨵�IP��ַ        
  ����:      
  ����ֵ:    string
-------------------------------------------------------------------------------}
function TFTPServer.GetBindingIP():string ;
begin
  Result := GStack.LocalAddress;  
end;
{-------------------------------------------------------------------------------
  ������:    BackSlashToSlash
  ����:      ��б�ܵ�б��
  ����:      const str: string
  ����ֵ:    string
-------------------------------------------------------------------------------}
function BackSlashToSlash( const str: string ) : string;
var
  a: dword;
begin
  result := str;
  for a := 1 to length( result ) do
    if result[a] = '\' then
      result[a] := '/';
end;

{-------------------------------------------------------------------------------
  ������:    SlashToBackSlash
  ����:      б�ܵ���б��        
  ����:      const str: string
  ����ֵ:    string
-------------------------------------------------------------------------------}
function SlashToBackSlash( const str: string ) : string;
var
  a: dword;
begin
  result := str;
  for a := 1 to length( result ) do
    if result[a] = '/' then
      result[a] := '\';
end;

{-------------------------------------------------------------------------------
  ������:    TFTPServer.TransLatePath
  ����:      ·�����Ʒ���        
  ����:      const APathname, homeDir: string
  ����ֵ:    string
-------------------------------------------------------------------------------}
function TFTPServer.TransLatePath( const APathname, homeDir: string ) : string;
var
  tmppath: string;
begin
  result := SlashToBackSlash(Utf8ToAnsi(homeDir) ) ;
  tmppath := SlashToBackSlash( Utf8ToAnsi(APathname) ) ;
  if homedir = '/' then
  begin
    result := tmppath;
    exit;
  end;

  if length( APathname ) = 0 then
    exit;
  if result[length( result ) ] = '\' then
    result := copy( result, 1, length( result ) - 1 ) ;
  if tmppath[1] <> '\' then
    result := result + '\';
  result := result + tmppath;
end;

{-------------------------------------------------------------------------------
  ������:    GetNewDirectory
  ����:      �õ���Ŀ¼        
  ����:      old, action: string
  ����ֵ:    string
-------------------------------------------------------------------------------}
function GetNewDirectory( old, action: string ) : string;
var
  a: integer;
begin
  if action = '../' then
  begin
    if old = '/' then
    begin
      result := old;
      exit;
    end;
    a := length( old ) - 1;
    while ( old[a] <> '\' ) and ( old[a] <> '/' ) do
      dec( a ) ;
    result := copy( old, 1, a ) ;
    exit;
  end;
  if ( action[1] = '/' ) or ( action[1] = '\' ) then
    result := action
  else
    result := old + action;
end;

{-------------------------------------------------------------------------------
  ������:    TFTPServer.IdFTPServer1UserLogin
  ����:      ���������ִ��һ���ͻ������ӵ��û��ʻ������֤        
  ����:      ASender: TIdFTPServerThread; const AUsername, APassword: string; var AAuthenticated: Boolean
  ����ֵ:    ��
-------------------------------------------------------------------------------}
procedure TFTPServer.IdFTPServer1UserLogin( ASender: TIdFTPServerThread;
  const AUsername, APassword: string; var AAuthenticated: Boolean ) ;
begin
  AAuthenticated := ( AUsername = UserName ) and ( APassword = UserPassword ) ;
  if not AAuthenticated then
    exit;
  ASender.HomeDir := AnsiToUtf8(BorrowDirectory);
  asender.currentdir := '/';
  if Assigned(FOnFtpNotifyEvent) then
    OnFtpNotifyEvent(Now, ASender.Connection.Socket.Binding.PeerIP,'�û���¼������');
end;

{-------------------------------------------------------------------------------
  ������:    TFTPServer.IdFTPServer1ListDirectory
  ����:      ������������ɸ�ʽ����Ŀ¼�б�        
  ����:      ASender: TIdFTPServerThread; const APath: string; ADirectoryListing: TIdFTPListItems
  ����ֵ:    ��
-------------------------------------------------------------------------------}
procedure TFTPServer.IdFTPServer1ListDirectory( ASender: TIdFTPServerThread; const APath: string; ADirectoryListing: TIdFTPListItems ) ;

  procedure AddlistItem( aDirectoryListing: TIdFTPListItems; Filename: string; ItemType: TIdDirItemType; size: int64; date: tdatetime ) ;
  var
    listitem: TIdFTPListItem;
  begin
    listitem := aDirectoryListing.Add;
    listitem.ItemType := ItemType; //��ʾһ���ļ�ϵͳ�����Լ�
    listitem.FileName := AnsiToUtf8(Filename);  //���Ʒ����Ŀ¼�е��б���,�����ֹ����������
    listitem.OwnerName := 'anonymous';//�������û�ӵ�е��ļ���Ŀ¼�������
    listitem.GroupName := 'all';    //ָ������ӵ�е��ļ����ƻ�Ŀ¼��Ŀ
    listitem.OwnerPermissions := 'rwx'; //ӵ����Ȩ�ޣ�R��WдXִ��
    listitem.GroupPermissions := 'rwx'; //��ӵ����Ȩ��
    listitem.UserPermissions := 'rwx';  //�û�Ȩ�ޣ������û�����Ȩ��
    listitem.Size := size;
    listitem.ModifiedDate := date;
  end;

var
  f: tsearchrec;
  a: integer;
begin
  ADirectoryListing.DirectoryName := apath; 
  a := FindFirst( TransLatePath( apath, ASender.HomeDir ) + '*.*', faAnyFile, f ) ;
  while ( a = 0 ) do
  begin
    if ( f.Attr and faDirectory > 0 ) then
      AddlistItem( ADirectoryListing, f.Name, ditDirectory, f.size, FileDateToDateTime( f.Time ) )
    else
      AddlistItem( ADirectoryListing, f.Name, ditFile, f.size, FileDateToDateTime( f.Time ) ) ;
    a := FindNext( f ) ;
  end;

  FindClose( f ) ;
end;

{-------------------------------------------------------------------------------
  ������:    TFTPServer.IdFTPServer1RenameFile
  ����:      ����������������������ļ�ϵͳ�е��ļ�        
  ����:      ASender: TIdFTPServerThread; const ARenameFromFile, ARenameToFile: string
  ����ֵ:    ��
-------------------------------------------------------------------------------}
procedure TFTPServer.IdFTPServer1RenameFile( ASender: TIdFTPServerThread;
  const ARenameFromFile, ARenameToFile: string ) ;
begin
  try
    if not MoveFile( pchar( TransLatePath( ARenameFromFile, ASender.HomeDir ) ) , pchar( TransLatePath( ARenameToFile, ASender.HomeDir ) ) ) then
      RaiseLastOSError;
  except
    on e:Exception do
    begin
      if Assigned(FOnFtpNotifyEvent) then
        OnFtpNotifyEvent(Now, ASender.Connection.Socket.Binding.PeerIP,'�������ļ�[' + Utf8ToAnsi(ARenameFromFile) + ']ʧ�ܣ�ԭ����' + e.Message);
      Exit;
    end;
  end;
  if Assigned(FOnFtpNotifyEvent) then
    OnFtpNotifyEvent(Now, ASender.Connection.Socket.Binding.PeerIP,'�������ļ�[' + Utf8ToAnsi(ARenameFromFile) + ']Ϊ[' + Utf8ToAnsi(ARenameToFile) + ']');
end;

{-------------------------------------------------------------------------------
  ������:    TFTPServer.IdFTPServer1RetrieveFile
  ����:      ����ӷ����������ļ�ϵͳ�е��ļ�
  ����:      ASender: TIdFTPServerThread; const AFilename: string; var VStream: TStream
  ����ֵ:    ��
-------------------------------------------------------------------------------}
procedure TFTPServer.IdFTPServer1RetrieveFile( ASender: TIdFTPServerThread;
  const AFilename: string; var VStream: TStream ) ;
begin
  VStream := TFileStream.Create( translatepath( AFilename, ASender.HomeDir ) , fmopenread or fmShareDenyWrite ) ;
  if Assigned(FOnFtpNotifyEvent) then
    OnFtpNotifyEvent(Now, ASender.Connection.Socket.Binding.PeerIP,'�����ļ�[' + Utf8ToAnsi(AFilename) + ']');
end;

{-------------------------------------------------------------------------------
  ������:    TFTPServer.IdFTPServer1StoreFile
  ����:      �����ڷ������ϴ��ļ�ϵͳ�е��ļ�
  ����:      ASender: TIdFTPServerThread; const AFilename: string; AAppend: Boolean; var VStream: TStream
  ����ֵ:    ��
-------------------------------------------------------------------------------}
procedure TFTPServer.IdFTPServer1StoreFile( ASender: TIdFTPServerThread;
  const AFilename: string; AAppend: Boolean; var VStream: TStream ) ;
begin
  if FileExists( translatepath( AFilename, ASender.HomeDir ) ) and AAppend then
  begin
    VStream := TFileStream.create( translatepath( AFilename, ASender.HomeDir ) , fmOpenWrite or fmShareExclusive ) ;
    VStream.Seek( 0, soFromEnd ) ;
  end
  else
    VStream := TFileStream.create( translatepath( AFilename, ASender.HomeDir ) , fmCreate or fmShareExclusive ) ;
  if Assigned(FOnFtpNotifyEvent) then
    OnFtpNotifyEvent(Now, ASender.Connection.Socket.Binding.PeerIP,'�ϴ��ļ�[' + Utf8ToAnsi(AFilename) + ']');
end;

{-------------------------------------------------------------------------------
  ������:    TFTPServer.IdFTPServer1RemoveDirectory
  ����:      ����������ڷ�����ɾ���ļ�ϵͳ��Ŀ¼        
  ����:      ASender: TIdFTPServerThread; var VDirectory: string
  ����ֵ:    ��
-------------------------------------------------------------------------------}
procedure TFTPServer.IdFTPServer1RemoveDirectory( ASender: TIdFTPServerThread;
  var VDirectory: string ) ;
begin
  try
    RmDir( TransLatePath( VDirectory, ASender.HomeDir ) ) ;
  except
    on e:Exception do
    begin
      if Assigned(FOnFtpNotifyEvent) then
        OnFtpNotifyEvent(Now, ASender.Connection.Socket.Binding.PeerIP,'ɾ��Ŀ¼[' + Utf8ToAnsi(VDirectory) + ']ʧ�ܣ�ԭ����' + e.Message);
      Exit;
    end;
  end;
  if Assigned(FOnFtpNotifyEvent) then
    OnFtpNotifyEvent(Now, ASender.Connection.Socket.Binding.PeerIP,'ɾ��Ŀ¼[' + Utf8ToAnsi(VDirectory) + ']');
end;

{-------------------------------------------------------------------------------
  ������:    TFTPServer.IdFTPServer1MakeDirectory
  ����:      ����������ӷ������д���һ���µ���Ŀ¼
  ����:      ASender: TIdFTPServerThread; var VDirectory: string
  ����ֵ:    ��
-------------------------------------------------------------------------------}
procedure TFTPServer.IdFTPServer1MakeDirectory( ASender: TIdFTPServerThread;
  var VDirectory: string ) ;
begin
  try
    MkDir( TransLatePath( VDirectory, ASender.HomeDir ) ) ;
  except
    on e:Exception do
    begin
      if Assigned(FOnFtpNotifyEvent) then
        OnFtpNotifyEvent(Now, ASender.Connection.Socket.Binding.PeerIP,'����Ŀ¼[' + Utf8ToAnsi(VDirectory) + ']ʧ�ܣ�ԭ����' + e.Message);
      Exit;
    end;
  end;
  if Assigned(FOnFtpNotifyEvent) then
    OnFtpNotifyEvent(Now, ASender.Connection.Socket.Binding.PeerIP,'����Ŀ¼[' + Utf8ToAnsi(VDirectory) + ']');
end;

{-------------------------------------------------------------------------------
  ������:    TFTPServer.IdFTPServer1GetFileSize
  ����:      ��������������ڷ������ļ�ϵͳ���ļ��Ĵ�С        
  ����:      ASender: TIdFTPServerThread; const AFilename: string; var VFileSize: Int64
  ����ֵ:    ��
-------------------------------------------------------------------------------}
procedure TFTPServer.IdFTPServer1GetFileSize( ASender: TIdFTPServerThread;
  const AFilename: string; var VFileSize: Int64 ) ;
begin
  VFileSize := FileSizeByName( TransLatePath( AFilename, ASender.HomeDir ) ) ;
  if Assigned(FOnFtpNotifyEvent) then
    OnFtpNotifyEvent(Now, ASender.Connection.Socket.Binding.PeerIP,'��ȡ�ļ���С');
end;

{-------------------------------------------------------------------------------
  ������:    TFTPServer.IdFTPServer1DeleteFile
  ����:      ����ӷ�������ɾ�����ļ�ϵͳ�е��ļ�
  ����:      ASender: TIdFTPServerThread; const APathname: string
  ����ֵ:    ��
-------------------------------------------------------------------------------}
procedure TFTPServer.IdFTPServer1DeleteFile( ASender: TIdFTPServerThread;
  const APathname: string ) ;
begin
  try
    DeleteFile( pchar( TransLatePath( ASender.CurrentDir + '/' + APathname, ASender.HomeDir ) ) ) ;
  except
    on e:Exception do
    begin
      if Assigned(FOnFtpNotifyEvent) then
        OnFtpNotifyEvent(Now, ASender.Connection.Socket.Binding.PeerIP,'ɾ���ļ�[' + Utf8ToAnsi(APathname) + ']ʧ�ܣ�ԭ����' + e.Message);
      Exit;
    end;
  end;
  if Assigned(FOnFtpNotifyEvent) then
    OnFtpNotifyEvent(Now, ASender.Connection.Socket.Binding.PeerIP,'ɾ���ļ�[' + Utf8ToAnsi(APathname) + ']');
end;

{-------------------------------------------------------------------------------
  ������:    TFTPServer.IdFTPServer1ChangeDirectory
  ����:      ���������ѡ��һ���ļ�ϵͳ·��        
  ����:      ASender: TIdFTPServerThread; var VDirectory: string
  ����ֵ:    ��
-------------------------------------------------------------------------------}
procedure TFTPServer.IdFTPServer1ChangeDirectory( ASender: TIdFTPServerThread;
  var VDirectory: string ) ;
begin
  VDirectory := GetNewDirectory( ASender.CurrentDir, VDirectory ) ;
  if Assigned(FOnFtpNotifyEvent) then
    OnFtpNotifyEvent(Now, ASender.Connection.Socket.Binding.PeerIP,'����Ŀ¼[' + Utf8ToAnsi(VDirectory) + ']');
end;

{-------------------------------------------------------------------------------
  ������:    TFTPServer.IdFTPServer1DisConnect
  ����:      ʧȥ��������        
  ����:      AThread: TIdPeerThread
  ����ֵ:    ��
-------------------------------------------------------------------------------}
procedure TFTPServer.IdFTPServer1DisConnect( AThread: TIdPeerThread ) ;
begin
  //  nothing much here
end;
end.
