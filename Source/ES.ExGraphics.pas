{******************************************************************************}
{                          FreeEsVclComponents/Core                            }
{                           ErrorSoft(c) 2009-2016                             }
{                                                                              }
{           errorsoft@mail.ru | vk.com/errorsoft | github.com/errorcalc        }
{     errorsoft@protonmail.ch | habrahabr.ru/user/error1024 | errorsoft.org    }
{                                                                              }
{ Open this on github: github.com/errorcalc/FreeEsVclComponents                }
{                                                                              }
{ �� ������ �������� ���������� VCL/FMX ���������� �� �����                    }
{ You can order the development of VCL/FMX components to order                 }
{******************************************************************************}
unit ES.ExGraphics;

interface

{$if CompilerVersion >= 21}
{$define VER210UP}
{$ifend}
{$IF CompilerVersion >= 23}
{$DEFINE VER230UP}
{$IFEND}

{$I 'EsVclCore.inc'}

uses
  Windows, Graphics, Themes{$ifdef VER230UP}, PngImage{$endif};

type
//  {$ifdef VER210UP} {$scopedenums on} {$endif}
  TStretchMode = (smNormal, smTile, smHorzFit, smVertFit, smHorzTile, smVertTile, smHorzTileFit, smVertTileFit);
//  {$ifdef VER210UP} {$scopedenums off} {$endif}

  /// <summary> Class for save canvas state </summary>
  TCanvasSaver = class(TInterfacedObject)
  private
    FPen: TPen;
    FBrush: TBrush;
    FFont: TFont;
    FCanvas: TCanvas;
    function GetBrush: TBrush;
    function GetFont: TFont;
    function GetPen: TPen;
    procedure SetBrush(const Value: TBrush);
    procedure SetFont(const Value: TFont);
    procedure SetPen(const Value: TPen);
  public
    property Pen: TPen read GetPen write SetPen;
    property Brush: TBrush read GetBrush write SetBrush;
    property Font: TFont read GetFont write SetFont;

    constructor Create(Canvas: TCanvas);
    destructor Destroy; override;
    procedure Restore;
  end;

  {$ifdef VER210UP}
  TEsCanvasHelper = class helper for TCanvas
  {$else}
  TEsCanvas = class(TCanvas)
  {$endif}
  public
    {$ifdef VER230UP}
    procedure DrawHighQuality(ARect: TRect; Bitmap: TBitmap; Opacity: Byte = 255); overload;
    procedure DrawHighQuality(ARect: TRect; Graphic: TGraphic; Opacity: Byte = 255); overload;
    {$endif}
    procedure StretchDraw(DestRect, SrcRect: TRect; Bitmap: TBitmap); overload;
    procedure StretchDraw(DestRect, SrcRect: TRect; Bitmap: TBitmap; Opacity: Byte); overload;
    procedure StretchDraw(Rect: TRect; Graphic: TGraphic; Opacity: Byte); overload;
    procedure Draw(X, Y: Integer; Graphic: TGraphic; Opacity: Byte); overload;
//    procedure StretchDraw(DestRect, ClipRect, SrcRect: TRect; Bitmap: TBitmap; Alpha: byte); overload;
    procedure DrawNinePatch(Dest: TRect; Bounds: TRect; Bitmap: TBitmap); overload;
    procedure DrawNinePatch(Dest: TRect; Bounds: TRect; Bitmap: TBitmap; Opacity: Byte); overload;
    procedure DrawNinePatch(Dest: TRect; Bounds: TRect; Bitmap: TBitmap; Mode: TStretchMode; Opacity: Byte = 255); overload;
    {$ifdef VER230UP}
    procedure DrawThemeText(Details: TThemedElementDetails; Rect: TRect; Text: string; Format: TTextFormat);
    {$endif}
    procedure DrawChessFrame(R: TRect; Color1, Color2: TColor); overload;
    procedure DrawTransparentFrame(R: TRect; Color1, Color2: TColor; Opacity: Integer = -1; const Mask: ShortString = '12');
    procedure DrawInsideFrame(R: TRect; Width: Integer; Color: TColor = clNone);
    // support save/restore state
    function SaveAll: TCanvasSaver;
    function SavePen: TCanvasSaver;
    function SaveBrush: TCanvasSaver;
    function SaveFont: TCanvasSaver;
    procedure Restore(var State: TCanvasSaver);
  end;

  TEsBitMap = class(TBitmap)
  private
  protected
    property Palette;
    {$ifdef VER210UP}
    property AlphaFormat;
    {$endif}
    property PixelFormat;
  public
    Constructor Create; override;
    {$ifndef VER210UP}
    procedure PreMultiplyAlpha;
    procedure UnPreMultiplyAlpha;
    {$endif}
    procedure LoadFromResourceName(Instance: THandle; const ResName: String; ResType: PChar); overload;
  end;

  // Utils
  function ColorToAlphaColor(Color: TColor; Alpha: byte = 255): DWORD; Inline;
  function RgbToArgb(Color: TColor; Alpha: byte = 255): DWORD; Inline;
  {$ifdef VER230UP}
  procedure DrawBitmapHighQuality(Handle: THandle; ARect: TRect; Bitmap: TBitmap; Opacity: Byte = 255;
  HighQality: Boolean = False; IsPremultipledBitmap: Boolean = True);
  {$endif}
  {$ifdef VER210UP}
  procedure PngImageAssignToBitmap(Bitmap: TBitmap; PngImage: TPngImage; IsPremultipledBitmap: Boolean = True);
  procedure BitmapAssignToPngImage(PngImage: TPngImage; Bitmap: TBitmap; IsPremultipledBitmap: Boolean = True);
  {$endif}
  procedure GraphicAssignToBitmap(Bitmap: TBitmap; Graphic: TGraphic); Inline;

  // Color spaces
  procedure ColorToHSL(Color: TColor; var H, S, L: Integer);
  function HSLToColor(Hue, Saturation, Lightness: Integer): TColor;
  //---
  function LuminanceColor(Color: TColor; Value: Integer): TColor;

implementation

uses
  Classes, Types {$ifdef VER230UP},GdipObj, GdipApi{$endif}, GraphUtil;

//------------------------------------------------------------------------------
// Utils
//------------------------------------------------------------------------------

type
  TRGBAArray = array[Word] of TRGBQuad;
  PRGBAArray = ^TRGBAArray;
  TRGBArray = array[Word] of TRGBTriple;
  PRGBArray = ^TRGBArray;

function RgbToArgb(Color: TColor; Alpha: byte = 255): DWORD;
begin
  Result := ColorToAlphaColor(Color, Alpha);
end;

function ColorToAlphaColor(Color: TColor; Alpha: byte = 255): DWORD;
var
  BRG: DWORD;
begin
  BRG := ColorToRGB(Color);

  Result := ((BRG shl 16) and $00FF0000) or ((BRG shr 16) and $000000FF) or (BRG and $0000FF00) or (Alpha shl 24);
end;

{$ifdef VER230UP}
procedure DrawBitmapHighQuality(Handle: THandle; ARect: TRect; Bitmap: TBitmap; Opacity: Byte = 255;
  HighQality: Boolean = False; IsPremultipledBitmap: Boolean = True);
var
  {$ifndef DISABLE_GDIPLUS}
  Graphics: TGPGraphics;
  GdiPBitmap: TGPBitmap;
  Attr: TGPImageAttributes;
  M: TColorMatrix;
  {$else}
  BF: TBlendFunction;
  {$endif}
