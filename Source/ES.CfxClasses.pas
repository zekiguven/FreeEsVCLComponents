{******************************************************************************}
{                          FreeEsVclComponents/Core                            }
{                           ErrorSoft(c) 2011-2016                             }
{                                                                              }
{           errorsoft@mail.ru | vk.com/errorsoft | github.com/errorcalc        }
{     errorsoft@protonmail.ch | habrahabr.ru/user/error1024 | errorsoft.org    }
{                                                                              }
{ Open this on github: github.com/errorcalc/FreeEsVclComponents                }
{                                                                              }
{ �� ������ �������� ���������� VCL/FMX ���������� �� �����                    }
{ You can order the development of VCL/FMX components to order                 }
{******************************************************************************}
unit Es.CfxClasses;

interface

{$IF CompilerVersion >= 23}
{$DEFINE VER230UP}
{$IFEND}
{$IF CompilerVersion >= 24}
{$DEFINE VER240UP}
{$IFEND}

uses
  Windows, Classes, Controls, Graphics, PngImage,
  ES.ExGraphics, Messages, Generics.Collections, Dialogs, StdCtrls;

type
//  {$scopedenums on}
  TVertLayout = (vlTop, vlCenter, vlBottom);
  THorzLayout = (hlLeft, hlCenter, hlRight);
  TImageAlign = (iaTopLeft, iaTopRight, iaBottomRight, iaBottomLeft, iaCenter, iaLeft, iaRight, iaTop, iaBottom);
  //                -  size+color size  size    win        win
  TExFrameStyle = (fsNone, fsFlat, fsUp, fsDown, fsLowered, fsRaised, fsBump, fsEtched, fsChess,
    fsLoweredColor, fsRaisedColor, fsBumpColor, fsEtchedColor, fsChessColor);
  {$ifndef VER230UP}
  TFrameStyle = fsNone..fsChess;
  {$else}
  TFrameStyle = TExFrameStyle.fsNone..TExFrameStyle.fsChess;
  {$endif}
  TFrameWidth = 1..MaxInt;
