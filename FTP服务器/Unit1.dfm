object Form1: TForm1
  Left = 206
  Top = 150
  Width = 445
  Height = 327
  Caption = 'Form1'
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = #23435#20307
  Font.Style = []
  OldCreateOrder = False
  PixelsPerInch = 96
  TextHeight = 12
  object lbl1: TLabel
    Left = 24
    Top = 56
    Width = 60
    Height = 12
    Caption = #35775#38382#30446#24405#65306
  end
  object lbl2: TLabel
    Left = 264
    Top = 56
    Width = 36
    Height = 12
    Caption = #31471#21475#65306
  end
  object lbl3: TLabel
    Left = 40
    Top = 83
    Width = 48
    Height = 12
    Caption = #29992#25143#21517#65306
  end
  object lbl4: TLabel
    Left = 264
    Top = 84
    Width = 36
    Height = 12
    Caption = #23494#30721#65306
  end
  object btn1: TButton
    Left = 88
    Top = 112
    Width = 75
    Height = 25
    Caption = #24320#21551#26381#21153
    TabOrder = 0
    OnClick = btn1Click
  end
  object btn2: TButton
    Left = 240
    Top = 112
    Width = 75
    Height = 25
    Caption = #20851#38381#26381#21153
    TabOrder = 1
    OnClick = btn2Click
  end
  object edt_BorrowDirectory: TEdit
    Left = 96
    Top = 48
    Width = 121
    Height = 20
    TabOrder = 2
    Text = 'E:\CVS'
  end
  object mmo1: TMemo
    Left = 16
    Top = 146
    Width = 401
    Height = 129
    ScrollBars = ssVertical
    TabOrder = 3
  end
  object edt_BorrowPort: TEdit
    Left = 304
    Top = 48
    Width = 89
    Height = 20
    TabOrder = 4
    Text = '21'
  end
  object edt_UserName: TEdit
    Left = 96
    Top = 80
    Width = 121
    Height = 20
    TabOrder = 5
    Text = '12'
  end
  object edt_UserPassword: TEdit
    Left = 304
    Top = 80
    Width = 89
    Height = 20
    TabOrder = 6
    Text = '12'
  end
end