begin
  {$ifndef DISABLE_GDIPLUS}
  if Bitmap.Empty then
    Exit;

  GdiPBitmap := nil;
  Graphics := TGPGraphics.Create(Handle);
  try
    Graphics.SetSmoothingMode(SmoothingModeDefault);
    Graphics.SetPixelOffsetMode(PixelOffsetModeHalf);

    if HighQality then
      Graphics.SetInterpolationMode(InterpolationModeBilinear)
    else
      Graphics.SetInterpolationMode(InterpolationModeHighQuality);

    if Bitmap.PixelFormat = pf32bit then
    begin
      Assert(Bitmap.HandleType = bmDIB);
      GdiPBitmap := TGPBitmap.Create(Bitmap.Width, Bitmap.Height, -Bitmap.Width * 4,
        PixelFormat32bppPARGB, Bitmap.ScanLine[0]);
    end else
      GdiPBitmap := TGPBitmap.Create(Bitmap.Handle, Bitmap.Palette);

    if Opacity <> 255 then
    begin
      FillMemory(@M, SizeOf(TColorMatrix), 0);
      M[0, 0] := 1;
      M[1, 1] := 1;
      M[2, 2] := 1;
      M[3, 3] := Opacity / 255;
      M[4, 4] := 1;

      Attr := TGPImageAttributes.Create;
      try
        Attr.SetColorMatrix(M);
        Graphics.DrawImage(GdiPBitmap, MakeRect(ARect.Left, ARect.Top, ARect.Width, ARect.Height),
          0, 0, Bitmap.Width, Bitmap.Height, UnitPixel, Attr);
      finally
        Attr.Free;
      end;
    end else
      Graphics.DrawImage(GdiPBitmap, MakeRect(ARect.Left, ARect.Top, ARect.Width, ARect.Height));
  finally
    Graphics.Free;
    GdiPBitmap.Free;
  end;
  {$else}
  if Bitmap.Empty then
    Exit;

  BF.BlendOp := AC_SRC_OVER;
  BF.BlendFlags := 0;
  BF.SourceConstantAlpha := Alpha;
  BF.AlphaFormat := AC_SRC_ALPHA;

  AlphaBlend(Handle, ARect.Left, ARect.Top, ARect.Right - ARect.Left, ARect.Bottom - ARect.Top,
    Bitmap.Canvas.Handle, 0, 0, Bitmap.Width, Bitmap.Height, BF);
  {$endif}
end;
{$endif}

{$ifdef VER210UP}
procedure PngImageAssignToBitmap(Bitmap: TBitmap; PngImage: TPngImage; IsPremultipledBitmap: Boolean = True);
var
  X, Y: Integer;
  pBitmap: PRGBAArray;
  pPng: PRGBArray;
  pPngAlpha: PByteArray;
  pPngTable: PByteArray;
  C: TRGBQuad;
  A: Byte;
begin
  if PngImage.Empty or (PngImage.TransparencyMode <> ptmPartial) or (PngImage.Header.BitDepth <> 8) then
    Bitmap.Assign(PngImage)
  else
  begin
    Bitmap.SetSize(0, 0);
    Bitmap.AlphaFormat := TAlphaFormat.afPremultiplied;
    Bitmap.PixelFormat := pf32bit;
    Bitmap.SetSize(PngImage.Width, PngImage.Height);

    for Y := 0 to Bitmap.Height - 1 do
    begin
      pBitmap := Bitmap.ScanLine[Y];
      pPng := PngImage.Scanline[Y];
      pPngTable := PngImage.Scanline[Y];
      pPngAlpha := PngImage.AlphaScanline[Y];

      if PngImage.Header.ColorType = COLOR_RGBALPHA then
      // RGBA
        if IsPremultipledBitmap then
          for X := 0 to Bitmap.Width - 1 do
          begin
            pBitmap[X].rgbBlue := (pPng[x].rgbtBlue * pPngAlpha[X]) div 255;
            pBitmap[X].rgbGreen := (pPng[x].rgbtGreen * pPngAlpha[X]) div 255;
            pBitmap[X].rgbRed := (pPng[x].rgbtRed * pPngAlpha[X]) div 255;
            pBitmap[X].rgbReserved := pPngAlpha[X];
          end
        else
          for X := 0 to Bitmap.Width - 1 do
          begin
            pBitmap[X].rgbBlue := pPng[x].rgbtBlue;
            pBitmap[X].rgbGreen := pPng[x].rgbtGreen;
            pBitmap[X].rgbRed := pPng[x].rgbtRed;
            pBitmap[X].rgbReserved := pPngAlpha[X];
          end
      else if PngImage.Header.ColorType = COLOR_PALETTE then
      // PALETTE
        if IsPremultipledBitmap then
          for X := 0 to Bitmap.Width - 1 do
          begin
            C := TChunkPLTE(PngImage.Chunks.ItemFromClass(TChunkPLTE)).Item[pPngTable[X]];
            A := TChunktRNS(PngImage.Chunks.ItemFromClass(TChunktRNS)).PaletteValues[pPngTable[X]];
            pBitmap[X].rgbBlue := (C.rgbBlue * A) div 255;
            pBitmap[X].rgbGreen := (C.rgbGreen * A) div 255;
            pBitmap[X].rgbRed := (C.rgbRed * A) div 255;
            pBitmap[X].rgbReserved := A;
          end
        else
          for X := 0 to Bitmap.Width - 1 do
          begin
            C := TChunkPLTE(PngImage.Chunks.ItemFromClass(TChunkPLTE)).Item[pPngTable[X]];
            A := TChunktRNS(PngImage.Chunks.ItemFromClass(TChunktRNS)).PaletteValues[pPngTable[X]];
            pBitmap[X].rgbBlue := C.rgbBlue;
            pBitmap[X].rgbGreen := C.rgbGreen;
            pBitmap[X].rgbRed := C.rgbRed;
            pBitmap[X].rgbReserved := A;
          end
      else
      // GRAYSCALE
        if IsPremultipledBitmap then
          for X := 0 to Bitmap.Width - 1 do
          begin
            pBitmap[X].rgbBlue := (pPngTable[X] * pPngAlpha[X]) div 255;
            pBitmap[X].rgbGreen := pBitmap[X].rgbBlue;
            pBitmap[X].rgbRed := pBitmap[X].rgbBlue;
            pBitmap[X].rgbReserved := pPngAlpha[X];
          end
        else
          for X := 0 to Bitmap.Width - 1 do
          begin
            pBitmap[X].rgbBlue := pPngTable[X];;
            pBitmap[X].rgbGreen := pBitmap[X].rgbBlue;
            pBitmap[X].rgbRed := pBitmap[X].rgbBlue;
            pBitmap[X].rgbReserved := pPngAlpha[X];
          end
    end;
  end;
end;

procedure BitmapAssignToPngImage(PngImage: TPngImage; Bitmap: TBitmap; IsPremultipledBitmap: Boolean = True);
var
  TempPng: TPngImage;
  X, Y: Integer;
  pBitmap: PRGBAArray;
  pPng: PRGBArray;
  pPngAlpha: PByteArray;
