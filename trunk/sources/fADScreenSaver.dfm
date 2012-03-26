object FormADScreenSaver: TFormADScreenSaver
  Left = 0
  Top = 0
  BorderStyle = bsNone
  Caption = 'FormADScreenSaver'
  ClientHeight = 585
  ClientWidth = 804
  Color = clBlack
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  WindowState = wsMaximized
  OnMouseDown = FormMouseDown
  PixelsPerInch = 96
  TextHeight = 13
  object LAirportDisplay: TLabel
    Left = 216
    Top = 240
    Width = 477
    Height = 78
    Caption = 'Airport Display'
    Font.Charset = ANSI_CHARSET
    Font.Color = clGray
    Font.Height = -64
    Font.Name = 'Verdana'
    Font.Style = []
    ParentFont = False
  end
  object TimerScreenSaver: TTimer
    Interval = 30000
    OnTimer = TimerScreenSaverTimer
    Left = 560
    Top = 152
  end
end