//  {$scopedenums off}

  TImageMargins = class(TMargins)
  private
    function GetRect: TRect; inline;
  protected
    class procedure InitDefaults(Margins: TMargins); override;
  public
    property Rect: TRect read GetRect;
  published
    property Left default 0;
    property Top default 0;
    property Right default 0;
    property Bottom default 0;
  end;

  TStyleMargins = class(TImageMargins)
  published
    property Left nodefault;
    property Top nodefault;
    property Right nodefault;
    property Bottom nodefault;
  end;

  TStylePadding = class(TPadding)
  published
    property Left nodefault;
    property Right nodefault;
    property Top nodefault;
    property Bottom nodefault;
  end;

  /// <summary> ONLY INTERNAL USE! </summary>
  TNinePatchObject = class
  private
    FBitmap: TBitmap;
    FOverlay: TBitmap;
    FMargins: TImageMargins;
    FOnNeedRepaint: TNotifyEvent;
    FOverlayAlign: TImageAlign;
    FOverlaySpace: Boolean;
    FOverlayMargins: TImageMargins;
    FContentSpace: Boolean;
    FControl: TControl;
    // FOnMarginsChange: TNotifyEvent;
    procedure BoundsChange(Sender: TObject);
    procedure SetMargins(const Value: TImageMargins);
    procedure SetBitMap(const Value: TBitmap);
    procedure SetOverlay(const Value: TBitmap);
    procedure SetOverlayAlign(const Value: TImageAlign);
    procedure SetOverlaySpace(const Value: Boolean);
    procedure SetOverlayMargins(const Value: TImageMargins);
    procedure SetContentSpace(const Value: Boolean);
    procedure SetControl(const Value: TControl);
  protected
    ContentRect: TRect;
    property ContentSpace: Boolean read FContentSpace write SetContentSpace;
    procedure NeedRepaint;
  public
    property Control: TControl read FControl write SetControl;
    property Bitmap: TBitmap read FBitmap write SetBitMap;
    property Overlay: TBitmap read FOverlay write SetOverlay;
    property OverlayAlign: TImageAlign read FOverlayAlign write SetOverlayAlign;
    property OverlayMargins: TImageMargins read FOverlayMargins write SetOverlayMargins;
    property OverlaySpace: Boolean read FOverlaySpace write SetOverlaySpace;
    property Margins: TImageMargins read FMargins write SetMargins;
    property OnNeedRepaint: TNotifyEvent read FOnNeedRepaint write FOnNeedRepaint;
    // property OnMarginsChange: TNotifyEvent read FOnMarginsChange write FOnMarginsChange;
    procedure Draw(Canvas: TCanvas; Rect: TRect; Opacity: Byte); virtual;
    procedure AssignImage(G: TGraphic);
    procedure AssignOverlay(G: TGraphic);
    constructor Create; virtual;
    destructor Destroy; override;
  end;

  /// <summary> ONLY INTERNAL USE! </summary>
  TTextNinePatchObject = class(TNinePatchObject)
  private
    FShowCaption: Boolean;
    FTextAlignment: TAlignment;
    FTextDistance: Integer;
    FTextMultiline: Boolean;
    FTextLayout: TVertLayout;
    procedure SetShowCaption(const Value: Boolean);
    procedure SetTextAlignment(const Value: TAlignment);
    procedure SetTextDistance(const Value: Integer);
    procedure SetTextMultiline(const Value: Boolean);
    procedure SetTextLayout(const Value: TVertLayout);
  public
    constructor Create; override;
    property ContentSpace;
    property ShowCaption: Boolean read FShowCaption write SetShowCaption;
    property TextAlignment: TAlignment read FTextAlignment write SetTextAlignment;
    property TextLayout: TVertLayout read FTextLayout write SetTextLayout;
    property TextDistance: Integer read FTextDistance write SetTextDistance;
    property TextMultiline: Boolean read FTextMultiline write SetTextMultiline;
    procedure Draw(Canvas: TCanvas; Rect: TRect; Text: String; Opacity: Byte); reintroduce; overload;
  end;

  /// <summary> Improved version TPngImage which causes OnChange </summary>
  TFixPngImage = class(TPngImage)
  protected
    procedure SetWidth(Value: Integer); override;
    procedure SetHeight(Value: Integer); override;
  public
    procedure LoadFromFile(const Filename: String); override;
    procedure LoadFromStream(Stream: TStream); override;
    procedure LoadFromClipboardFormat(AFormat: Word; AData: THandle; APalette: HPalette); override;
    procedure Assign(Source: TPersistent); override;
  end;

  /// <summary> ONLY INTERNAL USE! </summary>
  TStyleNinePatch = class(TPersistent)
  private
    ImageList: TList<TPngImage>;
    BitmapList: TList<TBitmap>;
    FImageMargins: TStyleMargins;
    FOverlayAlign: TImageAlign;
    FOverlayMargins: TStyleMargins;
    FOnChange: TNotifyEvent;
    FControl: TControl;
    FStateCount: Integer;
    FIsDefaultValues: Boolean;
    FUpdateCount: Integer;
    FImageMode: TStretchMode;
    FIsDefaultImages: Boolean;
    procedure SetImageMargins(const Value: TStyleMargins);
    procedure SetOverlayAlign(const Value: TImageAlign);
    procedure SetOverlayMargins(const Value: TStyleMargins);
    function RequestImage(Index: Integer): TPngImage;
    procedure ImageChange(Sender: TObject);
    function GetBitmap(Index: Integer): TBitmap;
    function GetOverlayBitmap(Index: Integer): TBitmap;
    procedure SetImageMode(const Value: TStretchMode);
    procedure SetIsDefaultValues(const Value: Boolean);
    procedure SetIsDefaultImages(const Value: Boolean);
    //
    procedure ChangeNotify;
    procedure SetIsDefaultStyle(const Value: Boolean);
    function GetIsDefaultStyle: Boolean;
  protected
    procedure Change;
    procedure ChangeMargins(Sender: TObject);// use for XXXMargins.OnChange
    function IsStyleStored: Boolean;
    // get/set
    property StateCount: Integer read FStateCount;
    function RequestBitmap(Index: Integer): TBitmap;
    function RequestOverlayBitmap(Index: Integer): TBitmap;
    function GetSuitedBitmap(Index: Integer): TBitmap;
    function GetSuitedOverlayBitmap(Index: Integer): TBitmap;
    procedure AssignTo(Dest: TPersistent); override;
    //
    procedure DoDraw(Canvas: TCanvas; Rect: TRect; Bitmap: TBitmap;
      OverlayBitmap: TBitmap; Mode: TStretchMode; Opacity: Byte = 255); virtual;
    //----------------------------------------------------------------------------------------------
    // Indexed properties:
    function GetImage(const Index: Integer): TPngImage;
    procedure SetImage(const Index: Integer; const Image: TPngImage);
    function GetOverlay(const Index: Integer): TPngImage;
    procedure SetOverlay(const Index: Integer; const Image: TPngImage);
    // PLEASE REALIZE THIS:
    function GetStateCount: Integer; dynamic; abstract;
    function GetStylePrefix: string; dynamic;// if use IsDefaultStyle or LoadDefaultStyle
    // to published
    property ImageMargins: TStyleMargins read FImageMargins write SetImageMargins stored IsStyleStored;
    property ImageMode: TStretchMode read FImageMode write SetImageMode stored IsStyleStored default TStretchMode.smNormal;
    property OverlayAlign: TImageAlign read FOverlayAlign write SetOverlayAlign stored IsStyleStored;
    property OverlayMargins: TStyleMargins read FOverlayMargins write SetOverlayMargins stored IsStyleStored;
    //----------------------------------------------------------------------------------------------
  public
    constructor Create; virtual;
    destructor Destroy; override;
    procedure Draw(Canvas: TCanvas; Rect: TRect; StateIndex: Integer; Opacity: Byte = 255); virtual;
    procedure Clear; dynamic;
    procedure UpdateImages; dynamic;
    //
    procedure AssignDefaultValues; dynamic;
    procedure AssignDefaultImages; dynamic;
    procedure AssignDefaultStyle;
    //
    procedure BeginUpdate;
    procedure EndUpdate;
    function IsPresented(Index: Integer): Boolean;
    //
    property Control: TControl read FControl write FControl;
    property Bitmap[Index: Integer]: TBitmap read GetBitmap;
    property OverlayBitmap[Index: Integer]: TBitmap read GetOverlayBitmap;
    //
    property OnChange: TNotifyEvent read FOnChange write FOnChange;
    //
    /// <summary>  This property is deprecated, please use IsDefaultValues/IsDefaultImages </summary>
    property IsDefaultStyle: Boolean read GetIsDefaultStyle write SetIsDefaultStyle stored False;
  published
    // default res style
    property IsDefaultValues: Boolean read FIsDefaultValues write SetIsDefaultValues stored False default True;
    property IsDefaultImages: Boolean read FIsDefaultImages write SetIsDefaultImages default True;
  end;

  // TODO: need rewrite for use CreateTimerQueueTimer...
  /// <summary> Improved timer </summary>
  TEsTimer = class
  private
    HidenWindow: HWND;
    FOnTimer: TNotifyEvent;
    FInterval: Cardinal;
    FEnabled: Boolean;
    procedure SetInterval(const Value: Cardinal);
    procedure SetOnTimer(const Value: TNotifyEvent);
    procedure UpdateTimer;
    procedure WndProc(var Message: TMessage);
    procedure SetEnabled(const Value: Boolean);
  protected
    procedure DoTimer; dynamic;
  public
    procedure Start;
    procedure Stop;
    procedure Reset;
    constructor Create(Interval: Cardinal = 1000; OnTimer: TNotifyEvent = nil; Enabled: Boolean = False);
    destructor Destroy; override;
    property Interval: Cardinal read FInterval write SetInterval default 1000;
    property Enabled: Boolean read FEnabled write SetEnabled default False;
    property OnTimer: TNotifyEvent read FOnTimer write SetOnTimer;
  end;

  // Internal use only
  TAnimationMode = (amLinear, amCubic);

  // Internal use only
  TCustomAnimation = class
  private
    FMode: TAnimationMode;
    FDuration: Cardinal;
    FOnProcess: TNotifyEvent;
    FOnFinish: TNotifyEvent;
    Timer: TEsTimer;
    StartTime: Cardinal;
    FNormalizedTime: Single;
    FReverseMode: Boolean;// 0..1
    procedure SetDuration(const Value: Cardinal);
    procedure SetMode(const Value: TAnimationMode);
    procedure SetReverseMode(const Value: Boolean);
  protected
    procedure TimerProc(Sender: TObject); virtual;
    procedure Process; virtual;
  public
    procedure Start; dynamic;
    procedure Stop; dynamic;
    constructor Create; dynamic;
    destructor Destroy; override;
    property Duration: Cardinal read FDuration write SetDuration;
    property Mode: TAnimationMode read FMode write SetMode;
    property ReverseMode: Boolean read FReverseMode write SetReverseMode;
    function CurrentTime: Single; virtual;// 0..1
    property OnProcess: TNotifyEvent read FOnProcess write FOnProcess;
    property OnFinish: TNotifyEvent read FOnFinish write FOnFinish;
  end;

  // Internal use only
  TIntegerAnimation = class(TCustomAnimation)
  private
    FStartValue: Integer;
    FEndValue: Integer;
    function GetValue: Integer;
    procedure SetEndValue(const Value: Integer);
    procedure SetStartValue(const Value: Integer);
  public
    constructor Create; override;
    property StartValue: Integer read FStartValue write SetStartValue;
    property EndValue: Integer read FEndValue write SetEndValue;
    property Value: Integer read GetValue;
  end;

  function DrawFrame(Canvas: TCanvas; Rect: TRect; Style: TExFrameStyle; FrameWidth: TFrameWidth;
    FrameColor: TColor; TopColor, BottomColor: TColor; BaseColor: TColor = clNone): TRect;
  function GetFrameWidth(Style: TExFrameStyle; FrameWidth: TFrameWidth = 1): Integer;

implementation

uses
  Themes, ES.BaseControls, ES.Utils, SysUtils, TypInfo, GraphUtil, UIConsts;

{$REGION 'Delphi 2010/XE support'}
{$ifndef VER230UP}

type
  TRectHelper = record helper for TRect
  private
    function GetHeight: Integer;
    function GetWidth: Integer;
    procedure SetHeight(const Value: Integer);
    procedure SetWidth(const Value: Integer);
  public
    procedure Offset(const DX, DY: Integer); overload;
    procedure Offset(const Point: TPoint); overload;
    procedure Inflate(const DX, DY: Integer); overload;
  published
    property Width: Integer read GetWidth write SetWidth;
    property Height: Integer read GetHeight write SetHeight;
  end;

  TPointHelper = record helper for TPoint
  public
    procedure Offset(const DX, DY : Integer); overload;
    procedure Offset(const Point: TPoint); overload;
  end;

{ TPointHelper }

procedure TPointHelper.Offset(const DX, DY: Integer);
begin
  Inc(Self.X, DX);
  Inc(Self.Y, DY);