begin
  if Bitmap.Empty or (Bitmap.PixelFormat <> pf32bit) then
    PngImage.Assign(Bitmap)
  else
  begin
    // set need settings
    TempPng := TPngImage.CreateBlank(COLOR_RGBALPHA, 8, 1, 1);
    try
      PngImage.Assign(TempPng);
    finally
      TempPng.Free;
    end;
    PngImage.SetSize(Bitmap.Width, Bitmap.Height);

    for Y := 0 to PngImage.Height - 1 do
    begin
      pBitmap := Bitmap.ScanLine[Y];
      pPng := PngImage.Scanline[Y];
      pPngAlpha := PngImage.AlphaScanline[Y];
      for X := 0 to PngImage.Width - 1 do
      begin
        if pBitmap[X].rgbReserved <> 0 then
        begin
          if IsPremultipledBitmap then
          begin
            pPng[X].rgbtBlue := (pBitmap[x].rgbBlue * 255) div pBitmap[x].rgbReserved;
            pPng[X].rgbtGreen := (pBitmap[x].rgbGreen * 255) div pBitmap[x].rgbReserved;
            pPng[X].rgbtRed := (pBitmap[x].rgbRed * 255) div pBitmap[x].rgbReserved;
          end else
          begin
            pPng[X].rgbtBlue := pBitmap[x].rgbBlue;
            pPng[X].rgbtGreen := pBitmap[x].rgbGreen;
            pPng[X].rgbtRed := pBitmap[x].rgbRed;
          end;
        end else
        begin
          pPng[X].rgbtBlue := 0; pPng[X].rgbtGreen := 0; pPng[X].rgbtRed := 0;
        end;
        pPngAlpha[X] := pBitmap[X].rgbReserved;
      end;
    end;
  end;
end;
{$endif}

procedure GraphicAssignToBitmap(Bitmap: TBitmap; Graphic: TGraphic); Inline;
begin
  // standart TPngImage.AssignTo works is bad!
  {$ifdef VER230UP}
  if Graphic is TPngImage then
    PngImageAssignToBitmap(Bitmap, TPngImage(Graphic))
  else
  {$endif}
    Bitmap.Assign(Graphic);
end;

//------------------------------------------------------------------------------
// Color spaces
//------------------------------------------------------------------------------

const
  //HSV_MAX = 240;
  HLS_MAX = 240;
  HLS_MAX_HALF = HLS_MAX / 2.0;
  HLS_MAX_ONE_THIRD = HLS_MAX / 3.0;
  HLS_MAX_TWO_THIRDS = (HLS_MAX * 2.0) / 3.0;
  HLS_MAX_SIXTH = HLS_MAX / 6.0;
  HLS_MAX_TWELVETH = HLS_MAX / 12.0;
  RGB_MAX = 255;

// Original source this function: JEDI Code Library (jvFullColorSpaces)
procedure ColorToHSL(Color: TColor; var H, S, L: Integer);
var
  Hue, Lightness, Saturation: Double;
  Red, Green, Blue: Integer;
  ColorMax, ColorMin, ColorDiff, ColorSum: Double;
  RedDelta, GreenDelta, BlueDelta: Extended;
begin
  Red := GetRValue(Color);
  Green := GetGValue(Color);
  Blue := GetBValue(Color);

  if Red > Green then
    ColorMax := Red
  else
    ColorMax := Green;
  if Blue > ColorMax then
    ColorMax := Blue;
  if Red < Green then
    ColorMin := Red
  else
    ColorMin := Green;
  if Blue < ColorMin then
    ColorMin := Blue;
  ColorDiff := ColorMax - ColorMin;
  ColorSum := ColorMax + ColorMin;

  Lightness := (ColorSum * HLS_MAX + RGB_MAX) / (2.0 * RGB_MAX);
  if ColorMax = ColorMin then
  begin
    L := Round(Lightness);
    S := 0;
    H := (2 * HLS_MAX div 3);
    //Color := (Round(Lightness) shl 8) or (2 * HLS_MAX div 3)
  end
  else
  begin
    if Lightness <= HLS_MAX_HALF then
      Saturation := (ColorDiff * HLS_MAX + ColorSum / 2.0) / ColorSum
    else
      Saturation := (ColorDiff * HLS_MAX + ((2.0 * RGB_MAX - ColorMax - ColorMin) / 2.0)) /
        (2.0 * RGB_MAX - ColorMax - ColorMin);

    RedDelta := ((ColorMax - Red) * HLS_MAX_SIXTH + ColorDiff / 2.0) / ColorDiff;
    GreenDelta := ((ColorMax - Green) * HLS_MAX_SIXTH + ColorDiff / 2.0) / ColorDiff;
    BlueDelta := ((ColorMax - Blue) * HLS_MAX_SIXTH + ColorDiff / 2.0) / ColorDiff;

    if Red = ColorMax then
      Hue := BlueDelta - GreenDelta
    else
    if Green = ColorMax then
      Hue := HLS_MAX_ONE_THIRD + RedDelta - BlueDelta
    else
      Hue := 2.0 * HLS_MAX_ONE_THIRD + GreenDelta - RedDelta;

    if Hue < 0 then
      Hue := Hue + HLS_MAX;
    if Hue > HLS_MAX then
      Hue := Hue - HLS_MAX;

    H := Cardinal(Round(Hue));
    L := Cardinal(Round(Lightness));
    S := Cardinal(Round(Saturation));
  end;
end;

// Original source this function: JEDI Code Library (jvFullColorSpaces)
function HSLToColor(Hue, Saturation, Lightness: Integer): TColor;
var
  Red, Green, Blue: Double;
  Magic1, Magic2: Double;

  function HueToRGB(Lightness, Saturation, Hue: Double): Integer;
  var
    ResultEx: Double;
  begin
    if Hue < 0 then
      Hue := Hue + HLS_MAX;
    if Hue > HLS_MAX then
      Hue := Hue - HLS_MAX;

    if Hue < HLS_MAX_SIXTH then
      ResultEx := Lightness + ((Saturation - Lightness) * Hue + HLS_MAX_TWELVETH) / HLS_MAX_SIXTH
    else
    if Hue < HLS_MAX_HALF then
      ResultEx := Saturation
    else
    if Hue < HLS_MAX_TWO_THIRDS then
      ResultEx := Lightness + ((Saturation - Lightness) * (HLS_MAX_TWO_THIRDS - Hue) + HLS_MAX_TWELVETH) / HLS_MAX_SIXTH
    else
      ResultEx := Lightness;
    Result := Round(ResultEx);
  end;

  function RoundColor(Value: Double): Integer;
  begin
    if Value > RGB_MAX then
      Result := RGB_MAX
    else
      Result := Round(Value);
  end;

begin
  if Saturation = 0 then
  begin
    Red := (Lightness * RGB_MAX) / HLS_MAX;
    Green := Red;
    Blue := Red;
  end
  else
  begin
    if Lightness <= HLS_MAX_HALF then
      Magic2 := (Lightness * (HLS_MAX + Saturation) + HLS_MAX_HALF) / HLS_MAX
    else
      Magic2 := Lightness + Saturation - ((Lightness * Saturation) + HLS_MAX_HALF) / HLS_MAX;

    Magic1 := 2 * Lightness - Magic2;

    Red := (HueToRGB(Magic1, Magic2, Hue + HLS_MAX_ONE_THIRD) * RGB_MAX + HLS_MAX_HALF) / HLS_MAX;
    Green := (HueToRGB(Magic1, Magic2, Hue) * RGB_MAX + HLS_MAX_HALF) / HLS_MAX;
    Blue := (HueToRGB(Magic1, Magic2, Hue - HLS_MAX_ONE_THIRD) * RGB_MAX + HLS_MAX_HALF) / HLS_MAX;
  end;

  Result := RGB(RoundColor(Red), RoundColor(Green), RoundColor(Blue));
