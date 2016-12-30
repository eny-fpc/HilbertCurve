{ HilbertCurves unit.

  This class implements a simple mechanism to calculate the points of a Hilbert Curve of a certain depth.
  A reference to hilbert curves: http://en.wikipedia.org/wiki/Hilbert_curve

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

unit HilbertCurves;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils;

type
  // 4 directions for easy definition of line segment structures
  THilbertDirection = (hiDo, hiLe, hiRi, hiUp);

  // Doubles instead of integers in a point
  TCoordinate = record
    X: double;
    Y: double;
  end;

  // Procedure to call when a new point is calculated
  TOnNewPointEvent = procedure(const pPoint: TCoordinate) of object;

  { THilbertCurve }

  THilbertCurve = class
  private
    FOnNewPoint: TOnNewPointEvent;

    // Dummy procedure for speed reasons
    procedure DummyOnNewPoint(const pPoint: TCoordinate);

    // Recursive method to generate all cups
    procedure HandleCup(const pMid: TCoordinate; const pRib: double; const pDir: THilbertDirection; const pDepth: integer);

  public
    procedure Draw(const pDepth: integer; const pBeginDir: THilbertDirection = hiUp);
    property OnNewPoint: TOnNewPointEvent read FOnNewPoint write FOnNewPoint;
  end;


implementation

type
  // Definition of a cup structure
  TCupDef = record
    X: integer;
    Y: integer;
    C: THilbertDirection;
  end;

const
  // Based on a point in a curve segment, a fixed set of 4  'cups' exist
  CupDirections: array[THilbertDirection, 0..3] of TCupDef =
    (((X:-1; y:+1; C:hiRi), (X:-1; y:-1; C:hiDo), (X:+1; y:-1; C:hiDo), (X:+1; y:+1; C:hiLe)),
     ((X:+1; y:-1; C:hiUp), (X:-1; y:-1; C:hiLe), (X:-1; y:+1; C:hiLe), (X:+1; y:+1; C:hiDo)),
     ((X:-1; y:+1; C:hiDo), (X:+1; y:+1; C:hiRi), (X:+1; y:-1; C:hiRi), (X:-1; y:-1; C:hiUp)),
     ((X:+1; y:-1; C:hiLe), (X:+1; y:+1; C:hiUp), (X:-1; y:+1; C:hiUp), (X:-1; y:-1; C:hiRi)));


{ THilbertCurve }

procedure THilbertCurve.HandleCup(const pMid: TCoordinate; const pRib: double; const pDir: THilbertDirection; const pDepth: integer);

  function CupPoint(const pDir: THilbertDirection; const pSeq: integer; const pPosition: TCoordinate; const pRib: double): TCoordinate;
  begin
    result.X := pPosition.X + CupDirections[pDir,pSeq].X * pRib;
    result.Y := pPosition.Y + CupDirections[pDir,pSeq].Y * pRib;
  end;

var offset: double;
begin
  offset := pRib / 2.0;
  if pDepth = 0 then
    begin
      OnNewPoint(CupPoint(pDir,0,pMid,offset));
      OnNewPoint(CupPoint(pDir,1,pMid,offset));
      OnNewPoint(CupPoint(pDir,2,pMid,offset));
      OnNewPoint(CupPoint(pDir,3,pMid,offset));
    end
  else
    begin
      HandleCup(CupPoint(pDir,0,pMid,offset),offset,CupDirections[pDir,0].C,pDepth-1);
      HandleCup(CupPoint(pDir,1,pMid,offset),offset,CupDirections[pDir,1].C,pDepth-1);
      HandleCup(CupPoint(pDir,2,pMid,offset),offset,CupDirections[pDir,2].C,pDepth-1);
      HandleCup(CupPoint(pDir,3,pMid,offset),offset,CupDirections[pDir,3].C,pDepth-1);
    end;
end;

procedure THilbertCurve.DummyOnNewPoint(const pPoint: TCoordinate);
begin
  // Do nothing here...
end;

procedure THilbertCurve.Draw(const pDepth: integer; const pBeginDir: THilbertDirection);
var C: TCoordinate;
begin
  // Make sure there is a procedure to call when a new point is calculated
  if not assigned(OnNewPoint) then
    OnNewPoint := @DummyOnNewPoint;

  // Start calculating the points starting with the cup in the middle; coordinate (0.5, 0.5)
  C.X := 0.5;
  C.Y := 0.5;
  HandleCup(C,0.5,pBeginDir,pDepth);
end;

end.

