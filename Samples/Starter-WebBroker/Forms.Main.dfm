object MainForm: TMainForm
  Left = 271
  Top = 114
  BorderIcons = [biSystemMenu, biMinimize]
  BorderStyle = bsSingle
  Caption = 'Prometheus WebBroker Demo'
  ClientHeight = 227
  ClientWidth = 333
  Color = clBtnFace
  Font.Charset = ANSI_CHARSET
  Font.Color = clWindowText
  Font.Height = -13
  Font.Name = 'Segoe UI'
  Font.Style = []
  ShowHint = True
  TextHeight = 17
  object PortLabel: TLabel
    Left = 192
    Top = 17
    Width = 24
    Height = 17
    Caption = 'Port'
  end
  object StartServerButton: TButton
    Left = 8
    Top = 16
    Width = 156
    Height = 49
    Action = StartServerAction
    Default = True
    TabOrder = 0
  end
  object StopServerButton: TButton
    Left = 8
    Top = 72
    Width = 156
    Height = 49
    Action = StopServerAction
    Cancel = True
    Default = True
    TabOrder = 1
  end
  object PortEdit: TEdit
    Left = 192
    Top = 40
    Width = 121
    Height = 25
    TabOrder = 2
    Text = '8081'
  end
  object OpenBrowserButton: TButton
    Left = 168
    Top = 168
    Width = 156
    Height = 49
    Action = OpenBrowserAction
    TabOrder = 3
  end
  object MainActionList: TActionList
    OnUpdate = MainActionListUpdate
    Left = 40
    Top = 168
    object StartServerAction: TAction
      Caption = '&Start Server'
      OnExecute = StartServerActionExecute
    end
    object StopServerAction: TAction
      Caption = 'Sto&p Server'
      OnExecute = StopServerActionExecute
    end
    object OpenBrowserAction: TAction
      Caption = '&Open Browser'
      OnExecute = OpenBrowserActionExecute
    end
  end
end
