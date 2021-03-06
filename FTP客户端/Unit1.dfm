object Form1: TForm1
  Left = 602
  Top = 154
  BorderIcons = [biSystemMenu, biMinimize]
  BorderStyle = bsSingle
  Caption = 'Form1'
  ClientHeight = 508
  ClientWidth = 702
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = #23435#20307
  Font.Style = []
  OldCreateOrder = False
  OnCreate = FormCreate
  PixelsPerInch = 96
  TextHeight = 12
  object lbl1: TLabel
    Left = 8
    Top = 21
    Width = 72
    Height = 12
    Caption = #26381#21153#22120#22320#22336#65306
  end
  object lbl2: TLabel
    Left = 213
    Top = 21
    Width = 48
    Height = 12
    Caption = #29992#25143#21517#65306
  end
  object lbl3: TLabel
    Left = 395
    Top = 21
    Width = 36
    Height = 12
    Caption = #23494#30721#65306
  end
  object edt_ServerAddress: TEdit
    Left = 86
    Top = 17
    Width = 121
    Height = 20
    ImeName = #20013#25991'('#31616#20307') - '#25628#29399#25340#38899#36755#20837#27861
    TabOrder = 0
    Text = '127.0.0.1'
  end
  object edt_UserName: TEdit
    Left = 267
    Top = 17
    Width = 121
    Height = 20
    ImeName = #20013#25991'('#31616#20307') - '#25628#29399#25340#38899#36755#20837#27861
    TabOrder = 1
    Text = '12'
  end
  object edt_UserPassword: TEdit
    Left = 437
    Top = 17
    Width = 145
    Height = 20
    ImeName = #20013#25991'('#31616#20307') - '#25628#29399#25340#38899#36755#20837#27861
    TabOrder = 2
    Text = '12'
  end
  object btn_Connect: TButton
    Left = 604
    Top = 15
    Width = 81
    Height = 25
    Caption = #36830#25509
    TabOrder = 3
    OnClick = btn_ConnectClick
  end
  object mmo_Log: TMemo
    Left = 6
    Top = 336
    Width = 689
    Height = 161
    ImeName = #20013#25991'('#31616#20307') - '#25628#29399#25340#38899#36755#20837#27861
    ReadOnly = True
    ScrollBars = ssBoth
    TabOrder = 4
  end
  object btn_Download: TButton
    Left = 10
    Top = 298
    Width = 83
    Height = 25
    Caption = #19979#36733
    TabOrder = 5
    OnClick = btn_DownloadClick
  end
  object btn_Upload: TButton
    Left = 107
    Top = 298
    Width = 83
    Height = 25
    Caption = #19978#20256
    TabOrder = 6
    OnClick = btn_UploadClick
  end
  object btn_Delete: TButton
    Left = 205
    Top = 298
    Width = 83
    Height = 25
    Caption = #21024#38500
    TabOrder = 7
    OnClick = btn_DeleteClick
  end
  object btn_MKDirectory: TButton
    Left = 602
    Top = 298
    Width = 83
    Height = 25
    Caption = #26032#24314#30446#24405
    TabOrder = 9
    OnClick = btn_MKDirectoryClick
  end
  object btn_Abort: TButton
    Left = 302
    Top = 298
    Width = 83
    Height = 25
    Caption = #21462#28040
    TabOrder = 8
    OnClick = btn_AbortClick
  end
  object btn_UploadDirectory: TButton
    Left = 399
    Top = 298
    Width = 83
    Height = 25
    Caption = #19978#20256#30446#24405
    TabOrder = 11
    OnClick = btn_UploadDirectoryClick
  end
  object tv1: TTreeView
    Left = 8
    Top = 56
    Width = 289
    Height = 233
    Indent = 19
    TabOrder = 12
    OnChange = tv1Change
    OnExpanding = tv1Expanding
  end
  object btn_Fresh: TButton
    Left = 497
    Top = 298
    Width = 83
    Height = 25
    Caption = #21047#26032#30446#24405
    TabOrder = 13
    OnClick = btn_FreshClick
  end
  object stat1: TStatusBar
    Left = 0
    Top = 489
    Width = 702
    Height = 19
    Panels = <
      item
        Text = #20256#36755#29366#24577
        Width = 351
      end
      item
        Width = 50
      end>
    SimplePanel = False
  end
  object pb_ShowWorking: TProgressBar
    Left = 352
    Top = 491
    Width = 350
    Height = 17
    Min = 0
    Max = 100
    TabOrder = 10
  end
  object dbgrd1: TDBGrid
    Left = 304
    Top = 56
    Width = 385
    Height = 233
    DataSource = ds2
    ImeName = #20013#25991'('#31616#20307') - '#25628#29399#25340#38899#36755#20837#27861
    ReadOnly = True
    TabOrder = 15
    TitleFont.Charset = DEFAULT_CHARSET
    TitleFont.Color = clWindowText
    TitleFont.Height = -12
    TitleFont.Name = #23435#20307
    TitleFont.Style = []
  end
  object idftp_Client: TIdFTP
    MaxLineAction = maException
    OnWork = idftp_ClientWork
    OnWorkBegin = idftp_ClientWorkBegin
    OnWorkEnd = idftp_ClientWorkEnd
    ProxySettings.ProxyType = fpcmNone
    ProxySettings.Port = 0
    Left = 88
    Top = 144
  end
  object dlgSave_File: TSaveDialog
    Left = 88
    Top = 88
  end
  object idntfrz1: TIdAntiFreeze
    Left = 136
    Top = 96
  end
  object dlgOpen_File: TOpenDialog
    Left = 144
    Top = 144
  end
  object ds1: TClientDataSet
    Aggregates = <>
    Params = <>
    Left = 432
    Top = 136
  end
  object ds2: TDataSource
    DataSet = ds1
    Left = 488
    Top = 136
  end
end
