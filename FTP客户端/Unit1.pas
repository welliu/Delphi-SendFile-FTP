{*******************************************************}
{                                                       }
{       ϵͳ���� IdFTP��ȫʹ��                          }
{       ��Ȩ���� (C) http://blog.csdn.net/akof1314      }
{       ��Ԫ���� Unit1.pas                              }
{       ��Ԫ���� ��Delphi 7��ʵ��FTP�ͻ���              }
{                                                       }
{*******************************************************}
unit Unit1;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, IdBaseComponent, IdComponent, IdTCPConnection,
  IdTCPClient, IdFTP, IdFTPCommon, IdFTPList, ComCtrls, IdGlobal,
  IdAntiFreezeBase, IdAntiFreeze, FileCtrl, Grids, DBGrids, DB, DBClient;

type
  TForm1 = class(TForm)
    idftp_Client: TIdFTP;
    edt_ServerAddress:TEdit;
    edt_UserName: TEdit;
    edt_UserPassword: TEdit;
    lbl1: TLabel;
    lbl2: TLabel;
    lbl3: TLabel;
    btn_Connect: TButton;
    btn_Download: TButton;
    btn_Upload: TButton;
    btn_Delete: TButton;
    btn_MKDirectory: TButton;
    btn_Abort: TButton;
    mmo_Log: TMemo;
    pb_ShowWorking: TProgressBar;
    dlgSave_File: TSaveDialog;
    idntfrz1: TIdAntiFreeze;
    dlgOpen_File: TOpenDialog;
    btn_UploadDirectory: TButton;
    tv1: TTreeView;
    btn_Fresh: TButton;
    stat1: TStatusBar;
    dbgrd1: TDBGrid;
    ds1: TClientDataSet;
    ds2: TDataSource;
    procedure btn_ConnectClick(Sender: TObject);
    procedure btn_DownloadClick(Sender: TObject);
    procedure idftp_ClientWork(Sender: TObject; AWorkMode: TWorkMode;
      const AWorkCount: Integer);
    procedure idftp_ClientWorkBegin(Sender: TObject; AWorkMode: TWorkMode;
      const AWorkCountMax: Integer);
    procedure idftp_ClientWorkEnd(Sender: TObject; AWorkMode: TWorkMode);
    procedure FormCreate(Sender: TObject);
    procedure btn_AbortClick(Sender: TObject);
    procedure btn_UploadClick(Sender: TObject);
    procedure btn_DeleteClick(Sender: TObject);
    procedure btn_MKDirectoryClick(Sender: TObject);
    procedure btn_UploadDirectoryClick(Sender: TObject);
    procedure tv1Expanding(Sender: TObject; Node: TTreeNode;
      var AllowExpansion: Boolean);
    procedure btn_FreshClick(Sender: TObject);
    procedure tv1Change(Sender: TObject; Node: TTreeNode);
  private
    FTransferrignData: Boolean;    //�Ƿ��ڴ�������
    FBytesToTransfer: LongWord;    //������ֽڴ�С
    FAbortTransfer: Boolean;       //ȡ�����ݴ���
    STime : TDateTime;             //ʱ��
    FAverageSpeed : Double;        //ƽ���ٶ�
    procedure ChageDir(DirName: String);
    procedure FreshTree(DirName: String);
    function CheckState:Boolean;
  public
    nodePath:string;
  end;



var
  Form1: TForm1;
const
  orginDir = '/';
  formName = '�ͻ��� ';
  
function getNodePath(Node:TTreeNode):string;
function isDirectory(var idftp_Client:TIdFTP;parentPath,fileName:String):Boolean;

implementation

{$R *.dfm}
function isDirectory(var idftp_Client:TIdFTP;parentPath,fileName:String):Boolean;
var
  i:Integer;
begin
  idftp_Client.ChangeDir(Trim(AnsiToUtf8(parentPath)));
  idftp_Client.TransferType := ftASCII;
  idftp_Client.List(nil);
  with idftp_Client.DirectoryListing do
  begin
    for i := 0 to Count - 1 do
    begin
      if Utf8ToAnsi(Trim(Items[i].FileName))= Trim(fileName) then
      begin
        result:=(Items[i].ItemType = ditDirectory);
        Break;
      end;
    end
  end;
end;

function getNodePath(Node:TTreeNode):string;
var
  strPath:string;
  level:Integer;
  curNode:TTreeNode;
begin
  if Node.Parent = nil then
  begin
    result:=orginDir;
    Exit;
  end;
  level:=Node.Level;
  curNode:=node;
  strPath:=Node.Text+'/';
  while level>1 do
  begin
    strPath:=curNode.Parent.Text+'/'+strPath;
    curNode:=curNode.Parent;
    level:=level-1;
  end;
  result:=orginDir+strPath;
end;
{-------------------------------------------------------------------------------
 Description: ���崴������
-------------------------------------------------------------------------------}
procedure TForm1.FormCreate(Sender: TObject);
begin
  Self.DoubleBuffered := True;     //����˫���壬ʹ��lbl_ShowWorking��������˸
  idntfrz1.IdleTimeOut := 50;
  idntfrz1.OnlyWhenIdle := False;
  Self.nodePath:=orginDir;
end;
{-------------------------------------------------------------------------------
 Description: ���ӡ��Ͽ�����
-------------------------------------------------------------------------------}
procedure TForm1.btn_ConnectClick(Sender: TObject);
begin
  btn_Connect.Enabled := False;
  if idftp_Client.Connected then
  begin
    //������
    try
      if FTransferrignData then      //�Ƿ������ڴ���
        idftp_Client.Abort;
      idftp_Client.Quit;
    finally
      btn_Connect.Caption := '����';
      nodePath := orginDir;
      btn_Connect.Enabled := True;
      mmo_Log.Lines.Add(DateTimeToStr(Now) + '�Ͽ�������');
    end;
  end
  else
  begin
    //δ����
    with idftp_Client do
    try
      Passive := True; //����ģʽ
      Username := Trim(edt_UserName.Text);
      Password := Trim(edt_UserPassword.Text);
      Host := Trim(edt_ServerAddress.Text);
      Connect();
      Self.ChageDir(nodePath);

      tv1.Items.Clear;
      Self.FreshTree(orginDir);
    finally
      btn_Connect.Enabled := True;
      if Connected then
        btn_Connect.Caption := '�Ͽ�����';
        mmo_Log.Lines.Add(DateTimeToStr(Now) + '���ӷ�����');
    end;
  end;
end;
{-------------------------------------------------------------------------------
 Description: �鿴״̬
-------------------------------------------------------------------------------}
function TForm1.CheckState:Boolean;
begin
  if not idftp_Client.Connected then
  begin
    ShowMessage('�޷����ӷ�������');
    result:=false;
    Exit;
  end;
  if tv1.Selected=nil then
  begin
    ShowMessage('����Ŀ¼����ѡ��Ҫ������ļ���');
    result:=false;
    Exit;
  end;
  result:=True;
end;
{-------------------------------------------------------------------------------
 Description: ˢ����״Ŀ¼
-------------------------------------------------------------------------------}
procedure TForm1.FreshTree(DirName: String);
  procedure ShowTree;
  var
    node:TTreeNode;
  begin
    tv1.HideSelection:=false;
    node:=tv1.Items.Item[0];
    while node.getFirstChild <> nil do
      node:=node.getFirstChild;
    node.Selected:=true;
  end;
var
  LS: TStringList;
  i: Integer;
  rootNode,curNode:TTreeNode;
begin
  tv1.Items.Clear;

  LS := TStringList.Create;
  try
    idftp_Client.ChangeDir(AnsiToUtf8(DirName));
    idftp_Client.TransferType := ftASCII;
    nodePath := Utf8ToAnsi(idftp_Client.RetrieveCurrentDir);
    idftp_Client.List(LS);
    LS.Clear;

    rootNode:=tv1.Items.AddFirst(nil,Utf8ToAnsi(idftp_Client.RetrieveCurrentDir));
    rootNode.HasChildren:=True;

    with idftp_Client.DirectoryListing do
    begin
      for i := 0 to Count - 1 do
      begin
        if (Trim(Items[i].FileName)<>'.') and (Trim(Items[i].FileName) <> '..') then
          begin
            curNode:=tv1.Items.AddChild(rootNode,Utf8ToAnsi(Trim(Items[i].FileName)));
            curNode.HasChildren :=(Items[i].ItemType = ditDirectory);
            curNode.ImageIndex := 0;
            curNode.SelectedIndex := 1;
          end;
      end;
    end;
  finally
    LS.Free;
  end;

  //ShowTree;
end;

{-------------------------------------------------------------------------------
 Description: �ı�Ŀ¼
-------------------------------------------------------------------------------}
procedure TForm1.ChageDir(DirName: String);
var
  i: Integer;
begin
  idftp_Client.ChangeDir(AnsiToUtf8(DirName));
  idftp_Client.TransferType := ftASCII;
  nodePath := Utf8ToAnsi(idftp_Client.RetrieveCurrentDir);
  idftp_Client.List(nil);

  ds1:=TClientDataSet.Create(nil);
  ds1.FieldDefs.Add('�ļ���',ftString,100,true);
  ds1.FieldDefs.Add('��С',ftString,100,true);
  ds1.FieldDefs.Add('����',ftString,10,true);
  ds1.FieldDefs.Add('�޸�����',ftString,100,true);
  ds1.CreateDataSet;
  ds1.Open;

  with idftp_Client.DirectoryListing do
  begin
    for i := 0 to Count - 1 do
    begin
      if (Trim(Items[i].FileName) = '.')or(Trim(Items[i].FileName)='..')then
        Continue;
      ds1.Append;
      ds1.FieldByName('�ļ���').AsString:=Utf8ToAnsi(Trim(Items[i].FileName));
      ds1.FieldByName('�޸�����').AsString:=DateTimeToStr(Items[i].ModifiedDate);
      if Items[i].ItemType = ditDirectory then
      begin
        ds1.FieldByName('����').AsString:='�ļ���';
        ds1.FieldByName('��С').AsString:='...';
      end
      else
      begin
        ds1.FieldByName('����').AsString:=' �ļ�';
        if Items[i].Size/(1024*10) < 1 then
          ds1.FieldByName('��С').AsString:=IntToStr(Items[i].Size)+' B'
        else if Items[i].Size/(1024*1024) < 1 then
          ds1.FieldByName('��С').AsString:=Format('%.2f',[Items[i].Size/(1024)])+' K'
        else
          ds1.FieldByName('��С').AsString:=Format('%.2f',[Items[i].Size/(1024*1024)])+' M';
      end;
    end;
  end;
  ds2.DataSet:=ds1;
  dbgrd1.DataSource:=ds2;

  dbgrd1.Columns.Items[0].Width:=127;
  dbgrd1.Columns.Items[1].Width:=60;
  dbgrd1.Columns.Items[2].Width:=40;
  dbgrd1.Columns.Items[3].Width:=120;
  dbgrd1.Perform(WM_VSCROLL,SB_TOP,0);
end;
{-------------------------------------------------------------------------------
 Description: ���ذ�ť
-------------------------------------------------------------------------------}
procedure TForm1.btn_DownloadClick(Sender: TObject);
 procedure DownloadDirectory(var idFTP: TIdFtp;LocalDir, RemoteDir: string);
 var
   i,DirCount: Integer;
   strName: string;
 begin
   if not DirectoryExists(LocalDir + RemoteDir) then
   begin
     ForceDirectories(LocalDir + RemoteDir);  //����һ��ȫ·�����ļ���
     mmo_Log.Lines.Add('����Ŀ¼��' + LocalDir + RemoteDir);
   end;
   idFTP.ChangeDir(AnsiToUtf8(RemoteDir));
   idFTP.TransferType := ftASCII;
   idFTP.List(nil);
   DirCount := idFTP.DirectoryListing.Count;
   for i := 0 to DirCount - 1 do
   begin
     strName := Trim(Utf8ToAnsi(idFTP.DirectoryListing.Items[i].FileName));
     mmo_Log.Lines.Add('�����ļ���' + strName);
     if idFTP.DirectoryListing.Items[i].ItemType = ditDirectory then
       if (strName = '.') or (strName = '..') then
         Continue
       else
       begin
         DownloadDirectory(idFTP,LocalDir + RemoteDir + '\', strName);
         idFTP.ChangeDir('..');
         idFTP.List(nil);
       end
     else
     begin
       if (ExtractFileExt(strName) = '.txt') or (ExtractFileExt(strName) = '.html') or (ExtractFileExt(strName) = '.htm') then
         idFTP.TransferType := ftASCII    //�ı�ģʽ
       else
         idFTP.TransferType := ftBinary;   //������ģʽ
       FBytesToTransfer := idFTP.Size(AnsiToUtf8(strName));        ;
       idFTP.Get(AnsiToUtf8(strName), LocalDir + RemoteDir + '\' + strName, True);
       mmo_Log.Lines.Add('�����ļ���' + strName);
     end;
     Application.ProcessMessages;
   end;
 end;
var
  strName: string;
  strDirectory: string;
  isDir:Boolean;
begin
  if not CheckState then
    Exit;

  btn_Download.Enabled := False;
  strName := Trim(tv1.Selected.Text);

  isDir:=isDirectory(idftp_Client,AnsiToUtf8(getNodePath(tv1.Selected.Parent)),strName);
  if isDir then
  begin
    if SelectDirectory('ѡ��Ŀ¼����·��','',strDirectory) then
    begin
      DownloadDirectory(idftp_Client,strDirectory + '\',Utf8ToAnsi(strName));
      idftp_Client.ChangeDir('..');
      idftp_Client.List(nil);
    end;
  end
  else
  begin
    //���ص����ļ�
    dlgSave_File.FileName := strName;
    if dlgSave_File.Execute then
    begin
      idftp_Client.TransferType := ftBinary;
      //idftp_Client.TransferType := ftASCII;
      FBytesToTransfer := idftp_Client.Size(AnsiToUtf8(strName));
      if FileExists(dlgSave_File.FileName) then
      begin
        case MessageDlg('�ļ��Ѿ����ڣ��Ƿ�Ҫ�������أ�',  mtConfirmation, mbYesNoCancel, 0) of
          mrCancel:  //�˳�����
            begin
              Exit;
            end;
          mrYes:    //�ϵ���������ļ�
            begin
              FBytesToTransfer := FBytesToTransfer - FileSizeByName(strName);
              idftp_Client.Get(AnsiToUtf8(strName),dlgSave_File.FileName,False,True);
            end;
          mrNo:     //��ͷ��ʼ�����ļ�
            begin
              idftp_Client.Get(AnsiToUtf8(strName),dlgSave_File.FileName,True);
            end;
        end;
      end
      else
        idftp_Client.Get(strName, dlgSave_File.FileName, False);
    end;  
  end;
  btn_Download.Enabled := True;
end;
{-------------------------------------------------------------------------------
 Description: ��д�����Ĺ����¼�
-------------------------------------------------------------------------------}
procedure TForm1.idftp_ClientWork(Sender: TObject; AWorkMode: TWorkMode;
  const AWorkCount: Integer);
Var
  S: String;
  TotalTime: TDateTime;
  H, M, Sec, MS: Word;
  DLTime: Double;
begin
  TotalTime :=  Now - STime;      //�ѻ��ѵ�ʱ��
  DecodeTime(TotalTime, H, M, Sec, MS);  //����ʱ��
  Sec := Sec + M * 60 + H * 3600;  //ת�����������
  DLTime := Sec + MS / 1000;      //��ȷ������
  if DLTime > 0 then
    FAverageSpeed := (AWorkCount / 1024) / DLTime;   //��ƽ���ٶ�
  if FAverageSpeed > 0 then
  begin
    Sec := Trunc(((pb_ShowWorking.Max - AWorkCount) / 1024) / FAverageSpeed);
    S := Format('%2d:%2d:%2d', [Sec div 3600, (Sec div 60) mod 60, Sec mod 60]);
    S := 'ʣ��ʱ�� ' + S;
  end
  else
    S := '';
  S := FormatFloat('0.00 KB/s', FAverageSpeed) + '; ' + S;

  //Sleep(1000);
  case AWorkMode of
    wmRead: stat1.Panels[0].Text := '�����ٶ� ' + S;
    wmWrite: stat1.Panels[0].Text := '�ϴ��ٶ� ' + S;
  end;
  if FAbortTransfer then   //ȡ�����ݴ���
    idftp_Client.Abort;
  pb_ShowWorking.Position := AWorkCount;
  FAbortTransfer := false;
end;
{-------------------------------------------------------------------------------
 Description: ��ʼ��д�������¼�
-------------------------------------------------------------------------------}
procedure TForm1.idftp_ClientWorkBegin(Sender: TObject;
  AWorkMode: TWorkMode; const AWorkCountMax: Integer);
begin
  FTransferrignData := True;
  btn_Abort.Enabled := True;
  FAbortTransfer := False;
  STime := Now;
  if AWorkCountMax > 0 then
    pb_ShowWorking.Max := AWorkCountMax
  else
    pb_ShowWorking.Max := FBytesToTransfer;
  FAverageSpeed := 0;
end;
{-------------------------------------------------------------------------------
 Description: ��д�������֮����¼�
-------------------------------------------------------------------------------}
procedure TForm1.idftp_ClientWorkEnd(Sender: TObject;
  AWorkMode: TWorkMode);
begin
  btn_Abort.Enabled := False;
  FTransferrignData := False;
  FBytesToTransfer := 0;
  pb_ShowWorking.Position := 0;
  FAverageSpeed := 0;
  stat1.Panels[0].Text:= '�������';
end;
{-------------------------------------------------------------------------------
 Description: ȡ����ť
-------------------------------------------------------------------------------}
procedure TForm1.btn_AbortClick(Sender: TObject);
begin
  FAbortTransfer := True;
end;
{-------------------------------------------------------------------------------
 Description: �ϴ���ť
-------------------------------------------------------------------------------}
procedure TForm1.btn_UploadClick(Sender: TObject);
begin
  if not CheckState then
    Exit;

  if dlgOpen_File.Execute then
  begin
    idftp_Client.TransferType := ftBinary;
    idftp_Client.Put(dlgOpen_File.FileName, Trim(AnsiToUtf8(ExtractFileName(dlgOpen_File.FileName))));
    ChageDir(Trim(Utf8ToAnsi(idftp_Client.RetrieveCurrentDir)));
  end;
  Self.FreshTree(orginDir);
end;
{-------------------------------------------------------------------------------
 Description: ɾ����ť
-------------------------------------------------------------------------------}
procedure TForm1.btn_DeleteClick(Sender: TObject);
  procedure DeleteDirectory(var idFTP: TIdFtp; RemoteDir: string);
  var
    i,DirCount: Integer;
    strName: string;
  begin
    idFTP.List(nil);
    DirCount := idFTP.DirectoryListing.Count;
    if DirCount = 2 then
    begin
      idFTP.ChangeDir('..');
      idFTP.RemoveDir(RemoteDir);
      idFTP.List(nil);
      Application.ProcessMessages;
      mmo_Log.Lines.Add('ɾ���ļ��У�' + Utf8ToAnsi(RemoteDir));
      Exit;
    end;
    for i := 0 to 2 do
    begin
      strName := idFTP.DirectoryListing.Items[i].FileName;
      if idFTP.DirectoryListing.Items[i].ItemType = ditDirectory then
      begin
        if (strName = '.') or (strName = '..') then
         Continue;
        idFTP.ChangeDir(strName);
        DeleteDirectory(idFTP,strName);
        DeleteDirectory(idFTP,RemoteDir);
      end
      else
      begin
        idFTP.Delete(strName);
        Application.ProcessMessages;
        mmo_Log.Lines.Add('ɾ���ļ���' + Utf8ToAnsi(strName));
        DeleteDirectory(idFTP,RemoteDir);
      end;  
    end;
  end;
Var
  strName: String;
  isDir:Boolean;
begin
  if not CheckState then
    Exit;

  strName := Trim(tv1.Selected.Text);
  isDir:=isDirectory(idftp_Client,getNodePath(tv1.Selected.Parent),strName);
  if isDir then
    try
      idftp_Client.ChangeDir(strName);
      DeleteDirectory(idftp_Client,strName);
      ChageDir(Utf8ToAnsi(idftp_Client.RetrieveCurrentDir));
    finally
    end
  else       //ɾ�������ļ�
    try
      idftp_Client.Delete(strName);
      ChageDir(Utf8ToAnsi(idftp_Client.RetrieveCurrentDir));
    finally
    end;
  Self.FreshTree(orginDir);
end;
{-------------------------------------------------------------------------------
 Description: �½�Ŀ¼��ť
-------------------------------------------------------------------------------}
procedure TForm1.btn_MKDirectoryClick(Sender: TObject);
var
  S,strName: string;
  isDir:Boolean;
begin
  if not CheckState then
    Exit;
  strName := Trim(tv1.Selected.Text);
  //idftp_Client.DirectoryListing.Items[lst_ServerList.ItemIndex].FileName;

  //�ж�ѡ�����Ŀ¼�����ļ���Ŀ¼����Ϊ�¼����ļ�����Ϊͬ����
  isDir:=isDirectory(idftp_Client,AnsiToUtf8(getNodePath(tv1.Selected.Parent)),strName);
  if isDir then
    idftp_Client.ChangeDir(AnsiToUtf8(getNodePath(tv1.Selected)));

  if InputQuery('�½�Ŀ¼','�ļ�������',S) and (Trim(S) <> '') then
  begin
    idftp_Client.MakeDir(AnsiToUtf8(S));
    Self.ChageDir(Utf8ToAnsi(idftp_Client.RetrieveCurrentDir));
  end;
  Self.FreshTree(orginDir);
end;
{-------------------------------------------------------------------------------
 Description: �ϴ�Ŀ¼��ť
-------------------------------------------------------------------------------}
procedure TForm1.btn_UploadDirectoryClick(Sender: TObject);
  function DoUploadDir(idftp:TIdFTP;sDirName:String;sToDirName:String):Boolean;
  var
    hFindFile:Cardinal;
    tfile:String;
    sCurDir:String[255];
    FindFileData:WIN32_FIND_DATA;
  begin
    //�ȱ��浱ǰĿ¼
    sCurDir:=GetCurrentDir;
    ChDir(sDirName);
    idFTP.ChangeDir(AnsiToUtf8(sToDirName));
    hFindFile:=FindFirstFile( '*.* ',FindFileData);
    Application.ProcessMessages;
    if hFindFile<>INVALID_HANDLE_VALUE then
    begin
      repeat
        tfile:=FindFileData.cFileName;
        if (tfile= '.') or (tfile= '..') then
              Continue;
        if FindFileData.dwFileAttributes=FILE_ATTRIBUTE_DIRECTORY then
        begin
          try
            IdFTP.MakeDir(AnsiToUtf8(tfile));
            mmo_Log.Lines.Add('�½��ļ��У�' + tfile);
          except
          end;
          DoUploadDir(idftp,sDirName+ '\'+tfile,tfile);
          idftp.ChangeDir('..');
          Application.ProcessMessages;
        end
        else
        begin
          IdFTP.Put(tfile, AnsiToUtf8(tfile));
          mmo_Log.Lines.Add('�ϴ��ļ���' + tfile);
          Application.ProcessMessages;
        end;
      until   FindNextFile(hFindFile,FindFileData)=false;
    end
    else
    begin
      ChDir(sCurDir);
      result:=false;
      exit;
    end;
    //�ص�ԭ����Ŀ¼��
    ChDir(sCurDir);
    result:=true;
  end;
var
  strPath,strToPath,temp: string;
begin
  if not CheckState then
    Exit;
  if SelectDirectory('ѡ���ϴ�Ŀ¼','',strPath) then
  begin
    temp := Trim(Utf8ToAnsi(idftp_Client.RetrieveCurrentDir));
    strToPath := temp;
    if Length(strToPath) = 1 then
      strToPath := strToPath +  ExtractFileName(strPath)
    else
      strToPath := strToPath + '/' +  ExtractFileName(strPath);
    try
      idftp_Client.MakeDir(AnsiToUtf8(ExtractFileName(strPath)));
    except
    end;
    DoUploadDir(idftp_Client,strPath,strToPath);
    Self.ChageDir(temp);
  end;
  Self.FreshTree(orginDir);
end;


procedure TForm1.tv1Expanding(Sender: TObject; Node: TTreeNode;
  var AllowExpansion: Boolean);
var
  ItemCount,Index,icount,ipostion:integer;
  Itemstr,strPath:string;
  isDir:Boolean;
  curNode:TTreeNode;
  LS: TStringList;
  i: Integer;
begin
   if Node.Count = 0 then
   begin
     icount:=0;
     strPath:=getNodePath(Node);

     LS := TStringList.Create;
     try
      idftp_Client.ChangeDir(AnsiToUtf8(strPath));
      idftp_Client.TransferType := ftASCII;
      nodePath := Utf8ToAnsi(idftp_Client.RetrieveCurrentDir);
      idftp_Client.List(LS);
      LS.Clear;
      with idftp_Client.DirectoryListing do
      begin
        for i := 0 to Count - 1 do
        begin
          if (Trim(Items[i].FileName)<>'.') and (Trim(Items[i].FileName) <> '..') then
          begin
            curNode:=tv1.Items.AddChild(node,Utf8ToAnsi(Trim(Items[i].FileName)));
            curNode.HasChildren :=(Items[i].ItemType = ditDirectory);
            curNode.ImageIndex := 0;
            curNode.SelectedIndex := 1;
            icount:=icount+1;
          end;
        end;
        if icount=0 then
          node.HasChildren:=False;
      end;
      finally
        LS.Free;
      end;
   end;
end;

procedure TForm1.btn_FreshClick(Sender: TObject);
begin
  Self.FreshTree(orginDir);
end;

procedure TForm1.tv1Change(Sender: TObject; Node: TTreeNode);
var
  strPath:string;
begin
  strPath:=getNodePath(Node);
  nodePath:=strPath;
  Self.ChageDir(strPath);
  Self.Caption:=formName + '��ǰĿ¼:['+nodePath+']';
  
  btn_Download.Enabled:=True;
end;

end.