end;

function LuminanceColor(Color: TColor; Value: Integer): TColor;
var
  H, S, L: Integer;
begin
  ColorToHSL(ColorToRgb(Color), H, S, L);
  Result := HSLToColor(H, S, Value);
end;

//------------------------------------------------------------------------------
// Classes
//------------------------------------------------------------------------------

{ TCanvasSaver }

constructor TCanvasSaver.Create(Canvas: TCanvas);
begin
  FCanvas := Canvas;
end;

destructor TCanvasSaver.Destroy;
begin
  if FCanvas <> nil then
  begin
    if FPen <> nil then
      FCanvas.Pen := FPen;
    if FBrush <> nil then
      FCanvas.Brush := FBrush;
    if FFont <> nil then
      FCanvas.Font := FFont;
  end;
  inherited;
end;

function TCanvasSaver.GetBrush: TBrush;
begin
  if FBrush = nil then
    FBrush := TBrush.Create;
  Result := FBrush;
end;

function TCanvasSaver.GetFont: TFont;
begin
  if FFont = nil then
    FFont := TFont.Create;
  Result := FFont;
end;

function TCanvasSaver.GetPen: TPen;
begin
  if FPen = nil then
    FPen := TPen.Create;
  Result := FPen;
end;

procedure TCanvasSaver.Restore;
begin
  Free;
end;

procedure TCanvasSaver.SetBrush(const Value: TBrush);
begin
  Brush.Assign(Value);
end;

procedure TCanvasSaver.SetFont(const Value: TFont);
begin
  Font.Assign(Value);
end;

procedure TCanvasSaver.SetPen(const Value: TPen);
begin
  Pen.Assign(Value);
end;

{ TEsCanvas && TEsCanvasHelper }

procedure {$ifdef VER210UP}TEsCanvasHelper{$else}TEsCanvas{$endif}.
  StretchDraw(DestRect, SrcRect: TRect; Bitmap: TBitmap);
begin
  StretchDraw(DestRect, SrcRect, BitMap, 255);
end;

procedure {$ifdef VER210UP}TEsCanvasHelper{$else}TEsCanvas{$endif}.
  StretchDraw(DestRect, SrcRect: TRect; Bitmap: TBitmap; Opacity: byte);
var
  BF: TBlendFunction;
begin
  if Bitmap.Empty then
    Exit;

  BF.BlendOp := AC_SRC_OVER;
  BF.BlendFlags := 0;
  BF.SourceConstantAlpha := Opacity;
  BF.AlphaFormat := AC_SRC_ALPHA;

  AlphaBlend(Handle, DestRect.Left, DestRect.Top, DestRect.Right - DestRect.Left, DestRect.Bottom - DestRect.Top,
    Bitmap.Canvas.Handle, SrcRect.Left, SrcRect.Top, SrcRect.Right - SrcRect.Left, SrcRect.Bottom - SrcRect.Top, BF);
end;

procedure {$ifdef VER210UP}TEsCanvasHelper{$else}TEsCanvas{$endif}.
  DrawNinePatch(Dest: TRect; Bounds: TRect; Bitmap: TBitmap);
begin
  DrawNinePatch(Dest, Bounds, Bitmap, 255);
end;

{$ifdef VER230UP}
procedure {$ifdef VER210UP}TEsCanvasHelper{$else}TEsCanvas{$endif}.
  DrawHighQuality(ARect: TRect; Bitmap: TBitmap; Opacity: Byte = 255);
begin
  DrawBitmapHighQuality(Handle, ARect, Bitmap, Opacity);
end;

procedure {$ifdef VER210UP}TEsCanvasHelper{$else}TEsCanvas{$endif}.
  DrawHighQuality(ARect: TRect; Graphic: TGraphic; Opacity: Byte = 255);
{$ifndef DISABLE_GDIPLUS}
var
  Bitmap: TBitmap;
{$endif}
begin
  {$ifndef DISABLE_GDIPLUS}
  if Graphic is TBitmap then
    DrawHighQuality(ARect, TBitmap(Graphic), Opacity)
  else
  begin
    Bitmap := TBitmap.Create;
    try
      GraphicAssignToBitmap(Bitmap, Graphic);
      DrawHighQuality(ARect, Bitmap, Opacity);
    finally
      Bitmap.Free;
    end;
  end;
  {$else}
  StretchDraw(ARect, Graphic, Alpha);
  {$endif}
end;

{$endif}

procedure {$ifdef VER210UP}TEsCanvasHelper{$else}TEsCanvas{$endif}.
  Draw(X, Y: Integer; Graphic: TGraphic; Opacity: Byte);
var
  Bitmap: TBitmap;
begin
  if Graphic is TBitmap then
  begin
//    if (TBitmap(Graphic).PixelFormat = pf32bit) and (TBitmap(Graphic).AlphaFormat = afIgnored) then
//      TBitmap(Graphic).AlphaFormat := afDefined;
    Inherited Draw(X, Y, Graphic, Opacity)
  end
  else
  begin
    Bitmap := TBitmap.Create;
    try
      GraphicAssignToBitmap(Bitmap, Graphic);
      Inherited Draw(X, Y, Bitmap, Opacity);
    finally
      Bitmap.Free;
    end;
  end;
end;

procedure {$ifdef VER210UP}TEsCanvasHelper{$else}TEsCanvas{$endif}.
  DrawChessFrame(R: TRect; Color1, Color2: TColor);
var
  Brush: HBRUSH;
  Bitmap: TBitmap;
begin
  Brush := 0;
  Bitmap := TBitmap.Create;
  try
    Bitmap.PixelFormat := pf24bit;
    Bitmap.SetSize(2, 2);
    Bitmap.Canvas.Pixels[0, 0] := ColorToRGB(Color1);
    Bitmap.Canvas.Pixels[1, 1] := ColorToRGB(Color1);
    Bitmap.Canvas.Pixels[1, 0] := ColorToRGB(Color2);
    Bitmap.Canvas.Pixels[0, 1] := ColorToRGB(Color2);

    Brush := CreatePatternBrush(Bitmap.Handle);

    Windows.FrameRect(Handle, R, Brush);
  finally
    DeleteObject(Brush);
    Bitmap.Free;
  end;
end;

function ValidRect(Rect: TRect): Boolean;
begin
  Result := (RectWidth(Rect) > 0) and (RectHeight(Rect) > 0);
end;

procedure {$ifdef VER210UP}TEsCanvasHelper{$else}TEsCanvas{$endif}
  .DrawNinePatch(Dest: TRect; Bounds: TRect; Bitmap: TBitmap; Opacity: byte);
var
  dx, dy: Integer;
  D, S: TRect;
  IntD, IntS: TRect;
