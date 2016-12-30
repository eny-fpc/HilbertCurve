{
  This unit contains the TGradientsFiller component to paint different kinds of gradients.
  TGradientsFiller v0.9.
  Lazarus: 0.9.31 (28833) / Win32; FPC 2.4.3.

  TGradientsFiller is based on the excellent Delphi TGradient component at Delphi Area.

  Delphi component:
   TGradient v2.62
   by Kambiz R. Khojasteh
   kambiz@delphiarea.com
   http://www.delphiarea.com

  Usage:
    // The example below displays a rectangular gradient on a Form's canvas.
    var Gradient: TGradientsFiller;
    //...
    // Create a gradients filler object
    Gradient := TGradientsFiller.Create(clBLue, clBlack);
    Gradient.Style := gsRadialRect;
    //...
    // Then for example in the OnPaint event of a TPaintbox:
    PaintBox1.Canvas.StretchDraw( rect(0,0,PaintBox1.ClientWidth,PaintBox1.ClientHeight),
                                  Gradient.Bitmap);

    Five properties change the behaviour of the gradient:
    1. Shift (-100..100): moves the overall gradient pattern more tot the start end color
    2. Rotation (-100..100): rotate the colors in the gradient.
    3. Reversed: swap the colors.
    4. ColorBegin: the first color of the gradient.
    5. ColrEnd: the last color of the gradient.


  Note: the custom gradient pattern is not (yet) implemented.

  Copyright (C) 2011 G.A. Nijland lemjeu@gmail.com

  This source is free software; you can redistribute it and/or modify it under the terms
  of the GNU General Public License as published by the Free Software Foundation; either
  version 2 of the License, or (at your option) any later version.

  This code is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
  without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
  PURPOSE. See the GNU General Public License for more details.

  A copy of the GNU General Public License is available on the World Wide Web at
  <http://www.gnu.org/copyleft/gpl.html>. You can also obtain it by writing to the Free
  Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
}
unit GradientsFiller;

{$mode objfpc}{$H+}

interface

uses
  LCLType, FPImage, IntfGraphics,
  Graphics,
  Classes, SysUtils; 