end;

procedure TPointHelper.Offset(const Point: TPoint);
begin
  Inc(Self.X, Point.X);
  Inc(Self.Y, Point.Y);
end;

{ TRectHelper }

function TRectHelper.GetHeight: Integer;
begin
  Result := Self.Bottom - Self.Top;
end;

function TRectHelper.GetWidth: Integer;
begin
  Result := Self.Right - Self.Left;
end;

procedure TRectHelper.Inflate(const DX, DY: Integer);
begin
  Self.Left := Self.Left - DX;
  Self.Top := Self.Top - DY;
  Self.Right := Self.Right + DX;
  Self.Bottom := Self.Bottom + DY;
end;

procedure TRectHelper.Offset(const DX, DY: Integer);
begin
  Self.Left := Self.Left + DX;
  Self.Top := Self.Top + DY;
  Self.Right := Self.Right + DX;
  Self.Bottom := Self.Bottom + DY;
end;

procedure TRectHelper.Offset(const Point: TPoint);
begin
  Self.Left := Self.Left + Point.X;
  Self.Top := Self.Top + Point.Y;
  Self.Right := Self.Right + Point.X;
  Self.Bottom := Self.Bottom + Point.Y;
end;

procedure TRectHelper.SetHeight(const Value: Integer);
begin
  Self.Bottom := Self.Top + Value;
end;

procedure TRectHelper.SetWidth(const Value: Integer);
begin
  Self.Right := Self.Left + Value;
end;

{$endif}
{$ENDREGION}

procedure Draw3dFrame(Handle: HDC; Rect: TRect; Width: Integer; TopColor, BottomColor: TColor);
  procedure OnePixel3d(Handle: HDC; Rect: TRect; TopColor, BottomColor: TColor);
  var
    SavePen: HPEN;
    Points: array [1..3] of TPoint;
  begin
    SavePen := SelectObject(Handle, GetStockObject(DC_PEN));

    try
      // TopLeft
      Points[1] := Point(Rect.Left, Rect.Bottom - 1);
      Points[2] := Point(Rect.Left, Rect.Top);
      Points[3] := Point(Rect.Right, Rect.Top);
      SetDCPenColor(Handle, TopColor);
      PolyLine(Handle, Points[1], 3);
      // BottomRight
      Points[1] := Point(Rect.Right, Rect.Top);
      Points[2] := Point(Rect.Right, Rect.Bottom);
      Points[3] := Point(Rect.Left - 1, Rect.Bottom);
      SetDCPenColor(Handle, BottomColor);
      PolyLine(Handle, Points[1], 3);
    finally
      if SavePen <> 0 then
        SelectObject(Handle, SavePen);
    end;
  end;
begin
  Dec(Rect.Right);
  Dec(Rect.Bottom);
  while Width > 0 do
  begin
    OnePixel3d(Handle, Rect, TopColor, BottomColor);
    Dec(Width);
    InflateRect(Rect, -1, -1);
  end;
end;

// todo: NOW THIS FUNCTION IS HELL, REFACTOR ME PLEASE!!!
function DrawFrame(Canvas: TCanvas; Rect: TRect; Style: TExFrameStyle; FrameWidth: TFrameWidth;
  FrameColor: TColor; TopColor, BottomColor: TColor; BaseColor: TColor = clNone): TRect;
var
  HighlightColor, ShadowColor: TColor;
  {$ifdef VER230UP}
  Elements: TElementEdges;
  {$endif}
begin
  {$ifdef VER230UP}
  if TStyleManager.IsCustomStyleActive then
  begin
    FrameColor := StyleServices.GetSystemColor(FrameColor);
    TopColor := StyleServices.GetSystemColor(TopColor);
    BottomColor := StyleServices.GetSystemColor(BottomColor);
  end else
  {$endif}
  begin
    FrameColor := ColorToRGB(FrameColor);
    TopColor := ColorToRGB(TopColor);
    BottomColor := ColorToRGB(BottomColor);
  end;

  if BaseColor <> clNone then
    {$ifdef VER230UP}
    if TStyleManager.IsCustomStyleActive then
      BaseColor := StyleServices.GetSystemColor(BaseColor)
    else
    {$endif}
      BaseColor := ColorToRgb(BaseColor);

  case Style of
    TExFrameStyle.fsNone:;

    TExFrameStyle.fsFlat:
    begin
      Canvas.DrawInsideFrame(Rect, FrameWidth, FrameColor);
      InflateRect(Rect, -FrameWidth, -FrameWidth);
    end;

    TExFrameStyle.fsUp, TExFrameStyle.fsDown:
    begin
      if Style = TExFrameStyle.fsUp then
        Draw3dFrame(Canvas.Handle, Rect, FrameWidth, TopColor, BottomColor)
      else
        Draw3dFrame(Canvas.Handle, Rect, FrameWidth, BottomColor, TopColor);

      InflateRect(Rect, -FrameWidth, -FrameWidth);
    end;

    TExFrameStyle.fsLowered, TExFrameStyle.fsRaised, TExFrameStyle.fsBump, TExFrameStyle.fsEtched,
    TExFrameStyle.fsChess, TExFrameStyle.fsLoweredColor, TExFrameStyle.fsRaisedColor,
    TExFrameStyle.fsBumpColor, TExFrameStyle.fsEtchedColor, TExFrameStyle.fsChessColor:
    begin
//      if Style in [TFrameStyle.fsLowered, TFrameStyle.fsRaised] and (BaseColor = clNone) then
//      begin
//        if Style = TFrameStyle.fsRaised then
//          DrawEdge(Canvas.Handle, Rect, EDGE_RAISED, BF_SOFT or BF_RECT or BF_ADJUST)
//        else
//          DrawEdge(Canvas.Handle, Rect, EDGE_SUNKEN, BF_SOFT or BF_RECT or BF_ADJUST);
//        InflateRect(Rect, -2, -2);
//      end else
//      begin
      {$ifdef VER230UP}
      if (TStyleManager.IsCustomStyleActive) and
        (Style in [TExFrameStyle.fsLowered, TExFrameStyle.fsRaised, TExFrameStyle.fsBump, TExFrameStyle.fsEtched]) then
      begin
        case Style of
          fsLowered: Elements := [eeSunken];
          fsRaised: Elements := [eeRaised];
          fsBump: Elements := [eeBump];
          fsEtched: Elements := [eeEtched];
        end;
        DrawStyleEdge(Canvas.Handle, Rect, Elements, [efRect, efSoft]);

        InflateRect(Rect, -2, -2);
      end else
      {$endif}
      begin
        if (Style in [TExFrameStyle.fsLowered, TExFrameStyle.fsRaised, TExFrameStyle.fsBump,
          TExFrameStyle.fsEtched, TExFrameStyle.fsChess]) or (BaseColor = clNone) then
        begin
          {$ifdef VER230UP}
          if TStyleManager.IsCustomStyleActive then
            BaseColor := StyleServices.GetSystemColor(clBtnFace)
          else
          {$endif}
            BaseColor := ColorToRgb(clBtnFace)
        end;

        // out
        if Style in [TExFrameStyle.fsLowered, TExFrameStyle.fsRaised,
          TExFrameStyle.fsBump, TExFrameStyle.fsEtched, TExFrameStyle.fsChess]
        then
          HighlightColor := LuminanceColor(BaseColor, 255)
        else
          HighlightColor := LuminanceColor(BaseColor, 240);

        if not (Style in [TExFrameStyle.fsBump, TExFrameStyle.fsBumpColor,
          TExFrameStyle.fsEtched, TExFrameStyle.fsEtchedColor, TExFrameStyle.fsChess, TExFrameStyle.fsChessColor])
        then
          ShadowColor := LuminanceColor(BaseColor, 99)
        else
          ShadowColor := LuminanceColor(BaseColor, 151);

        if Style in [TExFrameStyle.fsChess, TExFrameStyle.fsChessColor] then
          Canvas.DrawChessFrame(Rect, ShadowColor, HighlightColor)
        else
        if Style in [TExFrameStyle.fsRaised, TExFrameStyle.fsRaisedColor,
          TExFrameStyle.fsBump, TExFrameStyle.fsBumpColor]
        then
          Draw3dFrame(Canvas.Handle, Rect, 1, HighlightColor, ShadowColor)
        else
          Draw3dFrame(Canvas.Handle, Rect, 1, ShadowColor, HighlightColor);
        InflateRect(Rect, -1, -1);

        // In
        if not (Style in [TExFrameStyle.fsBump, TExFrameStyle.fsBumpColor, TExFrameStyle.fsEtched,
        TExFrameStyle.fsEtchedColor, TExFrameStyle.fsChess, TExFrameStyle.fsChessColor]) then
        begin
          HighlightColor := LuminanceColor(BaseColor, 214);
          ShadowColor := LuminanceColor(BaseColor, 151);
        end;

        if Style in [TExFrameStyle.fsChess, TExFrameStyle.fsChessColor] then
          Canvas.DrawChessFrame(Rect, ShadowColor, HighlightColor)
        else
        if Style in [TExFrameStyle.fsRaised, TExFrameStyle.fsRaisedColor,
          TExFrameStyle.fsEtched, TExFrameStyle.fsEtchedColor]
        then
          Draw3dFrame(Canvas.Handle, Rect, 1, HighlightColor, ShadowColor)
        else
          Draw3dFrame(Canvas.Handle, Rect, 1, ShadowColor, HighlightColor);
        InflateRect(Rect, -1, -1);
      end;
    end;
  end;

  Result := Rect;