begin
  if (Dest.Left >= Dest.Right) or (Dest.Top >= Dest.Bottom) then
    exit;

  IntD := Rect(Dest.Left + Bounds.Left, Dest.Top + Bounds.Top,
    Dest.Right - Bounds.Right, Dest.Bottom - Bounds.Bottom);
  IntS := Rect(Bounds.Left, Bounds.Top, Bitmap.Width - Bounds.Right, Bitmap.Height - Bounds.Bottom);

  // needs to adjust to get rid of overdraw and painting was correct
  // cut left
  if Dest.Right - Dest.Left < Bounds.Left then
  begin
    dx := Bounds.Left - (Dest.Right - Dest.Left);
    IntD.Left := IntD.Left - dx;
    IntS.Left := IntS.Left - dx;
    //
    IntD.Right := Dest.Right;
  end else
  // cut right
  if Dest.Right - Dest.Left < Bounds.Left + Bounds.Right then
  begin
    dx := (Bounds.Left + Bounds.Right) - (Dest.Right - Dest.Left);
    IntD.Right := IntD.Right + dx;
    IntS.Right := IntS.Right + dx;
  end;
  // cut top
  if Dest.Bottom - Dest.Top < Bounds.Top then
  begin
    dy := Bounds.Top - (Dest.Bottom - Dest.Top);
    IntD.Top := IntD.Top - dy;
    IntS.Top := IntS.Top - dy;
    //
    IntD.Bottom := Dest.Bottom;
  end else
  // cut bottom
  if Dest.Bottom - Dest.Top < Bounds.Top + Bounds.Bottom then
  begin
    dy := (Bounds.Top + Bounds.Bottom) - (Dest.Bottom - Dest.Top);
    IntD.Bottom := IntD.Bottom + dy;
    IntS.Bottom := IntS.Bottom + dy;
  end;

//  // correct!
//  if IntD.Left > Dest.Right then
//    IntD.Left := Dest.Right;
//  if IntD.Top > Dest.Bottom then
//    IntD.Top := Dest.Bottom;
//  if IntD.Right < Dest.Left then
//    IntD.Right := Dest.Left;
//  if IntD.Bottom < Dest.Top then
//    IntD.Bottom := Dest.Top;


  //   ---
  //  |*  |
  //  |   |
  //  |   |
  //   ---
  D := Rect(Dest.Left, Dest.Top, IntD.Left, IntD.Top);
  S := Rect(0, 0, IntS.Left, IntS.Top);
  StretchDraw(D, S, Bitmap, Opacity);
  //   ---
  //  |   |
  //  |*  |
  //  |   |
  //   ---
  D := Rect(Dest.Left, IntD.Top, IntD.Left, IntD.Bottom);
  S := Rect(0, IntS.Top, IntS.Left, IntS.Bottom);
  if ValidRect(D) then
    StretchDraw(D, S, Bitmap, Opacity);
  //   ---
  //  |   |
  //  |   |
  //  |*  |
  //   ---
  D := Rect(Dest.Left, IntD.Bottom, IntD.Left, Dest.Bottom);
  S := Rect(0, IntS.Bottom, IntS.Left, Bitmap.Height);
  if ValidRect(D) then
    StretchDraw(D, S, Bitmap, Opacity);
  //   ---
  //  |   |
  //  |   |
  //  | * |
  //   ---
  D := Rect(IntD.Left, IntD.Bottom, IntD.Right, Dest.Bottom);
  S := Rect(IntS.Left, IntS.Bottom, IntS.Right, Bitmap.Height);
  if ValidRect(D) then
    StretchDraw(D, S, Bitmap, Opacity);
  //   ---
  //  |   |
  //  |   |
  //  |  *|
  //   ---
  D := Rect(IntD.Right, IntD.Bottom, Dest.Right, Dest.Bottom);
  S := Rect(IntS.Right, IntS.Bottom, Bitmap.Width, Bitmap.Height);
  if ValidRect(D) then
    StretchDraw(D, S, Bitmap, Opacity);
  //   ---
  //  |   |
  //  |  *|
  //  |   |
  //   ---
  D := Rect(IntD.Right, IntD.Top, Dest.Right, IntD.Bottom);
  S := Rect(IntS.Right, IntS.Top, Bitmap.Width, IntS.Bottom);
  if ValidRect(D) then
    StretchDraw(D, S, Bitmap, Opacity);
  //   ---
  //  |  *|
  //  |   |
  //  |   |
  //   ---
  D := Rect(IntD.Right, Dest.Top, Dest.Right, IntD.Top);
  S := Rect(IntS.Right, 0, Bitmap.Width, IntS.Top);
  if ValidRect(D) then
    StretchDraw(D, S, Bitmap, Opacity);
  //   ---
  //  | * |
  //  |   |
  //  |   |
  //   ---
  D := Rect(IntD.Left, Dest.Top, IntD.Right, IntD.Top);
  S := Rect(IntS.Left, 0, IntS.Right, IntS.Top);
  if ValidRect(D) then
    StretchDraw(D, S, Bitmap, Opacity);
  //   ---
  //  |   |
  //  | * |
  //  |   |
  //   ---
  D := Rect(IntD.Left, IntD.Top, IntD.Right, IntD.Bottom);
  S := Rect(IntS.Left, IntS.Top, IntS.Right, IntS.Bottom);
  if ValidRect(D) then
    StretchDraw(D, S, Bitmap, Opacity);
end;

{$ifdef VER230UP}
procedure {$ifdef VER210UP}TEsCanvasHelper{$else}TEsCanvas{$endif}
  .DrawThemeText(Details: TThemedElementDetails; Rect: TRect; Text: string;
  Format: TTextFormat);
var
  Opt: TStyleTextOptions;
begin
  if StyleServices.Enabled then
  begin
    Opt.TextColor := Self.Font.Color;
    StyleServices.DrawText(Handle, Details, Text, Rect, Format, Opt);
  end;
end;
{$endif}

procedure {$ifdef VER210UP}TEsCanvasHelper{$else}TEsCanvas{$endif}
  .DrawInsideFrame(R: TRect; Width: Integer; Color: TColor = clNone);
var
  ColorPen: HPen;
begin
  if Color = clNone then
    Color := Pen.Color;

  ColorPen := CreatePen(PS_INSIDEFRAME or PS_SOLID, Width, Color);
  SelectObject(Handle, ColorPen);
  SelectObject(Handle, GetStockObject(NULL_BRUSH));

  Windows.Rectangle(Handle, R.Left, R.Top, R.Right, R.Bottom);

  SelectObject(Handle, GetStockObject(NULL_PEN));
  DeleteObject(ColorPen);
end;

//procedure {$ifdef VER210UP}TEsCanvasHelper{$else}TEsCanvas{$endif}
//  .StretchDraw(DestRect, ClipRect, SrcRect: TRect; Bitmap: TBitmap; Alpha: byte);
//var
//  BF: TBlendFunction;
//begin
//  if not IntersectRect(DestRect, ClipRect) then
//    exit;
//
//  BF.BlendOp := AC_SRC_OVER;
//  BF.BlendFlags := 0;
//  BF.SourceConstantAlpha := Alpha;
//  BF.AlphaFormat := AC_SRC_ALPHA;
//
//  // Cutting
//  //---
//  // Left:
//  if DestRect.Left < ClipRect.Left then
//  begin
//    // |----*-------|
//    // (Numerator * Number) / den
//    SrcRect.Left := SrcRect.Left + Trunc((SrcRect.Right - SrcRect.Left) * ((ClipRect.Left - DestRect.Left) / (DestRect.Right - DestRect.Left)));
//    DestRect.Left := ClipRect.Left;
//  end;
//  // Right
//  if DestRect.Right > ClipRect.Right then
//  begin
//    // |----*-------|
//    // (Numerator * Number) / den
//    SrcRect.Right := SrcRect.Right - Trunc((SrcRect.Right - SrcRect.Left) * ((DestRect.Right - ClipRect.Right) / (DestRect.Right - DestRect.Left)));
//    DestRect.Right := ClipRect.Right;
//  end;
//
//
//  AlphaBlend(Handle, DestRect.Left, DestRect.Top, DestRect.Right - DestRect.Left, DestRect.Bottom - DestRect.Top,
//    Bitmap.Canvas.Handle, SrcRect.Left, SrcRect.Top, SrcRect.Right - SrcRect.Left, SrcRect.Bottom - SrcRect.Top, BF);
//end;