type
  // Buffer for a color gradient with all possible gradients from 0 to 255.
  TGradientColors = array[0..255] of TRGBQuad;

  // Limit shift and rotation to keep valid results
  TGradientShift    = -100..100;
  TGradientRotation = -100..100;

  // All available gradient styles
  TGradientStyle = (gsCustom,
                    gsRadialC,    gsRadialT,    gsRadialB,    gsRadialL,
                    gsRadialR,    gsRadialTL,   gsRadialTR,   gsRadialBL,   gsRadialBR,
                    gsLinearH,    gsLinearV,
                    gsReflectedH, gsReflectedV,
                    gsDiagonalLF, gsDiagonalLB, gsDiagonalRF, gsDiagonalRB,
                    gsArrowL,     gsArrowR,     gsArrowU,     gsArrowD,
                    gsDiamond,    gsButterfly,  gsRadialRect);

  { TColorGradient }
  //
  // TColorGradient is a support class that calculates all in between
  // colors (the gradient) when going from one color to another.
  //
  TColorGradient = class
  private
    FColors    : TGradientColors;
    FReverse   : boolean;
    FShift     : integer;
    FRotation  : integer;
    FColorBegin: TColor;
    FColorEnd  : TColor;
    FDirty     : boolean;

    procedure SetColorBegin(const pValue: TColor);
    procedure SetColorEnd(const pValue: TColor);
    procedure SetReverse(const pValue: boolean);
    procedure SetRotation(const pValue: integer);
    procedure SetShift(const pValue: integer);

  protected
    property Dirty: boolean read FDirty;

  public
    constructor Create;
    constructor Create(const pColorBegin, pColorEnd: TColor);

    procedure Update;
    function Color(const pIndex: integer): TRGBQuad;
    function ColorAsFPColor(const pIndex: integer): TFPColor;

    property ColorBegin: TColor read FColorBegin write SetColorBegin;
    property ColorEnd  : TColor read FColorEnd write SetColorEnd;
    property Shift: integer read FShift write SetShift;
    property Rotation: integer read FRotation write SetRotation;
    property Reverse: boolean read FReverse write SetReverse;
  end;

  { TGradientsFiller }

  TGradientsFiller = class
  private
    // Storage of the color range from start to end
    FColors: TColorGradient;

    // Lazarus access to pixel data goes via 2 classes
    FBitmap : TBitmap;
    FPattern: TLazIntfImage;

    FStyle: TGradientStyle;
    FDirty: boolean;

    // Precalculate arrays for efficient triangular calculation
    PreCalcXs    : array[0..180] of integer;
    PreCalcXsRev : array[0..180] of integer;

    function GetBitmap: TBitmap;
    function GetColorBegin: TColor;
    function GetColorEnd: TColor;
    function GetReverse: boolean;
    function GetRotation: integer;
    function GetShift: integer;
    procedure SetColorBegin(const pValue: TColor);
    procedure SetColorEnd(const pValue: TColor);
    procedure SetReverse(const pValue: boolean);
    procedure SetRotation(const pValue: integer);
    procedure SetShift(const pValue: integer);
    procedure SetStyle(const pValue: TGradientStyle);

    function Dirty: boolean;
    procedure RefreshPattern;

    // All available gradient implementations
    procedure RadialRect;
    procedure RadialCentral;
    procedure RadialTop;
    procedure RadialBottom;
    procedure RadialLeft;
    procedure RadialRight;
    procedure RadialTopLeft;
    procedure RadialTopRight;
    procedure RadialBottomLeft;
    procedure RadialBottomRight;
    procedure LinearHorizontal;
    procedure LinearVertical;
    procedure ReflectedHorizontal;
    procedure ReflectedVertical;
    procedure DiagonalLinearForward;
    procedure DiagonalLinearBackward;
    procedure DiagonalReflectedForward;
    procedure DiagonalReflectedBackward;
    procedure ArrowLeft;
    procedure ArrowRight;
    procedure ArrowUp;
    procedure ArrowDown;
    procedure Diamond;
    procedure Butterfly;

    property Pattern: TLazIntfImage read FPattern;

  public
    constructor Create;
    constructor Create(const pColorFrom, pColorTo: TColor);
    destructor Destroy; override;

    property Style: TGradientStyle read FStyle write SetStyle;
    property Bitmap: TBitmap read GetBitmap;

    // Public embedded TColorGradient properties
    property ColorBegin: TColor read GetColorBegin write SetColorBegin;
    property ColorEnd  : TColor read GetColorEnd write SetColorEnd;
    property Shift: integer read GetShift write SetShift;
    property Rotation: integer read GetRotation write SetRotation;
    property Reverse: boolean read GetReverse write SetReverse;
  end;


const
  C_STYLE_DESCRIPTION: array[TGradientStyle] of string =
    ( 'Custom - OnCustom event (gsCustom)',
      'Radial - Central (gsRadialC)',
      'Radial - Top (gsRadialT)',
      'Radial - Bottom (gsRadialB)',
      'Radial - Left (gsRadialL)',
      'Radial - Right (gsRadialR)',
      'Radial - Top Left (gsRadialTL)',
      'Radial - Top Right (gsRadialTR)',
      'Radial - Bottom Left (gsRadialBL)',
      'Radial - Bottom Right (gsRadialBR)',
      'Linear - Horizontal (gsLinearH)',
      'Linear - Vertical (gsLinearV)',
      'Reflected - Horizontal (gsReflectedH)',
      'Reflected - Vertical (gsReflectedV)',
      'Diagonal - Linear Forward (gsDiagonalLF)',
      'Diagonal - Linear Backward (gsDiagonalLB)',
      'Diagonal - Reflected Forward (gsDiagonalRF)',
      'Diagonal - Reflected Backward (gsDiagonalRB)',
      'Arrow - Left (gsArrowL)',
      'Arrow - Right (gsArrowR)',
      'Arrow - Up (gsArrowU)',
      'Arrow - Down (gsArrowD)',
      'Diamond (gsDiamond)',
      'Butterfy (gsButterfly)',
      'Radial - Rectangular (gsRadialRect)'
    );


implementation

{ TColorGradient }

procedure TColorGradient.SetColorBegin(const pValue: TColor);
begin
  if FColorBegin = pValue then exit;
  FColorBegin := pValue;
  FDirty := true