end;

function GetFrameWidth(Style: TExFrameStyle; FrameWidth: TFrameWidth = 1): Integer;
begin
  case Style of
    TExFrameStyle.fsNone: Result := 0;
    TExFrameStyle.fsFlat, TExFrameStyle.fsUp, TExFrameStyle.fsDown:
      Result := FrameWidth;
    else
      Result := 2;
  end;
end;

{ TImageMargins }

function TImageMargins.GetRect: TRect;
begin
  Result := Classes.Rect(Left, Top, Right, Bottom);
end;

class procedure TImageMargins.InitDefaults(Margins: TMargins);
begin
  // zero values on default
end;

{ TNinePatchObject }

procedure TNinePatchObject.BoundsChange(Sender: TObject);
begin
  if Assigned(OnNeedRepaint) then
    OnNeedRepaint(Self);
//  if Assigned(OnMarginsChange) then
//    OnMarginsChange(Self);
end;

constructor TNinePatchObject.Create;
begin
  inherited;
  FMargins := TImageMargins.Create(nil);
  FMargins.OnChange := BoundsChange;
  FOverlayMargins := TImageMargins.Create(nil);
  FOverlayMargins.OnChange := BoundsChange;
  FBitmap := TBitMap.Create;
  FBitmap.PixelFormat := pf32bit;
  FBitmap.AlphaFormat := afPremultiplied;
  FOverlay := TBitMap.Create;
  FOverlay.PixelFormat := pf32bit;
  FOverlay.AlphaFormat := afPremultiplied;
  FOverlayAlign := TImageAlign.iaTopLeft;
  // FContentSpace := True;
end;

destructor TNinePatchObject.Destroy;
begin
  FMargins.Free;
  FOverlayMargins.Free;
  FBitMap.Free;
  FOverlay.Free;
  inherited;
end;

procedure TNinePatchObject.Draw(Canvas: TCanvas; Rect: TRect; Opacity: byte);
var
  R: TRect;
begin
  Canvas.DrawNinePatch(Rect, FMargins.Rect, FBitmap, Opacity);

  // for painting child class
  if (Self.ClassType <> TNinePatchObject) and ContentSpace then
  begin
    ContentRect.Left := Rect.Left + FMargins.Left;
    ContentRect.Top := Rect.Top + FMargins.Top;
    ContentRect.Right := Rect.Right - FMargins.Right;
    ContentRect.Bottom := Rect.Bottom - FMargins.Bottom;
  end
  else
    ContentRect := Rect;

  if Assigned(FOverlay) then
  begin
    R := Rect;

    if FOverlaySpace then
    begin
      R.Left := R.Left + FMargins.Left;
      R.Top := R.Top + FMargins.Top;
      R.Right := R.Right - FMargins.Right;
      R.Bottom := R.Bottom - FMargins.Bottom;
    end;

    R.TopLeft.Offset(OverlayMargins.Rect.TopLeft);
    R.BottomRight.Offset(-OverlayMargins.Rect.Right, -OverlayMargins.Rect.Bottom);

    case FOverlayAlign of
      TImageAlign.iaTopLeft:
        Canvas.Draw(R.Left, R.Top, FOverlay, Opacity);

      TImageAlign.iaTopRight:
        Canvas.Draw(R.Right - FOverlay.Width, R.Top, FOverlay, Opacity);

      TImageAlign.iaBottomRight:
        Canvas.Draw(R.Right - FOverlay.Width, R.Bottom - FOverlay.Height, FOverlay, Opacity);

      TImageAlign.iaBottomLeft:
        Canvas.Draw(R.Left, R.Bottom - FOverlay.Height, FOverlay, Opacity);

      TImageAlign.iaCenter:
        Canvas.Draw(R.Left + R.Width div 2 - FOverlay.Width div 2, R.Top + R.Height div 2 - FOverlay.Height div 2, FOverlay, Opacity);

      TImageAlign.iaLeft:
        Canvas.Draw(R.Left, R.Top + R.Height div 2 - FOverlay.Height div 2, FOverlay, Opacity);

      TImageAlign.iaRight:
        Canvas.Draw(R.Left + R.Width - FOverlay.Width, R.Top + R.Height div 2 - FOverlay.Height div 2, FOverlay, Opacity);

      TImageAlign.iaTop:
        Canvas.Draw(R.Left + R.Width div 2 - FOverlay.Width div 2, R.Top, FOverlay, Opacity);

      TImageAlign.iaBottom:
        Canvas.Draw(R.Left + R.Width div 2 - FOverlay.Width div 2, R.Top + R.Height - FOverlay.Height, FOverlay, Opacity);
    end;

    case FOverlayAlign of
      TImageAlign.iaLeft: ContentRect.Left := R.Left + FOverlay.Width + OverlayMargins.Right;
      TImageAlign.iaRight: ContentRect.Right := R.Right - FOverlay.Width - OverlayMargins.Left;
      TImageAlign.iaTop: ContentRect.Top := R.Top + FOverlay.Height - OverlayMargins.Bottom;
      TImageAlign.iaBottom: ContentRect.Bottom := R.Bottom - FOverlay.Height - OverlayMargins.Top;
    end;
  end

  // Canvas.Brush.Color := Random(255*255*255);
  // Canvas.Rectangle(Canvas.ClipRect);
  // Canvas.Font.Color := clRed;
  // Canvas.TextOut(Canvas.ClipRect.Left+30, Canvas.ClipRect.Top,
  //   IntToStr(Canvas.ClipRect.Left)+','+IntToStr(Canvas.ClipRect.Top) + '-'+IntToStr(Canvas.ClipRect.Width)+','+IntToStr(Canvas.ClipRect.Height));