// REFACTOR ME PLEASE !!!
// TOOOOOOOOOO LONG PROCEDURE
// FFFFUUUUU!!!!1111
procedure {$ifdef VER210UP}TEsCanvasHelper{$else}TEsCanvas{$endif}
  .DrawNinePatch(Dest, Bounds: TRect; Bitmap: TBitmap; Mode: TStretchMode;
  Opacity: Byte);
var
  dx, dy: Integer;
  D, S: TRect;
  IntD, IntS: TRect;
  W, H, X, Y: Integer;
begin
  if (Dest.Left >= Dest.Right)or(Dest.Top >= Dest.Bottom) then
    exit;

  if (Mode = TStretchMode.smHorzTileFit) or (Mode = TStretchMode.smHorzFit) then
  begin
    H := Bitmap.Height;
    Y := (Dest.Top + Dest.Bottom) div 2;
    Dest := Rect(Dest.Left, Y - H div 2, Dest.Right, Y + H - (H div 2));
  end else
  if (Mode = TStretchMode.smVertTileFit) or (Mode = TStretchMode.smVertFit) then
  begin
    W := Bitmap.Width;
    X := (Dest.Left + Dest.Right) div 2;
    Dest := Rect(X - W div 2, Dest.Top, X + W - (W div 2), Dest.Bottom);
  end;

  if (Mode = TStretchMode.smNormal) or (Mode = TStretchMode.smHorzFit) or (Mode = TStretchMode.smVertFit) then
  begin
    DrawNinePatch(Dest, Bounds, Bitmap, Opacity);
    Exit;
  end;

  IntD := Rect(Dest.Left + Bounds.Left, Dest.Top + Bounds.Top,
    Dest.Right - Bounds.Right, Dest.Bottom - Bounds.Bottom);
  IntS := Rect(Bounds.Left, Bounds.Top, Bitmap.Width - Bounds.Right, Bitmap.Height - Bounds.Bottom);

  // needs to adjust to get rid of overdraw and painting was correct
  // cut left
  if Dest.Right - Dest.Left < Bounds.Left then
  begin
    dx := Bounds.Left - (Dest.Right - Dest.Left);
    IntD.Left := IntD.Left - dx;
    IntS.Left := IntS.Left - dx;
    //
    IntD.Right := Dest.Right;
  end else
  // cut right
  if Dest.Right - Dest.Left < Bounds.Left + Bounds.Right then
  begin
    dx := (Bounds.Left + Bounds.Right) - (Dest.Right - Dest.Left);
    IntD.Right := IntD.Right + dx;
    IntS.Right := IntS.Right + dx;
  end;
  // cut top
  if Dest.Bottom - Dest.Top < Bounds.Top then
  begin
    dy := Bounds.Top - (Dest.Bottom - Dest.Top);
    IntD.Top := IntD.Top - dy;
    IntS.Top := IntS.Top - dy;
    //
    IntD.Bottom := Dest.Bottom;
  end else
  // cut bottom
  if Dest.Bottom - Dest.Top < Bounds.Top + Bounds.Bottom then
  begin
    dy := (Bounds.Top + Bounds.Bottom) - (Dest.Bottom - Dest.Top);
    IntD.Bottom := IntD.Bottom + dy;
    IntS.Bottom := IntS.Bottom + dy;
  end;