end;

procedure TColorGradient.SetColorEnd(const pValue: TColor);
begin
  if FColorEnd = pValue then exit;
  FColorEnd := pValue;
  FDirty := true
end;

procedure TColorGradient.SetReverse(const pValue: boolean);
begin
  if FReverse = pValue then exit;
  FReverse := pValue;
  FDirty := true;
end;

procedure TColorGradient.SetRotation(const pValue: integer);
begin
  if FRotation = pValue then exit;
  FRotation := pValue;
  FDirty := true
end;

procedure TColorGradient.SetShift(const pValue: integer);
begin
  if FShift = pValue then exit;
  FShift := pValue;
  FDirty := true
end;

constructor TColorGradient.Create;
begin
  Create(clWhite, clBlack)
end;

constructor TColorGradient.Create(const pColorBegin, pColorEnd: TColor);
begin
  ColorBegin := pColorBegin;
  ColorEnd   := pColorEnd;
end;

procedure TColorGradient.Update;
var
  dRed, dGreen, dBlue: Integer;
  RGB1, RGB2: TRGBQuad;
  PRGB : PRGBQuad;
  M    : Integer;

  procedure CalculateColors(const pFrom, pTo, pDiv, pSign: integer; var pRGB: TRGBQuad);
  var Index: integer;
  begin
    for Index := pFrom to pTo do
      with FColors[Index] do
      begin
        rgbRed   := pRGB.rgbRed   + pSign * ((Index * dRed)   div pDiv);
        rgbGreen := pRGB.rgbGreen + pSign * ((Index * dGreen) div pDiv);
        rgbBlue  := pRGB.rgbBlue  + pSign * ((Index * dBlue)  div pDiv);
      end
  end;

  procedure CalculateRotateColors(const pFrom, pTo, pSign, pM: integer; var pRGB: TRGBQuad);
  var Index, rIndex, rM: Integer;
  begin
    for Index := pFrom to pTo do
      with FColors[Index] do
      begin
        rIndex := 255 - Index;
        rM := 255 - pM;
        rgbRed   := pRGB.rgbRed   +  pSign * (((rIndex) * dRed)   div (rM));
        rgbGreen := pRGB.rgbGreen +  pSign * (((rIndex) * dGreen) div (rM));
        rgbBlue  := pRGB.rgbBlue  +  pSign * (((rIndex) * dBlue)  div (rM));
      end;
  end;

begin
  // Copy begin and end color to a RGBQuad structure
  if Reverse
    then RedGreenBlue(FColorEnd, RGB1.rgbRed, RGB1.rgbGreen, RGB1.rgbBlue)
    else RedGreenBlue(FColorBegin, RGB1.rgbRed, RGB1.rgbGreen, RGB1.rgbBlue);
  RGB1.rgbReserved := 0;
  if Reverse
    then RedGreenBlue(FColorBegin, RGB2.rgbRed, RGB2.rgbGreen, RGB2.rgbBlue)
    else RedGreenBlue(FColorEnd, RGB2.rgbRed, RGB2.rgbGreen, RGB2.rgbBlue);
  RGB2.rgbReserved := 0;

  // Calculate shift displacement
  if Shift <> 0 then
  begin
    if Shift > 0
      then PRGB := @RGB1
      else PRGB := @RGB2;
    PRGB^.rgbRed   := Byte(PRGB^.rgbRed   + MulDiv(RGB2.rgbRed - RGB1.rgbRed, Shift, 100));
    PRGB^.rgbGreen := Byte(PRGB^.rgbGreen + MulDiv(RGB2.rgbGreen - RGB1.rgbGreen, Shift, 100));
    PRGB^.rgbBlue  := Byte(PRGB^.rgbBlue  + MulDiv(RGB2.rgbBlue - RGB1.rgbBlue, Shift, 100));
  end;

  // Calculate RGB delta's
  dRed   := RGB2.rgbRed - RGB1.rgbRed;
  dGreen := RGB2.rgbGreen - RGB1.rgbGreen;
  dBlue  := RGB2.rgbBlue - RGB1.rgbBlue;

  // Incorporate color rotation
  M := MulDiv(255, Rotation, 100);
  if M = 0 then
    CalculateColors(0, 255, 255, 1, RGB1)
  else if M > 0 then
    begin
      M := 255 - M;
      CalculateColors(0, M-1, M, 1,RGB1);
      CalculateRotateColors(M,255,1,M,RGB1);
    end
  else if M < 0 then
    begin
      M := -M;
      CalculateColors(0,M,M,-1,RGB2);
      CalculateRotateColors(M+1, 255, -1, M, RGB2);
    end;

  // Calculations done, gradient is now OK.
  FDirty := false
