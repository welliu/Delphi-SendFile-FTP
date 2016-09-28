{*******************************************************}
{                                                       }
{       系统名称 FTP服务器类                            }
{       版权所有 (C) http://blog.csdn.net/akof1314      }
{       单元名称 FTPServer.pas                          }
{       单元功能 在Delphi 7下TIdFTPServer实现FTP服务器  }
{                                                       }
{*******************************************************}
unit FTPServer;

interface

uses
  Classes,  Windows,  Sysutils,  IdFTPList,  IdFTPServer,  Idtcpserver,  IdSocketHandle,  Idglobal,  IdHashCRC, IdStack;
{-------------------------------------------------------------------------------
  功能:  自定义消息，方便与窗体进行消息传递
-------------------------------------------------------------------------------}
  type
    TFtpNotifyEvent = procedure (ADatetime: TDateTime;AUserIP, AEventMessage: string) of object;
{-------------------------------------------------------------------------------
  功能:  FTP服务器类
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
  过程名:    TFTPServer.Create
  功能:      创建函数
  参数:      无
  返回值:    无
-------------------------------------------------------------------------------}
constructor TFTPServer.Create;
begin
  IdFTPServer := tIdFTPServer.create( nil ) ;
  IdFTPServer.DefaultPort := 21;               //默认端口号
  IdFTPServer.AllowAnonymousLogin := False;   //是否允许匿名登录
  IdFTPServer.EmulateSystem := ftpsUNIX;
  IdFTPServer.HelpReply.text := '帮助还未实现！';
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
  IdFTPServer.Greeting.Text.Text := '欢迎进入FTP服务器';
  IdFTPServer.Greeting.NumericCode := 220;
  IdFTPServer.OnDisconnect := IdFTPServer1DisConnect;
  with IdFTPServer.CommandHandlers.add do
  begin
    Command := 'XCRC';   //可以迅速验证所下载的文档是否和源文档一样
    OnCommand := IdFTPServer1CommandXCRC;
  end;
end;
{-------------------------------------------------------------------------------
  过程名:    CalculateCRC
  功能:      计算CRC        
  参数:      const path: string
  返回值:    string
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
  过程名:    TFTPServer.IdFTPServer1CommandXCRC
  功能:      XCRC命令        
  参数:      ASender: TIdCommand
  返回值:    无
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
  过程名:    TFTPServer.Destroy
  功能:      析构函数        
  参数:      无
  返回值:    无
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
  过程名:    TFTPServer.Run
  功能:      开启服务        
  参数:      无
  返回值:    无
-------------------------------------------------------------------------------}
procedure TFTPServer.Run;
begin
  IdFTPServer.DefaultPort := BorrowPort;
  IdFTPServer.Active := True;
end;

{-------------------------------------------------------------------------------
  过程名:    TFTPServer.Stop
  功能:      关闭服务        
  参数:      无
  返回值:    无
-------------------------------------------------------------------------------}
procedure TFTPServer.Stop;
begin 
  IdFTPServer.Active := False;
end;

{-------------------------------------------------------------------------------
  过程名:    TFTPServer.GetBindingIP
  功能:      获取绑定的IP地址        
  参数:      
  返回值:    string
-------------------------------------------------------------------------------}
function TFTPServer.GetBindingIP():string ;
begin
  Result := GStack.LocalAddress;  
end;
{-------------------------------------------------------------------------------
  过程名:    BackSlashToSlash
  功能:      反斜杠到斜杠
  参数:      const str: string
  返回值:    string
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
  过程名:    SlashToBackSlash
  功能:      斜杠到反斜杠        
  参数:      const str: string
  返回值:    string
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
  过程名:    TFTPServer.TransLatePath
  功能:      路径名称翻译        
  参数:      const APathname, homeDir: string
  返回值:    string
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
  过程名:    GetNewDirectory
  功能:      得到新目录        
  参数:      old, action: string
  返回值:    string
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
  过程名:    TFTPServer.IdFTPServer1UserLogin
  功能:      允许服务器执行一个客户端连接的用户帐户身份验证        
  参数:      ASender: TIdFTPServerThread; const AUsername, APassword: string; var AAuthenticated: Boolean
  返回值:    无
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
    OnFtpNotifyEvent(Now, ASender.Connection.Socket.Binding.PeerIP,'用户登录服务器');
end;

{-------------------------------------------------------------------------------
  过程名:    TFTPServer.IdFTPServer1ListDirectory
  功能:      允许服务器生成格式化的目录列表        
  参数:      ASender: TIdFTPServerThread; const APath: string; ADirectoryListing: TIdFTPListItems
  返回值:    无
-------------------------------------------------------------------------------}
procedure TFTPServer.IdFTPServer1ListDirectory( ASender: TIdFTPServerThread; const APath: string; ADirectoryListing: TIdFTPListItems ) ;

  procedure AddlistItem( aDirectoryListing: TIdFTPListItems; Filename: string; ItemType: TIdDirItemType; size: int64; date: tdatetime ) ;
  var
    listitem: TIdFTPListItem;
  begin
    listitem := aDirectoryListing.Add;
    listitem.ItemType := ItemType; //表示一个文件系统的属性集
    listitem.FileName := AnsiToUtf8(Filename);  //名称分配给目录中的列表项,这里防止了中文乱码
    listitem.OwnerName := 'anonymous';//代表了用户拥有的文件或目录项的名称
    listitem.GroupName := 'all';    //指定组名拥有的文件名称或目录条目
    listitem.OwnerPermissions := 'rwx'; //拥有者权限，R读W写X执行
    listitem.GroupPermissions := 'rwx'; //组拥有者权限
    listitem.UserPermissions := 'rwx';  //用户权限，基于用户和组权限
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
  过程名:    TFTPServer.IdFTPServer1RenameFile
  功能:      允许服务器重命名服务器文件系统中的文件        
  参数:      ASender: TIdFTPServerThread; const ARenameFromFile, ARenameToFile: string
  返回值:    无
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
        OnFtpNotifyEvent(Now, ASender.Connection.Socket.Binding.PeerIP,'重命名文件[' + Utf8ToAnsi(ARenameFromFile) + ']失败，原因是' + e.Message);
      Exit;
    end;
  end;
  if Assigned(FOnFtpNotifyEvent) then
    OnFtpNotifyEvent(Now, ASender.Connection.Socket.Binding.PeerIP,'重命名文件[' + Utf8ToAnsi(ARenameFromFile) + ']为[' + Utf8ToAnsi(ARenameToFile) + ']');
end;

{-------------------------------------------------------------------------------
  过程名:    TFTPServer.IdFTPServer1RetrieveFile
  功能:      允许从服务器下载文件系统中的文件
  参数:      ASender: TIdFTPServerThread; const AFilename: string; var VStream: TStream
  返回值:    无
-------------------------------------------------------------------------------}
procedure TFTPServer.IdFTPServer1RetrieveFile( ASender: TIdFTPServerThread;
  const AFilename: string; var VStream: TStream ) ;
begin
  VStream := TFileStream.Create( translatepath( AFilename, ASender.HomeDir ) , fmopenread or fmShareDenyWrite ) ;
  if Assigned(FOnFtpNotifyEvent) then
    OnFtpNotifyEvent(Now, ASender.Connection.Socket.Binding.PeerIP,'下载文件[' + Utf8ToAnsi(AFilename) + ']');
end;

{-------------------------------------------------------------------------------
  过程名:    TFTPServer.IdFTPServer1StoreFile
  功能:      允许在服务器上传文件系统中的文件
  参数:      ASender: TIdFTPServerThread; const AFilename: string; AAppend: Boolean; var VStream: TStream
  返回值:    无
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
    OnFtpNotifyEvent(Now, ASender.Connection.Socket.Binding.PeerIP,'上传文件[' + Utf8ToAnsi(AFilename) + ']');
end;

{-------------------------------------------------------------------------------
  过程名:    TFTPServer.IdFTPServer1RemoveDirectory
  功能:      允许服务器在服务器删除文件系统的目录        
  参数:      ASender: TIdFTPServerThread; var VDirectory: string
  返回值:    无
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
        OnFtpNotifyEvent(Now, ASender.Connection.Socket.Binding.PeerIP,'删除目录[' + Utf8ToAnsi(VDirectory) + ']失败，原因是' + e.Message);
      Exit;
    end;
  end;
  if Assigned(FOnFtpNotifyEvent) then
    OnFtpNotifyEvent(Now, ASender.Connection.Socket.Binding.PeerIP,'删除目录[' + Utf8ToAnsi(VDirectory) + ']');
end;

{-------------------------------------------------------------------------------
  过程名:    TFTPServer.IdFTPServer1MakeDirectory
  功能:      允许服务器从服务器中创建一个新的子目录
  参数:      ASender: TIdFTPServerThread; var VDirectory: string
  返回值:    无
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
        OnFtpNotifyEvent(Now, ASender.Connection.Socket.Binding.PeerIP,'创建目录[' + Utf8ToAnsi(VDirectory) + ']失败，原因是' + e.Message);
      Exit;
    end;
  end;
  if Assigned(FOnFtpNotifyEvent) then
    OnFtpNotifyEvent(Now, ASender.Connection.Socket.Binding.PeerIP,'创建目录[' + Utf8ToAnsi(VDirectory) + ']');
end;

{-------------------------------------------------------------------------------
  过程名:    TFTPServer.IdFTPServer1GetFileSize
  功能:      允许服务器检索在服务器文件系统的文件的大小        
  参数:      ASender: TIdFTPServerThread; const AFilename: string; var VFileSize: Int64
  返回值:    无
-------------------------------------------------------------------------------}
procedure TFTPServer.IdFTPServer1GetFileSize( ASender: TIdFTPServerThread;
  const AFilename: string; var VFileSize: Int64 ) ;
begin
  VFileSize := FileSizeByName( TransLatePath( AFilename, ASender.HomeDir ) ) ;
  if Assigned(FOnFtpNotifyEvent) then
    OnFtpNotifyEvent(Now, ASender.Connection.Socket.Binding.PeerIP,'获取文件大小');
end;

{-------------------------------------------------------------------------------
  过程名:    TFTPServer.IdFTPServer1DeleteFile
  功能:      允许从服务器中删除的文件系统中的文件
  参数:      ASender: TIdFTPServerThread; const APathname: string
  返回值:    无
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
        OnFtpNotifyEvent(Now, ASender.Connection.Socket.Binding.PeerIP,'删除文件[' + Utf8ToAnsi(APathname) + ']失败，原因是' + e.Message);
      Exit;
    end;
  end;
  if Assigned(FOnFtpNotifyEvent) then
    OnFtpNotifyEvent(Now, ASender.Connection.Socket.Binding.PeerIP,'删除文件[' + Utf8ToAnsi(APathname) + ']');
end;

{-------------------------------------------------------------------------------
  过程名:    TFTPServer.IdFTPServer1ChangeDirectory
  功能:      允许服务器选择一个文件系统路径        
  参数:      ASender: TIdFTPServerThread; var VDirectory: string
  返回值:    无
-------------------------------------------------------------------------------}
procedure TFTPServer.IdFTPServer1ChangeDirectory( ASender: TIdFTPServerThread;
  var VDirectory: string ) ;
begin
  VDirectory := GetNewDirectory( ASender.CurrentDir, VDirectory ) ;
  if Assigned(FOnFtpNotifyEvent) then
    OnFtpNotifyEvent(Now, ASender.Connection.Socket.Binding.PeerIP,'进入目录[' + Utf8ToAnsi(VDirectory) + ']');
end;

{-------------------------------------------------------------------------------
  过程名:    TFTPServer.IdFTPServer1DisConnect
  功能:      失去网络连接        
  参数:      AThread: TIdPeerThread
  返回值:    无
-------------------------------------------------------------------------------}
procedure TFTPServer.IdFTPServer1DisConnect( AThread: TIdPeerThread ) ;
begin
  //  nothing much here
end;
end.