//  // correct!
//  if IntD.Left > Dest.Right then
//    IntD.Left := Dest.Right;
//  if IntD.Top > Dest.Bottom then
//    IntD.Top := Dest.Bottom;
//  if IntD.Right < Dest.Left then
//    IntD.Right := Dest.Left;
//  if IntD.Bottom < Dest.Top then
//    IntD.Bottom := Dest.Top;

  if (Mode = TStretchMode.smHorzTile) or (Mode = TStretchMode.smHorzTileFit) then
  begin
    // Left Top
    D := Rect(Dest.Left, Dest.Top, IntD.Left, IntD.Top);
    S := Rect(0, 0, IntS.Left, IntS.Top);
    if ValidRect(D) then
      StretchDraw(D, S, Bitmap, Opacity);
    // Left Center
    D := Rect(Dest.Left, IntD.Top, IntD.Left, IntD.Bottom);
    S := Rect(0, IntS.Top, IntS.Left, IntS.Bottom);
    StretchDraw(D, S, Bitmap, Opacity);
    // Left Bottom
    D := Rect(Dest.Left, IntD.Bottom, IntD.Left, Dest.Bottom);
    S := Rect(0, IntS.Bottom, IntS.Left, Bitmap.Height);
    if ValidRect(D) then
      StretchDraw(D, S, Bitmap, Opacity);
    // Right Bottom
    D := Rect(IntD.Right, IntD.Bottom, Dest.Right, Dest.Bottom);
    S := Rect(IntS.Right, IntS.Bottom, Bitmap.Width, Bitmap.Height);
    if ValidRect(D) then
      StretchDraw(D, S, Bitmap, Opacity);
    // Right Center
    D := Rect(IntD.Right, IntD.Top, Dest.Right, IntD.Bottom);
    S := Rect(IntS.Right, IntS.Top, Bitmap.Width, IntS.Bottom);
    StretchDraw(D, S, Bitmap, Opacity);
    // Right Top
    D := Rect(IntD.Right, Dest.Top, Dest.Right, IntD.Top);
    S := Rect(IntS.Right, 0, Bitmap.Width, IntS.Top);
    if ValidRect(D) then
      StretchDraw(D, S, Bitmap, Opacity);
    // [ I I I ]
    X := IntD.Left;
    W := RectWidth(IntS);
    if W > 0 then
      while X + W <= IntD.Right do
      begin
        // up
        D := Rect(X, Dest.Top, X + W, IntD.Top);
        S := Rect(IntS.Left, 0, IntS.Right, IntS.Top);
        if ValidRect(D) then
          StretchDraw(D, S, Bitmap, Opacity);
        // center
        D := Rect(X, IntD.Top, X + W, IntD.Bottom);
        S := Rect(IntS.Left, IntS.Top, IntS.Right, IntS.Bottom);
        StretchDraw(D, S, Bitmap, Opacity);
        // down
        D := Rect(X, IntD.Bottom, X + W, Dest.Bottom);
        S := Rect(IntS.Left, IntS.Bottom, IntS.Right, Bitmap.Height);
        if ValidRect(D) then
          StretchDraw(D, S, Bitmap, Opacity);
        X := X + W;
      end;
    // cut up
    D := Rect(X, Dest.Top, IntD.Right, IntD.Top);
    S := Rect(IntS.Left, 0, IntS.Left + (IntD.Right - X), IntS.Top);
    if ValidRect(D) then
      StretchDraw(D, S, Bitmap, Opacity);
    // cut center
    D := Rect(X, IntD.Top, IntD.Right, IntD.Bottom);
    S := Rect(IntS.Left, IntS.Top, IntS.Left + (IntD.Right - X), IntS.Bottom);
    StretchDraw(D, S, Bitmap, Opacity);
    // cut down
    D := Rect(X, IntD.Bottom, IntD.Right, Dest.Bottom);
    S := Rect(IntS.Left, IntS.Bottom, IntS.Left + (IntD.Right - X), Bitmap.Height);
    if ValidRect(D) then
      StretchDraw(D, S, Bitmap, Opacity);
  end else
  if (Mode = TStretchMode.smVertTile) or (Mode = TStretchMode.smVertTileFit) then
  begin
    // Top Left
    D := Rect(Dest.Left, Dest.Top, IntD.Left, IntD.Top);
    S := Rect(0, 0, IntS.Left, IntS.Top);
    if ValidRect(D) then
      StretchDraw(D, S, Bitmap, Opacity);
    // Top Right
    D := Rect(IntD.Right, Dest.Top, Dest.Right, IntD.Top);
    S := Rect(IntS.Right, 0, Bitmap.Width, IntS.Top);
    if ValidRect(D) then
      StretchDraw(D, S, Bitmap, Opacity);
    // Top Center
    D := Rect(IntD.Left, Dest.Top, IntD.Right, IntD.Top);
    S := Rect(IntS.Left, 0, IntS.Right, IntS.Top);
    StretchDraw(D, S, Bitmap, Opacity);
    // Bottom Left
    D := Rect(Dest.Left, IntD.Bottom, IntD.Left, Dest.Bottom);
    S := Rect(0, IntS.Bottom, IntS.Left, Bitmap.Height);
    if ValidRect(D) then
      StretchDraw(D, S, Bitmap, Opacity);
    // Bottom Center
    D := Rect(IntD.Left, IntD.Bottom, IntD.Right, Dest.Bottom);
    S := Rect(IntS.Left, IntS.Bottom, IntS.Right, Bitmap.Height);
    StretchDraw(D, S, Bitmap, Opacity);
    // Bottom Right
    D := Rect(IntD.Right, IntD.Bottom, Dest.Right, Dest.Bottom);
    S := Rect(IntS.Right, IntS.Bottom, Bitmap.Width, Bitmap.Height);
    if ValidRect(D) then
      StretchDraw(D, S, Bitmap, Opacity);
    // [ I I I ]
    Y := IntD.Top;
    H := RectHeight(IntS);
    if H > 0 then
      while Y + H <= IntD.Bottom do
      begin
        // left
        D := Rect(Dest.Left, Y, IntD.Left, Y + H);
        S := Rect(0, IntS.Top, IntS.Left, IntS.Bottom);
        if ValidRect(D) then
          StretchDraw(D, S, Bitmap, Opacity);
        // center
        D := Rect(IntD.Left, Y, IntD.Right, Y + H);
        S := Rect(IntS.Left, IntS.Top, IntS.Right, IntS.Bottom);
        StretchDraw(D, S, Bitmap, Opacity);
        // right
        D := Rect(IntD.Right, Y, Dest.Right, Y + H);
        S := Rect(IntS.Right, IntS.Top, Bitmap.Width, IntS.Bottom);
        if ValidRect(D) then
          StretchDraw(D, S, Bitmap, Opacity);
        Y := Y + H;
      end;
    // cut left
    D := Rect(Dest.Left, Y, IntD.Left, IntD.Bottom);
    S := Rect(0, IntS.Top, IntS.Left, IntS.Top + (IntD.Bottom - Y));
    if ValidRect(D) then
      StretchDraw(D, S, Bitmap, Opacity);
    // cut center
    D := Rect(IntD.Left, Y, IntD.Right, IntD.Bottom);
    S := Rect(IntS.Left, IntS.Top, IntS.Right, IntS.Top + (IntD.Bottom - Y));
    StretchDraw(D, S, Bitmap, Opacity);
    // cut right
    D := Rect(IntD.Right, Y, Dest.Right, IntD.Bottom);
    S := Rect(IntS.Right, IntS.Top, Bitmap.Width, IntS.Top + (IntD.Bottom - Y));
    if ValidRect(D) then
      StretchDraw(D, S, Bitmap, Opacity);
  end else
  if (Mode = TStretchMode.smTile) then
  begin
    if (Bitmap.Width <> 0)and(Bitmap.Height <> 0) then
    begin
      Y := Dest.Top;
      repeat
        if Y + Bitmap.Height <= Dest.Bottom then
          H := Bitmap.Height
        else
          H := Dest.Bottom - Y;
        X := Dest.Left;
        repeat
          if X + Bitmap.Width <= Dest.Right  then
            W := Bitmap.Width
          else
            W := Dest.Right - X;

          StretchDraw(Rect(X, Y, X + W, Y + H), Rect(0, 0, W, H), Bitmap, Opacity);
          X := X + Bitmap.Width;
        until X >= Dest.Right;
        Y := Y + Bitmap.Height;
      until Y >= Dest.Bottom;
    end;
  end;
end;

procedure {$ifdef VER210UP}TEsCanvasHelper{$else}TEsCanvas{$endif}
  .DrawTransparentFrame(R: TRect; Color1, Color2: TColor; Opacity: Integer = -1; const Mask: ShortString = '12');
var
  C1, C2, DrawColor: TColor;
  Temp, X, Y: Integer;
  Index, Count: Integer;

  function MakeColor24(Dest: TColor; Src: TColor): TColor; inline;
  begin
    TRGBQuad(Result).rgbRed := (TRGBQuad(Dest).rgbRed *
      (255 - TRGBQuad(Src).rgbReserved) + TRGBQuad(Src).rgbRed * TRGBQuad(Src).rgbReserved) div 255;
    TRGBQuad(Result).rgbBlue := (TRGBQuad(Dest).rgbBlue *
      (255 - TRGBQuad(Src).rgbReserved) + TRGBQuad(Src).rgbBlue * TRGBQuad(Src).rgbReserved) div 255;
    TRGBQuad(Result).rgbGreen := (TRGBQuad(Dest).rgbGreen *
      (255 - TRGBQuad(Src).rgbReserved) + TRGBQuad(Src).rgbGreen * TRGBQuad(Src).rgbReserved) div 255;
    TRGBQuad(Result).rgbReserved := 0;
  end;

  function GetColor: TColor;
  begin
    if Mask[Index] = '1' then
      Result := C1
    else
    if Mask[Index] = '2' then
      Result := C2
    else
      Result := 0;

    Inc(Index);
    if Index > Count then
      Index := 1;
  end;
begin
  Count := Length(Mask);
  if Count = 0 then
    Exit;
  Index := 1;

  if Opacity <> -1 then
  begin
    C1 := ColorToRgb(Color1) or (Opacity shl 24);
    C2 := ColorToRgb(Color2) or (Opacity shl 24);
  end else
  begin
    C1 := Color1;
    C2 := Color2;
  end;