end;

function TColorGradient.Color(const pIndex: integer): TRGBQuad;
begin
  // As soon as a color is requested, make sure the gradient is OK.
  // If not, request an update.
  if FDirty then Update;
  result := FColors[pIndex]
end;

function TColorGradient.ColorAsFPColor(const pIndex: integer): TFPColor;
begin
  with Color(pIndex) do
  begin
    result.red   := (rgbRed   shl 8) + rgbRed;
    result.green := (rgbGreen shl 8) + rgbGreen;
    result.blue  := (rgbBlue  shl 8) + rgbBlue;
  end;
  Result.Alpha := AlphaOpaque;
end;

{ TGradientsFiller }

function TGradientsFiller.GetColorBegin: TColor;
begin
  result := FColors.ColorBegin;
end;

function TGradientsFiller.GetBitmap: TBitmap;
begin
  if Dirty then RefreshPattern;
  result := FBitmap
end;

function TGradientsFiller.GetColorEnd: TColor;
begin
  result := FColors.ColorEnd;
end;

function TGradientsFiller.GetReverse: boolean;
begin
  result := FColors.Reverse;
end;

function TGradientsFiller.GetRotation: integer;
begin
  result := FColors.Rotation;
end;

function TGradientsFiller.GetShift: integer;
begin
  result := FColors.Shift;
end;

procedure TGradientsFiller.SetColorBegin(const pValue: TColor);
begin
  FColors.ColorBegin := pValue;
end;

procedure TGradientsFiller.SetColorEnd(const pValue: TColor);
begin
  FColors.ColorEnd := pValue;
end;

procedure TGradientsFiller.SetReverse(const pValue: boolean);
begin
  FColors.Reverse := pValue;
end;

procedure TGradientsFiller.SetRotation(const pValue: integer);
begin
  FColors.Rotation := pValue;
end;

procedure TGradientsFiller.SetShift(const pValue: integer);
begin
  FColors.Shift := pValue;
end;

constructor TGradientsFiller.Create;
begin
  Create(clBlack, clWhite);  // Default gradient
end;

constructor TGradientsFiller.Create(const pColorFrom, pColorTo: TColor);
var i: integer;
begin
  // Init local vars
  Style := gsRadialRect;

  // All colors in the range From...To
  FColors  := TColorGradient.Create(pColorFrom, pColorTo);

  // TBitmap is required to export the gradient pattern
  FBitmap  := TBitmap.Create;
  FBitmap.PixelFormat := pf24bit;

  // Initialize TLazIntfImage for processing (mandatory statements)
  FPattern := TLazIntfImage.Create(FBitmap.Width, FBitmap.Height);
  FPattern.LoadFromBitmap(FBitmap.Handle, FBitmap.MaskHandle);

  // Preset arrays for triangular calculation
  for i := 0 to 180 do
  begin
    PreCalcXs[i]          := i * i;
    PreCalcXsRev[180 - i] := i * i;
  end;
end;

destructor TGradientsFiller.Destroy;
begin
  FColors.Free;
  FPattern.Free;
  FBitmap.Free;
  inherited Destroy;
end;

procedure TGradientsFiller.SetStyle(const pValue: TGradientStyle);
begin
  if FStyle = pValue then exit;
  FStyle := pValue;
  FDirty := true;
end;

function TGradientsFiller.Dirty: boolean;
begin
  // Is the gradient pattern ór the color list dirty?
  result := FDirty or FColors.Dirty
end;

