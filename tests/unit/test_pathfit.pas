unit test_pathfit;
{ Contract tests for PathFit: result must fit within triggerCells,
  the lead-...-tail layout collapses to a plain prefix when the
  trigger cannot accommodate the ellipsis, and a non-positive
  trigger clips to empty. }

{$mode objfpc}{$H+}

interface

uses fpcunit, testregistry;

type
  TPathFitTest = class(TTestCase)
  published
    procedure TestNeverExceedsTrigger;
    procedure TestTinyTrigger_NoEllipsis;
    procedure TestNegativeTrigger_ReturnsEmpty;
  end;

implementation

uses pc, UnicodeVideo, SysUtils;

function CellWidth(const s: AnsiString): integer;
begin
  result := StringDisplayWidth(UTF8Decode(s));
end;

procedure TPathFitTest.TestNeverExceedsTrigger;
{ The contract: when input is wider than triggerCells, the result
  must also fit within triggerCells.  Real call site sn_obj.pas
  passes tailCells=30 with small triggers; lead+3+tail can be much
  larger than the trigger if PathFit doesn't cap. }
var
  fit: string;
begin
  { Tight trigger forces tail to shrink. }
  fit := PathFit('/usr/local/share/applications/foo/bar/baz/long.txt',
                 20, 4, 30);
  AssertTrue('Trigger=20: result fits within trigger',
             CellWidth(fit) <= 20);

  { Real sn_obj.pas:831 shape: small trigger, large tail. }
  fit := PathFit('VeryLongDiskLabelExceedingTwentyCells', 24, 4, 30);
  AssertTrue('Disk-label PathFit fits in trigger',
             CellWidth(fit) <= 24);

  { CJK input must still respect the budget. }
  fit := PathFit('中文中文中文中文中文中文', 10, 4, 30);
  AssertTrue('CJK over-trigger result fits',
             CellWidth(fit) <= 10);
end;

procedure TPathFitTest.TestTinyTrigger_NoEllipsis;
{ When triggerCells < 3 there is no room for "..."; PathFit drops
  the ellipsis and clips to a plain cell prefix. }
begin
  AssertEquals('Trigger=2 returns 2-cell prefix',
               '/v', PathFit('/very/long/path', 2, 4, 4));
  AssertEquals('Trigger=0 returns empty',
               '', PathFit('/anything', 0, 4, 4));
end;

procedure TPathFitTest.TestNegativeTrigger_ReturnsEmpty;
{ Negative triggerCells must clip to empty rather than treat the
  value as "no truncation".  Guards against unsigned underflow at
  call sites that compute trigger from a `word`-typed panel width. }
begin
  AssertEquals('Trigger=-1 returns empty',
               '', PathFit('/anything', -1, 4, 4));
end;

initialization
  RegisterTest(TPathFitTest);

end.