//  Bitmap := TBitmap.Create;
//  try
//    Bitmap.PixelFormat := pf32bit;
//    Bitmap.AlphaFormat := afDefined;
//    Bitmap.SetSize(4, 4);
//    // frame
//    SetPixel(0, 0, C1);
//    SetPixel(1, 0, C2);
//    SetPixel(2, 0, C1);
//    SetPixel(3, 0, C2);
//    SetPixel(3, 1, C1);
//    SetPixel(3, 2, C2);
//    SetPixel(3, 3, C1);
//    SetPixel(2, 3, C2);
//    SetPixel(1, 3, C1);
//    SetPixel(0, 3, C2);
//    SetPixel(0, 2, C1);
//    SetPixel(0, 1, C2);
//    // center
//    SetPixel(1, 1, 0);
//    SetPixel(1, 2, 0);
//    SetPixel(2, 1, 0);
//    SetPixel(2, 2, 0);
//
//    if (Alpha >= 0) and (Alpha <= 255) then
//      DrawNinePatch(R, Rect(2, 2, 2, 2), Bitmap, TStretchMode.smTile, Alpha)
//    else
//      DrawNinePatch(R, Rect(1, 1, 1, 1), Bitmap, TStretchMode.smTile, 255);
//  finally
//    Bitmap.Free;
//  end;

  if R.Left > R.Right then
  begin
    Temp := R.Right;
    R.Right := R.Left;
    R.Left := Temp;
  end;
  Dec(R.Right);
  if R.Top > R.Bottom then
  begin
    Temp := R.Bottom;
    R.Bottom := R.Top;
    R.Top := Temp;
  end;
  Dec(R.Bottom);

  for X := R.Left to R.Right - 1 do
  begin
    DrawColor := GetColor;
    if DrawColor <> 0 then
      Pixels[X, R.Top] := MakeColor24(Pixels[X, R.Top], DrawColor);
  end;

  for Y := R.Top to R.Bottom - 1do
  begin
    DrawColor := GetColor;
    if DrawColor <> 0 then
      Pixels[R.Right, Y] := MakeColor24(Pixels[R.Right, Y], DrawColor);
  end;

  if R.Bottom <> R.Top then
    for X := R.Right downto R.Left + 1 do
    begin
      DrawColor := GetColor;
      if DrawColor <> 0 then
        Pixels[X, R.Bottom] := MakeColor24(Pixels[X, R.Bottom], DrawColor);
    end
  else
    Pixels[R.Right, R.Top] := MakeColor24(Pixels[R.Right, R.Top], GetColor);

  if R.Right <> R.Left then
    for Y := R.Bottom downto R.Top + 1 do
    begin
      DrawColor := GetColor;
      if DrawColor <> 0 then
        Pixels[R.Left, Y] := MakeColor24(Pixels[R.Left, Y], DrawColor);
    end
  else
    Pixels[R.Right, R.Bottom] := MakeColor24(Pixels[R.Right, R.Bottom], GetColor);
end;

procedure {$ifdef VER210UP}TEsCanvasHelper{$else}TEsCanvas{$endif}
  .Restore(var State: TCanvasSaver);
begin
  State.Free;
  State := nil;
end;

function {$ifdef VER210UP}TEsCanvasHelper{$else}TEsCanvas{$endif}
  .SaveAll: TCanvasSaver;
begin
  Result := TCanvasSaver.Create(Self);
  Result.Font := Font;
  Result.Brush := Brush;
  Result.Pen := Pen;
end;

function {$ifdef VER210UP}TEsCanvasHelper{$else}TEsCanvas{$endif}
  .SaveBrush: TCanvasSaver;
begin
  Result := TCanvasSaver.Create(Self);
  Result.Brush := Brush;
end;

function {$ifdef VER210UP}TEsCanvasHelper{$else}TEsCanvas{$endif}
  .SaveFont: TCanvasSaver;
begin
  Result := TCanvasSaver.Create(Self);
  Result.Font := Font;
end;

function {$ifdef VER210UP}TEsCanvasHelper{$else}TEsCanvas{$endif}
  .SavePen: TCanvasSaver;
begin
  Result := TCanvasSaver.Create(Self);
  Result.Pen := Pen;
end;

type
  THackGraphic = class(TGraphic);

procedure {$ifdef VER210UP}TEsCanvasHelper{$else}TEsCanvas{$endif}
  .StretchDraw(Rect: TRect; Graphic: TGraphic; Opacity: Byte);
var
  Bitmap: TBitmap;
begin
  if Graphic <> nil then
  begin
    Changing;
    RequiredState([csHandleValid]);
    if Opacity = 255 then
      THackGraphic(Graphic).Draw(Self, Rect)
    else
      // for Opacity <> 255
      if Graphic is TBitmap then
      begin
        // god scenary
        THackGraphic(Graphic).DrawTransparent(Self, Rect, Opacity);
      end
      else
      begin
        // bed, we create temp buffer, it is slowly :(
        Bitmap := TBitmap.Create;
        try
          GraphicAssignToBitmap(Bitmap, Graphic);
          StretchDraw(Rect, Bitmap, Opacity);
        finally
          Bitmap.Free;
        end;
      end;

    Changed;
  end;
end;

{TEsBitMap}

{$ifdef VER210UP} {$REGION 'Old delphi support'} {$endif}
{$ifndef VER210UP}
procedure TEsBitMap.PreMultiplyAlpha;
var
  x, y: integer;
  TripleAlpha: double;
  pBmp: pRGBAArray;
  Alpha: word;
begin
  if PixelFormat <> pf32bit then exit;
  for y := 0 to Height-1 do
    begin
    pBmp := ScanLine[y];
    for x := 0 to Width-1 do
      begin
        Alpha := pBmp[x].rgbReserved;
        pBmp[x].rgbRed := MulDiv(pBmp[x].rgbRed, Alpha, 255);
        pBmp[x].rgbGreen := MulDiv(pBmp[x].rgbGreen, Alpha, 255);
        pBmp[x].rgbBlue := MulDiv(pBmp[x].rgbBlue, Alpha, 255);
      end;
    end;
end;

procedure TEsBitMap.UnPreMultiplyAlpha;
var
  x, y: integer;
  TripleAlpha: double;
  pBmp: pRGBAArray;
  Alpha: word;
begin
  if PixelFormat <> pf32bit then exit;
  for y := 0 to Height-1 do
    begin
    pBmp := ScanLine[y];
    for x := 0 to Width-1 do
      begin
        Alpha := pBmp[x].rgbReserved;
        pBmp[x].rgbRed := MulDiv(pBmp[x].rgbRed, 255, Alpha);
        pBmp[x].rgbGreen := MulDiv(pBmp[x].rgbGreen, 255, Alpha);
        pBmp[x].rgbBlue := MulDiv(pBmp[x].rgbBlue, 255, Alpha);
      end;
    end;
end;
{$endif}
{$ifdef VER210UP} {$ENDREGION} {$endif}

constructor TEsBitMap.Create;
begin
  inherited;
  {$ifdef VER210UP}
  self.AlphaFormat := afDefined;
  {$endif}
  self.PixelFormat := pf32bit;
end;

procedure TEsBitMap.LoadFromResourceName(Instance: THandle;
  const ResName: String; ResType: PChar);
var
  Stream: TResourceStream;
begin
  Stream := TResourceStream.Create(Instance, ResName, ResType);
  try
    self.LoadFromStream(Stream);
  finally
    Stream.Free;
  end;
end;

end.