procedure TGradientsFiller.RefreshPattern;
begin
  // Refresh the pattern based on the style
  case Style of
    gsRadialC    : RadialCentral;
    gsRadialT    : RadialTop;
    gsRadialB    : RadialBottom;
    gsRadialL    : RadialLeft;
    gsRadialR    : RadialRight;
    gsRadialTL   : RadialTopLeft;
    gsRadialTR   : RadialTopRight;
    gsRadialBL   : RadialBottomLeft;
    gsRadialBR   : RadialBottomRight;
    gsRadialRect : RadialRect;
    gsLinearH    : LinearHorizontal;
    gsLinearV    : LinearVertical;
    gsReflectedH : ReflectedHorizontal;
    gsReflectedV : ReflectedVertical;
    gsDiagonalLF : DiagonalLinearForward;
    gsDiagonalLB : DiagonalLinearBackward;
    gsDiagonalRF : DiagonalReflectedForward;
    gsDiagonalRB : DiagonalReflectedBackward;
    gsArrowL     : ArrowLeft;
    gsArrowR     : ArrowRight;
    gsArrowU     : ArrowUp;
    gsArrowD     : ArrowDown;
    gsDiamond    : Diamond;
    gsButterfly  : Butterfly;
  else
    raise Exception.CreateFmt('Style %d not yet implemented!',[Style]);
  end; // style

  // Copy pattern to a bitmap for external access
  FBitmap.LoadFromIntfImage(FPattern);

  // Pattern is OK to use for future reference
  FDirty := false
end;

procedure TGradientsFiller.RadialRect;
var x, y : Integer;
    color: TFPColor;
begin
  FPattern.Width := 512;
  FPattern.Height := 512;

  for Y := 0 to 255 do
  begin
    color := FColors.ColorAsFPColor(y);
    for x:=Y to 511-y do
    begin
      FPattern.Colors[x,y]     := color;
      FPattern.Colors[x,511-y] := color;
    end;

    for x:=0 to y do
    begin
      color := FColors.ColorAsFPColor(x);
      FPattern.Colors[x,y]         := color;
      FPattern.Colors[x,511-y]     := color;
      FPattern.Colors[511-x,y]     := color;
      FPattern.Colors[511-x,511-y] := color;
     end
  end;
end;

procedure TGradientsFiller.RadialCentral;
var
  X, Y : Integer;
  Color: TFPColor;
begin
  Pattern.Width := 362;
  Pattern.Height := 362;

  for Y := 180 downto 0 do
  begin
    for X := 180 downto 0 do
    begin
      Color := FColors.ColorAsFPColor(Round(Sqrt(PreCalcXsRev[X] + PreCalcXsRev[Y])));
      Pattern.Colors[X,Y]         := Color;
      Pattern.Colors[361-X,Y]     := Color;
      Pattern.Colors[X,361-Y]     := Color;
      Pattern.Colors[361-X,361-Y] := Color;
    end;
  end;
end;

procedure TGradientsFiller.RadialTop;
var
  X, Y: Integer;
  PreCalcY: Integer;
  Color: TFPColor;
begin
  Pattern.Width := 362;
  Pattern.Height := 181;

  for Y := 180 downto 0 do
  begin
    PreCalcY := PreCalcXsRev[180-Y];
    for X := 180 downto 0 do
    begin
      Color := FColors.ColorAsFPColor(Round(Sqrt(PreCalcXsRev[X] + PreCalcY)));
      Pattern.Colors[X,Y]  := Color;
      Pattern.Colors[361-x,Y] := Color;
    end;
  end;
end;

procedure TGradientsFiller.RadialBottom;
var
  X, Y: Integer;
  PreCalcY: Integer;
  Color: TFPColor;
begin
  Pattern.Width := 362;
  Pattern.Height := 181;

  for Y := 180 downto 0 do
  begin
    PreCalcY := PreCalcXsRev[Y];
    for X := 180 downto 0 do
    begin
      Color := FColors.ColorAsFPColor(Round(Sqrt(PreCalcXsRev[X] + PreCalcY)));
      Pattern.Colors[X,Y]  := Color;
      Pattern.Colors[361-x,Y] := Color;
    end;
  end;
end;

procedure TGradientsFiller.RadialLeft;
var
  X, Y    : Integer;
  PreCalcY: Integer;
  Color   : TFPColor;