end;

procedure TNinePatchObject.NeedRepaint;
begin
  if Assigned(OnNeedRepaint) then
    OnNeedRepaint(Self);
end;

procedure TNinePatchObject.SetBitMap(const Value: TBitmap);
begin
  FBitmap.Assign(Value);
  NeedRepaint;
end;

procedure TNinePatchObject.SetContentSpace(const Value: Boolean);
begin
  if Value <> FContentSpace then
  begin
    FContentSpace := Value;
    NeedRepaint;
  end;
end;

procedure TNinePatchObject.SetControl(const Value: TControl);
begin
  FControl := Value;
  NeedRepaint;
end;

procedure TNinePatchObject.SetMargins(const Value: TImageMargins);
begin
  FMargins.Assign(Value);
end;

procedure TNinePatchObject.AssignImage(G: TGraphic);
begin
  FBitmap.SetSize(G.Width, G.Height);
  FBitmap.Canvas.Brush.Color := 0;
  FBitmap.Canvas.FillRect(Rect(0, 0, FBitmap.Width, FBitmap.Height));
  FBitmap.Canvas.Draw(0, 0, G);

  NeedRepaint;
end;

procedure TNinePatchObject.AssignOverlay(G: TGraphic);
begin
  FOverlay.SetSize(G.Width, G.Height);
  FOverlay.Canvas.Brush.Color := 0;
  FOverlay.Canvas.FillRect(Rect(0, 0, FOverlay.Width, FOverlay.Height));
  FOverlay.Canvas.Draw(0, 0, G);

  NeedRepaint;
end;

procedure TNinePatchObject.SetOverlay(const Value: TBitmap);
begin
  FOverlay.Assign(Value);
  NeedRepaint;
end;

procedure TNinePatchObject.SetOverlayAlign(const Value: TImageAlign);
begin
  if Value <> FOverlayAlign then
  begin
    FOverlayAlign := Value;
    if Assigned(FOverlay) then
      NeedRepaint;
  end;
end;

procedure TNinePatchObject.SetOverlayMargins(const Value: TImageMargins);
begin
  FOverlayMargins.Assign(Value);
  if Assigned(FOverlay) then
    NeedRepaint;
end;

procedure TNinePatchObject.SetOverlaySpace(const Value: Boolean);
begin
  if Value <> FOverlaySpace then
  begin
    FOverlaySpace := Value;
    NeedRepaint;
  end;
end;

{ TTextNinePatchObject }

constructor TTextNinePatchObject.Create;
begin
  inherited;
  FTextAlignment := taCenter;
  FTextLayout := TVertLayout.vlCenter;
  FTextDistance := 0;
  OverlaySpace := True;
  ContentSpace := True;
  OverlayAlign := TImageAlign.iaLeft;
end;

procedure TTextNinePatchObject.Draw(Canvas: TCanvas; Rect: TRect; Text: String; Opacity: byte);
{$ifdef VER230UP}
const
  D: array[Boolean] of TThemedTextLabel = (ttlTextLabelDisabled, ttlTextLabelNormal);//TStyleFont = (sfPanelTextDisabled, sfPanelTextNormal);
{$endif}
var
  R, Temp: TRect;
  Format: TTextFormat;
  procedure CalcRect(var Rect: TRect);
  var
    T: TTextFormat;
  begin
    Rect.Offset(-Rect.Top, -Rect.Left);
    T := Format;
    T := T + [tfCalcRect{$ifdef VER230UP}, tfWordEllipsis{$endif}];
    {$ifdef VER230UP}
    if IsStyledFontControl(Control) then
      Canvas.DrawThemeText(StyleServices.GetElementDetails(D[Control.Enabled]),
        Rect, Text, T)
    else
    {$endif}
      Canvas.TextRect(Rect, Text, T);
  end;
begin
  inherited Draw(Canvas, Rect, Opacity);

  if (not ShowCaption) or (Control = nil) then
    exit;

  //Canvas.FrameRect(ContentRect);

  R := ContentRect;

  if TextMultiline then
    Format := [tfWordBreak, tfEndEllipsis]
  else
    Format := [tfSingleLine];

  case TextAlignment of
    taLeftJustify:
      begin
        Format := Format + [];
        if TextMultiline then
          R.Inflate(-FTextDistance, -FTextDistance)
        else
          R.Left := R.Left + FTextDistance;
      end;
    taRightJustify:
      begin
        Format := Format + [tfRight];
        if TextMultiline then
          R.Inflate(-FTextDistance, -FTextDistance)
        else
          R.Right := R.Right - FTextDistance;
      end;
    taCenter:
      begin
        Format := Format + [tfCenter];
        //R := Rect;
        if TextMultiline then
        begin
          R := ContentRect;
          R.Inflate(-FTextDistance, -FTextDistance);
        end
        else
        if not Overlay.Empty then
        begin
//          case FOverlayAlign of
//            iaLeft: R.Left := ContentRect.Left;
//            iaRight: R.Right := ContentRect.Right;
//            iaTop: R.Top := ContentRect.Top;
//            iaBottom: R.Bottom := ContentRect.Bottom;
//          end;
          R.Inflate(-FTextDistance, 0);
        end else
        begin
          //R.Inflate(-FTextDistance, 0);
          R.Left := Rect.Left;
          R.Right := Rect.Right;
        end
      end;
  end;

  case TextLayout of
    TVertLayout.vlCenter:
      if not TextMultiline then
        Format := Format + [tfVerticalCenter]
      else
      begin
        Temp := R;
        CalcRect(Temp);
        R.Top := R.Top + (R.Height div 2) - (Temp.Height div 2);
        R.Height := Temp.Height;
      end;
    TVertLayout.vlBottom:
      if not TextMultiline then
      begin
        Format := Format + [tfBottom];
        R.Bottom := R.Bottom - FTextDistance;
      end else
      begin
        Temp := R;
        CalcRect(Temp);
        R.Top := R.Top + (R.Height - Temp.Height) - FTextDistance;
      end;
    TVertLayout.vlTop:
      if not TextMultiline then
      begin
        R.Top := R.Top + FTextDistance;
      end else
      begin
        Temp := R;
        CalcRect(Temp);
        R.Height := Temp.Height;
      end;
  end;

  if (Control <> nil)and(csDesigning in Control.ComponentState)and
     (Control is TEsCustomControl) then
  begin
    if TEsCustomControl(Control).IsDrawHelper then
      Canvas.DrawChessFrame(R, $009900, $F0FF40);
    //Canvas.DrawChessFrame(ContentRect, clRed, $C0C0C0);
  end;

  Canvas.Brush.Style := bsClear;
  {$ifdef VER230UP}
  if IsStyledFontControl(Control) then
    Canvas.DrawThemeText(StyleServices.GetElementDetails(D[Control.Enabled]),
      R, Text, Format)
  else
  {$endif}
    if Control.Enabled then
      Canvas.TextRect(R, Text, Format)
    else
    begin
      R.Offset(1, 1);
      Canvas.Font.Color := clBtnHighlight;
      Canvas.TextRect(R, Text, Format);
      R.Offset(-1, -1);
      Canvas.Font.Color := clBtnShadow;
      Canvas.TextRect(R, Text, Format);
    end;
  Canvas.Brush.Style := bsSolid;
end;

procedure TTextNinePatchObject.SetShowCaption(const Value: Boolean);
begin
  if FShowCaption <> Value then
  begin
    FShowCaption := Value;
    NeedRepaint;
  end;
end;

procedure TTextNinePatchObject.SetTextAlignment(const Value: TAlignment);
begin
  if FTextAlignment <> Value then
  begin
    FTextAlignment := Value;
    if FShowCaption then
       NeedRepaint;
  end;
