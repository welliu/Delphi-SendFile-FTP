unit Unit1;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, FTPServer;

type
  TForm1 = class(TForm)
    btn1: TButton;
    btn2: TButton;
    edt_BorrowDirectory: TEdit;
    lbl1: TLabel;
    mmo1: TMemo;
    lbl2: TLabel;
    edt_BorrowPort: TEdit;
    lbl3: TLabel;
    edt_UserName: TEdit;
    lbl4: TLabel;
    edt_UserPassword: TEdit;
    procedure btn1Click(Sender: TObject);
    procedure btn2Click(Sender: TObject);
    procedure TFTPServer1FtpNotifyEvent(ADatetime: TDateTime;AUserIP, AEventMessage: string);
  private
    FFtpServer: TFTPServer;
  public
    { Public declarations }
  end;

var
  Form1: TForm1;

implementation



{$R *.dfm}

procedure TForm1.btn1Click(Sender: TObject);
begin
  if not Assigned(FFtpServer) then
  begin
    FFtpServer := TFTPServer.Create;
    FFtpServer.UserName := Trim(edt_UserName.Text);
    FFtpServer.UserPassword := Trim(edt_UserPassword.Text);
    FFtpServer.BorrowDirectory := Trim(edt_BorrowDirectory.Text);
    FFtpServer.BorrowPort := StrToInt(Trim(edt_BorrowPort.Text));
    FFtpServer.OnFtpNotifyEvent := TFTPServer1FtpNotifyEvent;
    FFtpServer.Run;
    mmo1.Lines.Add(DateTimeToStr(Now) + #32 +'FTP服务器已开启，本机IP地址：' + FFtpServer.GetBindingIP);
  end;
end;

procedure TForm1.btn2Click(Sender: TObject);
begin
  if Assigned(FFtpServer) then
  begin
    FFtpServer.Stop;
    FreeAndNil(FFtpServer);
    mmo1.Lines.Add(DateTimeToStr(Now) + #32 +'FTP服务器已关闭');
  end;
end;

procedure TForm1.TFTPServer1FtpNotifyEvent(ADatetime: TDateTime;AUserIP, AEventMessage: string);
begin
  mmo1.Lines.Add(DateTimeToStr(ADatetime) + #32 + AUserIP + #32 + AEventMessage);
  SendMessage(mmo1.Handle,WM_VSCROLL,SB_PAGEDOWN,0);
end;
end.