begin
  Pattern.Width := 181;
  Pattern.Height := 362;

  for Y := 0 to 180 do
  begin
    PreCalcY := PreCalcXs[180-Y];
    for X := 0 to 180 do
    begin
      Color := FColors.ColorAsFPColor(Round(Sqrt(PreCalcXs[X] + PreCalcY)));
      Pattern.Colors[X,Y] := Color;
      Pattern.Colors[X,361-Y] := color;
    end;
  end;
end;

procedure TGradientsFiller.RadialRight;
var
  X, Y    : Integer;
  PreCalcY: Integer;
  Color   : TFPColor;
begin
  Pattern.Width := 181;
  Pattern.Height := 362;

  for Y := 0 to 180 do
  begin
    PreCalcY := PreCalcXs[180-Y];
    for X := 0 to 180 do
    begin
      Color := FColors.ColorAsFPColor(Round(Sqrt(PreCalcXsRev[X] + PreCalcY)));
      Pattern.Colors[X,Y] := Color;
      Pattern.Colors[X,361-Y] := color;
    end;
  end;
end;

procedure TGradientsFiller.RadialTopLeft;
var
  X, Y: Integer;
begin
  Pattern.Width := 181;
  Pattern.Height := 181;

  for Y := 0 to 180 do
    for X := 0 to 180 do
      FPattern.Colors[X,Y] := FColors.ColorAsFPColor(Round(Sqrt(PreCalcXs[X] + PreCalcXs[Y])));
end;

procedure TGradientsFiller.RadialTopRight;
var
  X, Y: Integer;
begin
  Pattern.Width := 181;
  Pattern.Height := 181;

  for Y := 0 to 180 do
    for X := 0 to 180 do
      FPattern.Colors[X,Y] := FColors.ColorAsFPColor(Round(Sqrt(PreCalcXsRev[X] + PreCalcXs[Y])));
end;

procedure TGradientsFiller.RadialBottomLeft;
var
  X, Y: Integer;
begin
  Pattern.Width := 181;
  Pattern.Height := 181;

  for Y := 0 to 180 do
    for X := 0 to 180 do
      FPattern.Colors[X,180-Y] := FColors.ColorAsFPColor(Round(Sqrt(PreCalcXs[X] + PreCalcXs[Y])));
end;

procedure TGradientsFiller.RadialBottomRight;
var
  X, Y: Integer;
begin
  Pattern.Width := 181;
  Pattern.Height := 181;

  for Y := 0 to 180 do
    for X := 0 to 180 do
      FPattern.Colors[X,180-Y] := FColors.ColorAsFPColor(Round(Sqrt(PreCalcXs[180-X] + PreCalcXs[Y])));
end;

procedure TGradientsFiller.LinearHorizontal;
var X: Integer;
begin
  Pattern.Width := 256;
  Pattern.Height := 1;
  for X := 0 to 255 do
    FPattern.Colors[X,0] := FColors.ColorAsFPColor(X);
end;

procedure TGradientsFiller.LinearVertical;
var Y: Integer;
begin
  Pattern.Width := 1;
  Pattern.Height := 256;
  for Y := 0 to 255 do
    FPattern.Colors[0,Y] := FColors.ColorAsFPColor(Y);
end;

procedure TGradientsFiller.ReflectedHorizontal;
var Y: Integer;
begin
  Pattern.Width := 1;
  Pattern.Height := 512;
  for Y := 0 to 255 do
  begin
    FPattern.Colors[0,Y] := FColors.ColorAsFPColor(255-Y);
    FPattern.Colors[0,511-Y] := FColors.ColorAsFPColor(255-Y);
  end;
end;

procedure TGradientsFiller.ReflectedVertical;
var X: Integer;
begin
  Pattern.Width := 512;
  Pattern.Height := 1;
  for X := 0 to 255 do
  begin
    FPattern.Colors[X,0] := FColors.ColorAsFPColor(255-X);
    FPattern.Colors[511-X,0] := FColors.ColorAsFPColor(255-X);
  end;
end;

procedure TGradientsFiller.DiagonalLinearForward;
var X,Y: Integer;
begin
  Pattern.Width := 128;
  Pattern.Height := 129;
  for Y := 0 to 128 do
    for X := 0 to 127 do
      FPattern.Colors[X,Y] := FColors.ColorAsFPColor(X + Y);
end;

