object AddTextsView: TAddTextsView
  Left = 0
  Top = 0
  Caption = 'Add Texts'
  ClientHeight = 314
  ClientWidth = 688
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  Position = poOwnerFormCenter
  TextHeight = 13
  object CommandButtonsPanel: TPanel
    Left = 0
    Top = 280
    Width = 688
    Height = 34
    Align = alBottom
    BevelOuter = bvNone
    TabOrder = 0
    ExplicitTop = 29
    ExplicitWidth = 458
    object CancelButton: TButton
      AlignWithMargins = True
      Left = 610
      Top = 3
      Width = 75
      Height = 28
      Align = alRight
      Cancel = True
      Caption = 'Cancel'
      DoubleBuffered = True
      ModalResult = 2
      ParentDoubleBuffered = False
      TabOrder = 0
      ExplicitLeft = 380
    end
    object OKButton: TButton
      AlignWithMargins = True
      Left = 529
      Top = 3
      Width = 75
      Height = 28
      Align = alRight
      Caption = 'OK'
      Default = True
      DoubleBuffered = True
      ModalResult = 1
      ParentDoubleBuffered = False
      TabOrder = 1
      ExplicitLeft = 299
    end
    object ToggleButton: TButton
      AlignWithMargins = True
      Left = 3
      Top = 3
      Width = 122
      Height = 28
      Align = alLeft
      Cancel = True
      Caption = 'Toggle Selected'
      DoubleBuffered = True
      ParentDoubleBuffered = False
      TabOrder = 2
      OnClick = ToggleButtonClick
    end
  end
  object TextsCheckListBox: TCheckListBox
    AlignWithMargins = True
    Left = 3
    Top = 3
    Width = 682
    Height = 274
    Align = alClient
    ItemHeight = 13
    TabOrder = 1
    OnClickCheck = TextsCheckListBoxClickCheck
  end
end