end;

procedure TTextNinePatchObject.SetTextDistance(const Value: Integer);
begin
  if FTextDistance <> Value then
  begin
    FTextDistance := Value;
    if FShowCaption then
       NeedRepaint;
  end;
end;

procedure TTextNinePatchObject.SetTextLayout(const Value: TVertLayout);
begin
  if FTextLayout <> Value then
  begin
    FTextLayout := Value;
    if FShowCaption then
       NeedRepaint;
  end;
end;

procedure TTextNinePatchObject.SetTextMultiline(const Value: Boolean);
begin
  if FTextMultiline <> Value then
  begin
    FTextMultiline := Value;
    if FShowCaption then
       NeedRepaint;
  end;
end;

{ TStateNinePatch }

procedure TStyleNinePatch.AssignDefaultValues;
begin
  //FIsDefaultValues := True;
end;

procedure TStyleNinePatch.AssignTo(Dest: TPersistent);
begin
  if Dest is TStyleNinePatch then
  begin
    AssignPersistent(Dest, Self);
    //TStyleNinePatch(Dest).Change;
  end
  else
    inherited;
end;

procedure TStyleNinePatch.BeginUpdate;
begin
  Inc(FUpdateCount);
end;

procedure TStyleNinePatch.Change;
begin
  if FUpdateCount <> 0 then
    Exit;

  FIsDefaultValues := False;

  ChangeNotify;
end;

procedure TStyleNinePatch.ChangeMargins(Sender: TObject);
begin
  Change;
end;

procedure TStyleNinePatch.ChangeNotify;
begin
  if Assigned(FOnChange) and not((Control <> nil) and (csLoading in Control.ComponentState)) then
    FOnChange(Self);
end;

procedure TStyleNinePatch.Clear;
var
  I: Integer;
begin
  for I := 0 to ImageList.Count - 1 do
    if ImageList[I] <> nil then
    begin
      ImageList[I].Free;
      ImageList[I] := nil;
    end;

  for I := 0 to BitmapList.Count - 1 do
    if BitmapList[I] <> nil then
    begin
      BitmapList[I].Free;
      BitmapList[I] := nil;
    end;
end;

constructor TStyleNinePatch.Create;
begin
  inherited;
  ImageList := TList<TPngImage>.Create;
  BitmapList := TList<TBitmap>.Create;

  FStateCount := GetStateCount;

  ImageList.Count := FStateCount * 2;
  BitmapList.Count := FStateCount * 2;

  FImageMargins := TStyleMargins.Create(nil);
  FImageMargins.OnChange := ChangeMargins;
  FOverlayMargins := TStyleMargins.Create(nil);
  FOverlayMargins.OnChange := ChangeMargins;

  FIsDefaultValues := True;
  FIsDefaultImages := True;

  BeginUpdate;
  try
    AssignDefaultValues;
  finally
    EndUpdate;
  end;
end;

destructor TStyleNinePatch.Destroy;
begin
  Clear;
  ImageList.Free;
  BitmapList.Free;
  FImageMargins.Free;
  FOverlayMargins.Free;
  inherited;
end;

procedure TStyleNinePatch.Draw(Canvas: TCanvas; Rect: TRect; StateIndex: Integer; Opacity: Byte = 255);
begin
  DoDraw(Canvas, Rect, GetSuitedBitmap(StateIndex), GetSuitedOverlayBitmap(StateIndex), ImageMode, Opacity);
end;

procedure TStyleNinePatch.EndUpdate;
begin
  Dec(FUpdateCount);
  if FUpdateCount <= 0 then
  begin
    FUpdateCount := 0;
  end;
end;

function TStyleNinePatch.GetBitmap(Index: Integer): TBitmap;
begin
  if (Index < 0) or (Index >= StateCount) then
    raise Exception.CreateFmt('GetBitmap(%d) - Index of bounds!', [Index]);
  Result := RequestBitmap(Index);
end;

function TStyleNinePatch.GetImage(const Index: Integer): TPngImage;
begin
  Result := RequestImage(Index);
  // TPngImage not support OnChange event, because we need delete cache in Getter :(
//  if (BitmapList[Index] <> nil) then
//  begin
//    BitmapList[Index].Free;
//    BitmapList[Index] := nil;
//  end;
end;

function TStyleNinePatch.GetIsDefaultStyle: Boolean;
begin
  Result := IsDefaultValues and IsDefaultImages;
end;

function TStyleNinePatch.GetOverlayBitmap(Index: Integer): TBitmap;
begin
  if (Index < StateCount) or (Index >= StateCount * 2) then
    raise Exception.CreateFmt('GetOverlayBitmap(%d) - Index of bounds!', [Index]);
  Result := RequestBitmap(Index + StateCount);
end;

function TStyleNinePatch.GetOverlay(const Index: Integer): TPngImage;
begin
  Result := RequestImage(Index + StateCount);
  // TPngImage not support OnChange event, because we need delete cache in Getter :(
//  if (BitmapList[Index + StateCount] <> nil) then
//  begin
//    BitmapList[Index + StateCount].Free;
//    BitmapList[Index + StateCount] := nil;
//  end;
end;

function TStyleNinePatch.GetStylePrefix: string;
begin
  Result := Self.ClassName;
end;

function TStyleNinePatch.GetSuitedBitmap(Index: Integer): TBitmap;
var
  I: Integer;
begin
  if (Index < 0) or (Index >= StateCount) then
    raise Exception.CreateFmt('GetSuitedBitmap(%d) - Index of bounds!', [Index]);
  for I := Index downto 0 do
  begin
    if (ImageList[I] <> nil) or (BitmapList[I] <> nil) then
    begin
      //if not BitmapList[I].Empty then
      begin
        Result := RequestBitmap(I);
        exit;
      end;
    end;
  end;

  Result := BitmapList[Index];
end;

function TStyleNinePatch.GetSuitedOverlayBitmap(Index: Integer): TBitmap;
var
  I: Integer;
begin
  Index := Index + StateCount;
  if (Index < StateCount) or (Index >= StateCount * 2) then
    raise Exception.CreateFmt('GetSuitedOverlayBitmap(%d) - Index of bounds!', [Index]);
  for I := Index downto StateCount do
  begin
    if (ImageList[I] <> nil) or (BitmapList[I] <> nil) then
    begin
      //if not BitmapList[I].Empty then
      begin
        Result := RequestBitmap(I);
        exit;
      end;
    end;
  end;

  Result := BitmapList[Index];
end;

procedure TStyleNinePatch.ImageChange(Sender: TObject);
var
  Index: Integer;
begin
  if FIsDefaultImages and (FUpdateCount = 0) then
  begin
    FIsDefaultImages := False;
    UpdateImages;
  end;

  Index := ImageList.IndexOf(TPngImage(Sender));

  //
  if BitmapList[Index] = nil then
  begin
    if not TPngImage(Sender).Empty then
      RequestBitmap(Index).Assign(TPngImage(Sender));
  end else
  begin
    if not TPngImage(Sender).Empty then
      BitmapList[Index].Assign(TPngImage(Sender))
    else
    begin
      BitmapList[Index].Free;
      BitmapList[Index] := nil;
    end;
  end;

  Change;
end;

procedure TStyleNinePatch.DoDraw(Canvas: TCanvas; Rect: TRect; Bitmap: TBitmap;
      OverlayBitmap: TBitmap; Mode: TStretchMode; Opacity: Byte = 255);
var
  R: TRect;
  ContentRect: TRect;