procedure TGradientsFiller.DiagonalLinearBackward;
var X,Y: Integer;
begin
  Pattern.Width := 128;
  Pattern.Height := 129;
  for Y := 0 to 128 do
    for X := 0 to 127 do
      FPattern.Colors[X,Y] := FColors.ColorAsFPColor(127 + (Y-X));
end;

procedure TGradientsFiller.DiagonalReflectedForward;
var X,Y: Integer;
begin
  Pattern.Width := 256;
  Pattern.Height := 256;
  for Y := 0 to 255 do
    for X := 0 to 255 do
      FPattern.Colors[X,Y] := FColors.ColorAsFPColor(abs(255 - (X + Y)))
end;

procedure TGradientsFiller.DiagonalReflectedBackward;
var X,Y: Integer;
begin
  Pattern.Width := 256;
  Pattern.Height := 256;
  for Y := 0 to 255 do
    for X := 0 to 255 do
      FPattern.Colors[X,Y] := FColors.ColorAsFPColor(abs(X - Y))
end;

procedure TGradientsFiller.ArrowLeft;
var X,Y: Integer;
begin
  Pattern.Width := 129;
  Pattern.Height := 256;
  for Y := 0 to 127 do
    for X := 0 to 128 do
    begin
      Pattern.Colors[X,Y]     := FColors.ColorAsFPColor(255 - (X + Y));
      Pattern.Colors[X,Y+128] := FColors.ColorAsFPColor(Y+128-X);
    end;
end;

procedure TGradientsFiller.ArrowRight;
var X,Y: Integer;
begin
  Pattern.Width := 129;
  Pattern.Height := 256;
  for Y := 0 to 127 do
    for X := 0 to 128 do
    begin
      Pattern.Colors[X,Y]     := FColors.ColorAsFPColor((X - Y) + 127);
      Pattern.Colors[X,Y+128] := FColors.ColorAsFPColor((X + Y)      );  // Y + 128 - 128
    end;
end;

procedure TGradientsFiller.ArrowUp;
var X,Y: Integer;
begin
  Pattern.Width := 256;
  Pattern.Height := 129;
  for Y := 0 to 128 do
    for X := 0 to 127 do
    begin
      Pattern.Colors[X,Y]     := FColors.ColorAsFPColor(255 - (X + Y));
      Pattern.Colors[X+128,Y] := FColors.ColorAsFPColor(X-Y + 128);
    end;
end;

procedure TGradientsFiller.ArrowDown;
var X,Y: Integer;
begin
  Pattern.Width := 256;
  Pattern.Height := 129;
  for Y := 0 to 128 do
    for X := 0 to 127 do
    begin
      Pattern.Colors[X,Y]     := FColors.ColorAsFPColor(127 + (Y-X));
      Pattern.Colors[X+128,Y] := FColors.ColorAsFPColor((X + Y) );   // X + 128 - 128
    end;
end;

procedure TGradientsFiller.Diamond;
var X,Y: Integer;
begin
  Pattern.Width := 256;
  Pattern.Height := 256;
  for Y := 0 to 127 do
    for X := 0 to 127 do
    begin
      Pattern.Colors[X,Y]         := FColors.ColorAsFPColor(255 - (X + Y));
      Pattern.Colors[X+128,Y]     := FColors.ColorAsFPColor((X+128) - Y);
      Pattern.Colors[X,Y+128]     := FColors.ColorAsFPColor((Y+128) - X);
      Pattern.Colors[X+128,Y+128] := FColors.ColorAsFPColor(((X+128) + (Y+128)) - 255);
    end;
end;

procedure TGradientsFiller.Butterfly;
var X,Y: Integer;
begin
  Pattern.Width := 256;
  Pattern.Height := 256;
  for Y := 0 to 127 do
    for X := 0 to 127 do
    begin
      Pattern.Colors[X,Y]         := FColors.ColorAsFPColor((X - Y) + 128);
      Pattern.Colors[X+128,Y]     := FColors.ColorAsFPColor(383 - ((X+128) + Y));
      Pattern.Colors[X,Y+128]     := FColors.ColorAsFPColor((X + (Y+128)) - 128);
      Pattern.Colors[X+128,Y+128] := FColors.ColorAsFPColor(128 + ((Y+128) - (X+128)));
    end;
end;

end.

