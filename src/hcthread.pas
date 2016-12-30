{ HCThread unit.

  This class makes drawing a HilbertCurve threaded. I.e. it's possible to slow down the drawing to
  see how a curve is constructedin an embedding program, without it coming to a grinding halt.

  Usage example: see the demo program on the Lazarus wiki.

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
unit HCThread;

{$mode objfpc}{$H+}

interface

uses
  HilbertCurves,
  Classes, SysUtils; 

type

  { THCThread }

  THCTOnDephtStartEvent = procedure(const pDepth: integer) of object;
  TSlowDownEvent = procedure of object;
  THCThreadDoneEvent = procedure of object;

  THCThread = class(TThread)
  private
    FHC: THilbertCurve;
    FDepth: integer;
    FDoAllDepths: boolean;
    FNewPoint: TCoordinate;
    FCurrentDepth: integer;
    FOnHCThreadDone: THCThreadDoneEvent;

    FOnNewPoint: TOnNewPointEvent;
    FOnDepthStartEvent: THCTOnDephtStartEvent;
    FOnSlowDown: TSlowDownEvent;

  protected
    procedure Execute; override;
    procedure OnNewPointHandler(const pCoordinate: TCoordinate);
    procedure LCLProcessNewPoint;
    procedure SignalStartNewDepth;

  public
    constructor Create(const pDepth: integer);
    property DoAllDepths: boolean read FDoAllDepths write FDoAllDepths;
    property OnNewPoint: TOnNewPointEvent read FOnNewPoint write FOnNewPoint;
    property OnDepthStartEvent: THCTOnDephtStartEvent read FOnDepthStartEvent write FOnDepthStartEvent;
    property OnSlowDown: TSlowDownEvent read FOnSlowDown write FOnSlowDown;
    property OnHCThreadDone: THCThreadDoneEvent read FOnHCThreadDone write FOnHCThreadDone;
  end;

implementation

{ THCThread }

constructor THCThread.Create(const pDepth: integer);
begin
  FreeOnTerminate := true;
  inherited Create(true);
  FDepth := pDepth;
end;

procedure THCThread.Execute;
var i,ifrom,iTo: integer;
begin
  // Determine of just one curve must be drawn, or all curves from 0..depth.
  iTo := FDepth;
  if DoAllDepths
    then iFrom := 0
    else iFrom := FDepth;

  // Draw all curves.
  for i := iFrom to iTo do
  begin
    // Store the depth for reference in VCL synchronize procs
    FCurrentDepth := i;

    // Signal that a new curve with depth 'FCurrentDepth' will start shortly
    Synchronize(@SignalStartNewDepth);

    // Now draw the curve
    FHC := THilbertCurve.Create;
    FHC.OnNewPoint := @OnNewPointHandler;
    FHC.Draw(FCurrentDepth);
    FHC.Free;
  end;

  // Signal done
  if assigned(FOnHCThreadDone) then
    FOnHCThreadDone();
end;

procedure THCThread.LCLProcessNewPoint;
begin
  // Call the method that process the new point.
  if assigned(FOnNewPoint) then
    FOnNewPoint(FNewPoint)
end;

procedure THCThread.OnNewPointHandler(const pCoordinate: TCoordinate);
begin
  // A new point was calculated. Store it and synchronize with the main VCL thread.
  FNewPoint := pCoordinate;
  Synchronize(@LCLProcessNewPoint);

  // Maybe do some slowing down for educational purposes.
  if assigned(OnSlowDown) then
    OnSlowDown();
end;

procedure THCThread.SignalStartNewDepth;
begin
  // A new curve will be drawn. This is the moment for the main program
  // to set pen widths, colors etc. hence this call,
  if assigned(OnDepthStartEvent) then
    OnDepthStartEvent(FCurrentDepth);
end;

end.