begin
  if Assigned(Bitmap) then
    Canvas.DrawNinePatch(Rect, FImageMargins.Rect, Bitmap, Mode, Opacity);

//  // for painting child class
//  if (Self.ClassType <> TNinePatchObject) and ContentSpace then
//  begin
//    ContentRect.Left := Rect.Left + FMargins.Left;
//    ContentRect.Top := Rect.Top + FMargins.Top;
//    ContentRect.Right := Rect.Right - FMargins.Right;
//    ContentRect.Bottom := Rect.Bottom - FMargins.Bottom;
//  end
//  else
  ContentRect := Rect;

  if Assigned(OverlayBitmap) then
  begin
    R := Rect;

//    if FOverlaySpace then
//    begin
//      R.Left := R.Left + FMargins.Left;
//      R.Top := R.Top + FMargins.Top;
//      R.Right := R.Right - FMargins.Right;
//      R.Bottom := R.Bottom - FMargins.Bottom;
//    end;

    R.TopLeft.Offset(OverlayMargins.Rect.TopLeft);
    R.BottomRight.Offset(-OverlayMargins.Rect.Right, -OverlayMargins.Rect.Bottom);

    case FOverlayAlign of
      TImageAlign.iaTopLeft:
        Canvas.Draw(R.Left, R.Top, OverlayBitmap, Opacity);

      TImageAlign.iaTopRight:
        Canvas.Draw(R.Right - OverlayBitmap.Width, R.Top, OverlayBitmap, Opacity);

      TImageAlign.iaBottomRight:
        Canvas.Draw(R.Right - OverlayBitmap.Width, R.Bottom - OverlayBitmap.Height, OverlayBitmap, Opacity);

      TImageAlign.iaBottomLeft:
        Canvas.Draw(R.Left, R.Bottom - OverlayBitmap.Height, OverlayBitmap, Opacity);

      TImageAlign.iaCenter:
        Canvas.Draw(R.Left + R.Width div 2 - OverlayBitmap.Width div 2, R.Top + R.Height div 2 - OverlayBitmap.Height div 2, OverlayBitmap, Opacity);

      TImageAlign.iaLeft:
        Canvas.Draw(R.Left, R.Top + R.Height div 2 - OverlayBitmap.Height div 2, OverlayBitmap, Opacity);

      TImageAlign.iaRight:
        Canvas.Draw(R.Left + R.Width - OverlayBitmap.Width, R.Top + R.Height div 2 - OverlayBitmap.Height div 2, OverlayBitmap, Opacity);

      TImageAlign.iaTop:
        Canvas.Draw(R.Left + R.Width div 2 - OverlayBitmap.Width div 2, R.Top, OverlayBitmap, Opacity);

      TImageAlign.iaBottom:
        Canvas.Draw(R.Left + R.Width div 2 - OverlayBitmap.Width div 2, R.Top + R.Height - OverlayBitmap.Height, OverlayBitmap, Opacity);
    end;

//    case FOverlayAlign of
//      iaLeft: ContentRect.Left := R.Left + OverlayBitmap.Width + OverlayMargins.Right;
//      iaRight: ContentRect.Right := R.Right - OverlayBitmap.Width - OverlayMargins.Left;
//      iaTop: ContentRect.Top := R.Top + OverlayBitmap.Height - OverlayMargins.Bottom;
//      iaBottom: ContentRect.Bottom := R.Bottom - OverlayBitmap.Height - OverlayMargins.Top;
//    end;
  end;
end;

function TStyleNinePatch.IsPresented(Index: Integer): Boolean;
begin
  Result := False;

  if (Index < 0) or (Index >= StateCount) then
    exit;

  if (ImageList[Index] <> nil) and (not ImageList[Index].Empty) then
    Result := True;

  if (ImageList[Index + StateCount] <> nil) and (not ImageList[Index + StateCount].Empty) then
    Result := True;

  if (BitmapList[Index] <> nil) and (not BitmapList[Index].Empty) then
    Result := True;

  if (BitmapList[Index + StateCount] <> nil) and (not BitmapList[Index + StateCount].Empty) then
    Result := True;
end;

function TStyleNinePatch.IsStyleStored: Boolean;
begin
  Result := not (FIsDefaultValues and FIsDefaultImages);
end;

procedure TStyleNinePatch.AssignDefaultImages;
var
  StylePrefix: string;
  Name: string;
  I: Integer;
  Data: PTypeData;
  Info: PTypeInfo;
  PropList: PPropList;
  Png: TPngImage;
  hInstance: HINST;
begin
  Clear;

  FIsDefaultImages := True;

  StylePrefix := GetStylePrefix;

  hInstance := FindClassHInstance(Self.ClassType);
  Data := GetTypeData(Self.ClassType.ClassInfo);
  GetMem(PropList, Data.PropCount * SizeOf(Pointer));
  BeginUpdate;
  try
    GetPropInfos(ClassType.ClassInfo, PropList);
    for I := 0 to Data.PropCount - 1 do
    begin
      if IsStoredProp(Self, PropList[i]) then
      begin
        Info := PropList[i]^.PropType^;
        if (Info^.Kind = tkClass) and (string(Info^.Name) = TPngImage.ClassName) then
        begin
          Name := UpperCase(StylePrefix + '_' + string(PropList[i]^.Name));
          if FindResource(hInstance, PChar(Name), RT_RCDATA) <> 0 then
          begin
            Png := TPngImage(GetObjectProp(Self, string(PropList[i]^.Name)));
            Png.LoadFromResourceName(hInstance, PChar(Name));
          end;
        end;
      end;
    end;
  finally
    FreeMem(PropList, Data.PropCount * SizeOf(Pointer));
    EndUpdate;
  end;

  UpdateImages;

  for I := 0 to ImageList.Count - 1 do
    if ImageList[I] <> nil then
    begin
      ImageList[I].Free;
      ImageList[I] := nil;
    end;
end;

function TStyleNinePatch.RequestBitmap(Index: Integer): TBitmap;
begin
  if BitmapList[Index] = nil then
  begin
    BitmapList[Index] := TBitmap.Create;
    BitmapList[Index].PixelFormat := pf32bit;
    BitmapList[Index].AlphaFormat := afDefined;

    if (ImageList[Index] <> nil) and not ImageList[Index].Empty then
      BitmapList[Index].Assign(ImageList[Index]);
  end;

  Result := BitmapList[Index];
end;

function TStyleNinePatch.RequestImage(Index: Integer): TPngImage;
begin
  if ImageList[Index] = nil then
  begin
    ImageList[Index] := TFixPngImage.Create;
    ImageList[Index].OnChange := ImageChange;
  end;

  Result := ImageList[Index];
end;

function TStyleNinePatch.RequestOverlayBitmap(Index: Integer): TBitmap;
begin
  result := RequestBitmap(Index + StateCount);
end;

procedure TStyleNinePatch.AssignDefaultStyle;
begin
  AssignDefaultImages;
  BeginUpdate;
  try
    AssignDefaultValues;
  finally
    EndUpdate;
  end;
  FIsDefaultValues := True;
  ChangeNotify;
end;

procedure TStyleNinePatch.SetIsDefaultValues(const Value: Boolean);
begin
  if Value <> FIsDefaultValues then
  begin
    FIsDefaultValues := Value;
    if Value then
    begin
      //Clear;
      BeginUpdate;
      try
        AssignDefaultValues;
      finally
        EndUpdate;
      end;
      //LoadDefaultImages;
      //Change;
      ChangeNotify;
    end;
  end;
end;

procedure TStyleNinePatch.SetImage(const Index: Integer; const Image: TPngImage);
begin
  RequestImage(Index).Assign(Image);
  // ImageChange(RequestImage(Index));
  // Change;
