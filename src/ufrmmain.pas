{ Hilbert Curves demo program main form.

  Copyright (C) 2011 G.A. Nijland (lemjeu@gmail.com)

  This source is free software; you can redistribute it and/or modify it under the terms of the GNU General Public
  License as published by the Free Software Foundation; either version 2 of the License, or (at your option) any later
  version.

  This code is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied
  warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
  details.

  A copy of the GNU General Public License is available on the World Wide Web at
  <http://www.gnu.org/copyleft/gpl.html>. You can also obtain it by writing to the Free Software Foundation, Inc., 59
  Temple Place - Suite 330, Boston, MA 02111-1307, USA.
}

unit ufrmMain;

{$mode objfpc}{$H+}

interface

uses
  GradientsFiller, HCThread, HilbertCurves,
  Classes, SysUtils, FileUtil, LResources, Forms, Controls, Graphics, Dialogs,
  ExtCtrls, StdCtrls, ComCtrls, Buttons;

const
  C_MAX_DEPTH = 8;

type
  TCurveColors = array[0..C_MAX_DEPTH] of TColor;

  { TfrmMain }

  TfrmMain = class(TForm)
    bbDrawAll: TBitBtn;
    bbClearCanvas: TBitBtn;
    Button1: TButton;
    Button2: TButton;
    Button3: TButton;
    Button4: TButton;
    Button5: TButton;
    Button6: TButton;
    Button7: TButton;
    Button8: TButton;
    Button9: TButton;
    ColorDialog1: TColorDialog;
    Label1: TLabel;
    PaintBox1: TPaintBox;
    PaintBox2: TPaintBox;
    PaintBox3: TPaintBox;
    PaintBox4: TPaintBox;
    PaintBox5: TPaintBox;
    PaintBox6: TPaintBox;
    PaintBox7: TPaintBox;
    PaintBox8: TPaintBox;
    PaintBox9: TPaintBox;
    pbBackground: TPaintBox;
    pbCurve: TPaintBox;
    Panel1: TPanel;
    tbSpeed: TTrackBar;

    procedure bbClearCanvasClick(Sender: TObject);
    procedure ButtonDrawClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure ChangeCurveColorClick(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure PaintBox1Paint(Sender: TObject);
    procedure pbBackgroundPaint(Sender: TObject);
    procedure pbCurvePaint(Sender: TObject);
    procedure pbCurveResize(Sender: TObject);

  private
    { private declarations }
    isEndpoint: boolean;
    CurrentDepth: integer;
    BusyDrawing: boolean;

    GFH: TGradientsFiller;
    Shadow: TBitmap;
    Colors: TCurveColors;

    procedure ClearCanvas;
    procedure BeginNewDepth(const pDepth: integer);
    procedure InitPen(pCanvas: TCanvas; const pDepth: integer);
    procedure StartCurveDrawing(const pDepth: integer; const pDrawAll: boolean = false);
    procedure SlowDownDrawingSpeed;
    function GetDelay: integer;
    procedure DrawingDone;

  public
    { public declarations }
    procedure NewPoint(const pPoint: TCoordinate);
  end; 


var
  frmMain: TfrmMain;

implementation

{ TfrmMain }

procedure TfrmMain.FormCreate(Sender: TObject);
begin
  // Init the curves colors
  Colors[0] := clYellow;
  Colors[1] := clAqua;
  Colors[2] := clPurple;
  Colors[3] := clGreen;
  Colors[4] := RGBToColor(255,128,64); // Orange-ish
  Colors[5] := clwhite;
  Colors[6] := clRed;
  Colors[7] := clAqua;
  Colors[8] := RGBToColor(255,0,255); // Purple-ish

  // Init the gradinent filler for the form's background
  GFH := TGradientsFiller.Create(clBlue, clBlack);
  GFH.Style := gsButterfly;

  // Create a shadow image for the curves to be used in case of repaints
  Shadow := TBitmap.Create;
  Shadow.Width := pbCurve.ClientWidth;
  Shadow.Height := pbCurve.ClientHeight;
  Shadow.Canvas.StretchDraw(Rect(0,0,pbCurve.ClientWidth,pbCurve.ClientHeight),GFH.Bitmap);

  // Make the panel background cover the complete panel
  pbBackground.Align := alClient;
end;

procedure TfrmMain.ChangeCurveColorClick(Sender: TObject);
var i: integer;
begin
  // Determine the curve depth based on the control's tag and retrieve the color
  i := (Sender as TPaintBox).Tag;
  ColorDialog1.Color := Colors[i];

  if ColorDialog1.Execute then
  begin
    // Store the new color and display it as the new color
    Colors[i] := ColorDialog1.Color;
    (Sender as TPaintBox).Repaint;

    // When a curve is being drawn, the new color must be used as the pen's new color as well
    InitPen(pbCurve.Canvas, CurrentDepth);
    InitPen(Shadow.Canvas, CurrentDepth);
  end;
end;

procedure TfrmMain.FormShow(Sender: TObject);
begin
  // For demo purposes, draw a depth 5 curve when the main form is shown
  tbSpeed.Position := 1;
  Button5.OnClick(Button5);
end;

procedure TfrmMain.PaintBox1Paint(Sender: TObject);
begin
  // This paints the lines after each curve button.
  // Based on the depth (Tag property) a line with a certain width and color is drawn
  with Sender as TPaintBox do
  begin
    InitPen(Canvas,Tag);
    Canvas.Line(0,ClientHeight div 2,ClientWidth, ClientHeight div 2);
  end;
end;

procedure TfrmMain.pbBackgroundPaint(Sender: TObject);
begin
  // This is the background for the panel at the left side
  pbBackground.Canvas.StretchDraw(rect(0,0,pbBackground.ClientWidth,pbBackground.ClientHeight), GFH.Bitmap);
end;

procedure TfrmMain.pbCurvePaint(Sender: TObject);
begin
  // If the curve paintbox must be redrawn, i.e. when it was covered by something,
  // the copy from the shadow bitmap is used to restore the curve bitmap.
  if assigned(Shadow) then
    pbCurve.Canvas.Draw(0,0,Shadow);
end;

procedure TfrmMain.pbCurveResize(Sender: TObject);
var bmp: TBitMap;
begin
  // When the form is resized, the drawn image will be lost.
  // To get some fancy visual feedback, the current drawing is scaled to the new
  // size and that scaled image is used as the new curve image. If a curve is
  // currently being drawn, it will continue to do so.
  if assigned(Shadow) then
  begin
    bmp := TBitMap.Create;
    bmp.Width  := pbCurve.Width;   // Make the new bitmap the same size as the
    bmp.Height := pbCurve.Height;  // now resized curve paintbox.
    bmp.Canvas.StretchDraw(rect(0,0,bmp.Width,bmp.Height), Shadow);

    // Destroy the old shadow copy and use the newly created image as the
    // new 'shadow' version of what is currently drawn.
    Shadow.Free;
    Shadow := bmp
  end;
end;

procedure TfrmMain.bbClearCanvasClick(Sender: TObject);
begin
  ClearCanvas;
end;

procedure TfrmMain.ButtonDrawClick(Sender: TObject);
begin
  // Only start drawing when the previous drawing is finished.
  if BusyDrawing then
  begin
    if MessageDlg('A curve is being drawn; please wait or'#13#10 +
                  'press Cancel to quickly finish it.',
                  mtInformation, [mbOK, mbCancel], 0)
       = mrCancel
    then
      // Cancel pressed: set 'speed dial' to 0 for minimal delays
      tbSpeed.Position := 0;
    EXIT;
  end;

  // If the Draw All button is clicked then first clear the canvas.
  if Sender = bbDrawAll then
    ClearCanvas;

  // All 'Draw curve x' buttons call this method. Based on the Tag property
  // a curve is drawn for a certain depth.
  StartCurveDrawing((Sender as TComponent).Tag, Sender = bbDrawAll);
end;

procedure TfrmMain.ClearCanvas;
begin
  // Clear the painting area for a new curve. Also clear the shadow image with the background
  // because it might be used in repainting.
  pbCurve.Canvas.StretchDraw(rect(0,0,pbCurve.ClientWidth, pbCurve.ClientHeight), GFH.Bitmap);
  Shadow.Canvas.StretchDraw(rect(0,0,pbCurve.ClientWidth, pbCurve.ClientHeight), GFH.Bitmap);
end;

procedure TfrmMain.BeginNewDepth(const pDepth: integer);
begin
  // This method is called from the HC thread when a new curve drawing will be created.
  // This is the moment to init the pen for this particular depth.
  InitPen(pbCurve.Canvas, pDepth);
  InitPen(Shadow.Canvas, pDepth);

  // When drawing, the first point is not an endpoint, but the start point.
  // Therefore the variable below is set for future reference.
  isEndPoint := false;

  // And the current depth is stored for future reference as well.
  CurrentDepth := pDepth;
end;

procedure TfrmMain.InitPen(pCanvas: TCanvas; const pDepth: integer);
begin
  // The pen on the canvas is based on the depth i.e. the type of curve that is drawn.
  // The higher the depth, the thinner the pen.
  case pDepth of
    0 : pCanvas.Pen.Width := 7;
    1 : pCanvas.Pen.Width := 6;
    2 : pCanvas.Pen.Width := 5;
    3 : pCanvas.Pen.Width := 4;
    4 : pCanvas.Pen.Width := 3;
    5 : pCanvas.Pen.Width := 2;
  else
    pCanvas.Pen.Width := 1;
  end;

  // Every depth has it's own color.
  pCanvas.Pen.Color := Colors[pDepth];
end;

procedure TfrmMain.StartCurveDrawing(const pDepth: integer; const pDrawAll: boolean);
var hct: THCThread;
begin
  // Create the thread that will handle all calculations for the curve.
  hct := THCThread.Create(pDepth);
  hct.DoAllDepths := pDrawAll;
  hct.OnNewPoint := @NewPoint;
  hct.OnDepthStartEvent := @BeginNewDepth;
  hct.OnSlowDown := @SlowDownDrawingSpeed;
  hct.OnHCThreadDone := @DrawingDone;
  hct.Start;

  // All drawing is blocked until the thread is ready
  BusyDrawing := true;
end;

function TfrmMain.GetDelay: integer;
var slowdown: integer;
begin
  // The delay is based on the trackbar on screen.
  // The higher the value, the slower the lines will be drawn.
  if tbSpeed.Position = 0 then
    result := 0
  else
    begin
      case CurrentDepth of
        0: slowdown := 250;
        1: slowdown := 100;
        2: slowdown := 50;
        3: slowdown := 10;
        4: slowdown := 5;
        5: slowdown := 3;
      else
        slowdown := 1;
      end;
      result := slowdown * tbSpeed.Position;
    end;
end;

procedure TfrmMain.SlowDownDrawingSpeed;
begin
  // Delay the drawing of lines so the process can be followed on screen.
  // This method is called from the HC thread.
  Sleep(GetDelay);
end;

// This method is called as soon as the thread is ready.
procedure TfrmMain.DrawingDone;
begin
  BusyDrawing := false;
end;

//
// This is the key method that is called from the thread. As soon as a
// new point is calculated, this method is called to draw the new line segment.
//
procedure TfrmMain.NewPoint(const pPoint: TCoordinate);
var P: TPoint;
begin
  // Transpose the point that is in the range (0,0)-(1,1) to the actual
  // width and height of the paintbox.
  {$HINTS OFF}  // To prevent silly Int64 converting hints...
  P.X := pbCurve.Width - trunc(pPoint.X * (pbCurve.Width - 2));
  P.Y := (pbCurve.Height - 1) - trunc(pPoint.Y * (pbCurve.Height - 2));
  {$HINTS ON}

  // If a new endpoint is found, draw the line from the previous point.
  // Draw on the paintbox on screen *and* to the shadow copy of the bitmap.
  if isEndPoint then
    begin
      pbcurve.Canvas.LineTo(P);
      Shadow.Canvas.LineTo(P);
    end
  else
    begin
      // It's the first point that was calculated, so no line can be drawn yet.
      // Position the pen on the canvas for the paintbox on screen and the shadow bitmap.
      pbCurve.Canvas.MoveTo(P);
      Shadow.Canvas.MoveTo(P);

      // And of course from now on all new points are endpoints.
      isEndPoint := true
    end;
end;

initialization
  {$I ufrmmain.lrs}

end.