end;

procedure TStyleNinePatch.SetImageMargins(const Value: TStyleMargins);
begin
  FImageMargins.Assign(Value);
end;


procedure TStyleNinePatch.SetImageMode(const Value: TStretchMode);
begin
  if FImageMode <> Value then
  begin
    FImageMode := Value;
    Change;
  end;
end;

procedure TStyleNinePatch.SetIsDefaultImages(const Value: Boolean);
begin
  if Value <> FIsDefaultImages then
  begin
    FIsDefaultImages := Value;
    if Value then
    begin
      Clear;
      AssignDefaultImages;
    end else
      Clear;
    ChangeNotify;
  end;
end;

procedure TStyleNinePatch.SetIsDefaultStyle(const Value: Boolean);
begin
  IsDefaultImages := Value;
  IsDefaultValues := Value;
end;

procedure TStyleNinePatch.SetOverlayAlign(const Value: TImageAlign);
begin
  if FOverlayAlign <> Value then
  begin
    FOverlayAlign := Value;
    Change;
  end;
end;

procedure TStyleNinePatch.SetOverlay(const Index: Integer; const Image: TPngImage);
begin
  RequestImage(Index + StateCount).Assign(Image);
  // ImageChange(RequestImage(Index));
  // Change;
end;

procedure TStyleNinePatch.SetOverlayMargins(const Value: TStyleMargins);
begin
  FOverlayMargins.Assign(Value);
end;

procedure TStyleNinePatch.UpdateImages;
var
  I: Integer;
begin
  for I := 0 to ImageList.Count - 1 do
  begin
    if (ImageList[I] <> nil)and not ImageList[I].Empty then
    begin
      RequestBitmap(I).Assign(ImageList[I]);
    end else
    begin
      BitmapList[I].Free;
      BitmapList[I] := nil;
    end;
  end;
end;

{ TEsTimer }

constructor TEsTimer.Create(Interval: Cardinal = 1000; OnTimer: TNotifyEvent = nil; Enabled: Boolean = False);
begin
  FInterval := Interval;
  FEnabled := Enabled;
  FOnTimer := OnTimer;
  UpdateTimer;
end;

destructor TEsTimer.Destroy;
begin
  FEnabled := False;
  UpdateTimer;
  inherited;
end;

procedure TEsTimer.DoTimer;
begin
  if Assigned(OnTimer) then
    OnTimer(Self);
end;

procedure TEsTimer.Reset;
begin
  if FEnabled then
    UpdateTimer;
end;

procedure TEsTimer.SetEnabled(const Value: Boolean);
begin
  if Value <> FEnabled then
  begin
    FEnabled := Value;
    UpdateTimer;
  end;
end;

procedure TEsTimer.SetInterval(const Value: Cardinal);
begin
  if Value <> FInterval then
  begin
    FInterval := Value;
    UpdateTimer;
  end;
end;

procedure TEsTimer.SetOnTimer(const Value: TNotifyEvent);
begin
  FOnTimer := Value;
  UpdateTimer;
end;

procedure TEsTimer.Start;
begin
  if not FEnabled then
  begin
    FEnabled := True;
    UpdateTimer;
  end;
end;

procedure TEsTimer.Stop;
begin
  if FEnabled then
  begin
    FEnabled := False;
    UpdateTimer;
  end;
end;

procedure TEsTimer.UpdateTimer;
begin
  if FEnabled then
  begin
    if HidenWindow = 0 then
    begin
      HidenWindow := AllocateHWnd(WndProc);
    end;
    KillTimer(HidenWindow, 1);
    if SetTimer(HidenWindow, 1, FInterval, nil) = 0 then
      raise EOutOfResources.Create('Error: No timers!');
  end
  else
    if HidenWindow <> 0 then
    begin
      KillTimer(HidenWindow, 1);
      DeallocateHWnd(HidenWindow);
      HidenWindow := 0;
    end;
end;

procedure TEsTimer.WndProc(var Message: TMessage);
begin
  if Message.Msg = WM_TIMER then
    DoTimer
  else
    Message.Result := DefWindowProc(HidenWindow, Message.Msg, Message.WParam, Message.LParam);
end;

{ TCustomAnimation }

constructor TCustomAnimation.Create;
begin
  Timer := TEsTimer.Create(10, TimerProc, False);
  //FOnProcess := OnProcess;
  FNormalizedTime := 0;
  FMode := amLinear;
  //Timer.Enabled := Enabled;
end;

destructor TCustomAnimation.Destroy;
begin
  Timer.Free;
  inherited;
end;

function TCustomAnimation.CurrentTime: Single;
var
  t: Single;
begin
  Result := 0;// for compiler paranoia

  if ReverseMode then
    t := 1 - FNormalizedTime
  else
    t := FNormalizedTime;

  case FMode of
    amLinear: Result := t;
    amCubic: Result := t * t * t; //( 1 - Sqrt(t * t * t * t * t));
  end;

  if ReverseMode then
    Result := 1 - Result;
end;

procedure TCustomAnimation.Process;
begin
  if Assigned(OnProcess) then
    OnProcess(Self);
end;

procedure TCustomAnimation.SetDuration(const Value: Cardinal);
begin
  if Value = 0 then
    FDuration := 1
  else
    FDuration := Value;
end;

procedure TCustomAnimation.SetMode(const Value: TAnimationMode);
begin
  FMode := Value;
end;

procedure TCustomAnimation.SetReverseMode(const Value: Boolean);
begin
  FReverseMode := Value;
end;

procedure TCustomAnimation.Start;
begin
  StartTime := GetTickCount;
  FNormalizedTime := 0;
  Timer.Start;
  Process;
end;

procedure TCustomAnimation.Stop;
begin
  Timer.Stop;
  FNormalizedTime := 1;
  Process;
  if Assigned(OnFinish) then
    OnFinish(Self);
end;

procedure TCustomAnimation.TimerProc(Sender: TObject);
var
  t: Cardinal;
begin
  t := GetTickCount;
  if t < StartTime + FDuration then
  begin
    FNormalizedTime := (t - StartTime) / FDuration;
    Process;
  end else
  begin
    Stop;
  end;
end;

{ TIntegerAnimation }

constructor TIntegerAnimation.Create;
begin
  inherited;

end;

function TIntegerAnimation.GetValue: Integer;
begin
  Result := Trunc(StartValue * (1 - CurrentTime) + EndValue * CurrentTime + 0.5);
end;

procedure TIntegerAnimation.SetEndValue(const Value: Integer);
begin
  if FEndValue <> Value then
  begin
    FEndValue := Value;
//    Process;
  end;
end;

procedure TIntegerAnimation.SetStartValue(const Value: Integer);
begin
  if FStartValue <> Value then
  begin
    FStartValue := Value;
//    Process;
  end;
end;

{ TFixPngImage }

procedure TFixPngImage.Assign(Source: TPersistent);
begin
  inherited;
  Changed(Self);
end;

procedure TFixPngImage.LoadFromClipboardFormat(AFormat: Word; AData: THandle; APalette: HPalette);
begin
  inherited;
  Changed(Self);
end;

procedure TFixPngImage.LoadFromFile(const Filename: String);
begin
  inherited;
  Changed(Self);
end;

procedure TFixPngImage.LoadFromStream(Stream: TStream);
begin
  inherited;
  Changed(Self);
end;

procedure TFixPngImage.SetHeight(Value: Integer);
begin
  inherited;
  Changed(Self);
end;

procedure TFixPngImage.SetWidth(Value: Integer);
begin
  inherited;
  Changed(Self);
end;

end.
