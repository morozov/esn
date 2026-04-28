unit test_fitinfo_path;
{ Coverage for FitInfoPath, the directory-line truncator that
  picks PathFit's lead-...-tail layout on wide panels and the
  trailing-leaf clip on tight ones. }

{$mode objfpc}{$H+}

interface

uses fpcunit, testregistry;

type
  TFitInfoPathTest = class(TTestCase)
  published
    procedure TestWideUsesLeadTail;
    procedure TestNarrowShowsTrailingLeaf;
    procedure TestNarrowFitsAlreadyShort;
    procedure TestNarrowCJK_TrailingByCells;
  end;

implementation

uses pc, UnicodeVideo, SysUtils;

function CellWidth(const s: AnsiString): integer;
begin
  result := StringDisplayWidth(UTF8Decode(s));
end;

procedure TFitInfoPathTest.TestWideUsesLeadTail;
{ pw >= 12: defer to PathFit's lead-...-tail layout. }
var
  fit: string;
begin
  fit := FitInfoPath('/usr/local/share/applications/foo', 38);
  AssertTrue('Wide panel: contains "..."',
    Pos('...', fit) > 0);
  AssertTrue('Wide panel: starts with prefix /usr',
    Copy(fit, 1, 4) = '/usr');
end;

procedure TFitInfoPathTest.TestNarrowShowsTrailingLeaf;
{ pw < 12: lead-...-tail collapses to '...' or empty.  Show the
  trailing path within available cells so the user still sees where
  they are, rather than a row of dots. }
var
  fit: string;
begin
  fit := FitInfoPath('/usr/local/share/applications/foo', 8);
  AssertEquals('Trailing 8 cells of path', 'ions/foo', fit);
  AssertEquals('Result fits panel', 8, CellWidth(fit));
end;

procedure TFitInfoPathTest.TestNarrowFitsAlreadyShort;
{ Short input under pw: pass through unchanged even on tight panel. }
var
  fit: string;
begin
  fit := FitInfoPath('/abc', 8);
  AssertEquals('Short path returned verbatim', '/abc', fit);
end;

procedure TFitInfoPathTest.TestNarrowCJK_TrailingByCells;
{ Trailing-leaf clip respects cluster boundaries on tight panels:
  '/中文' is 1+2+2 = 5 cells; a 5-cell budget admits the leading
  '/' and both CJK clusters and clips on the cluster boundary,
  never half a glyph. }
var
  fit: string;
begin
  fit := FitInfoPath('/中文/中文/中文', 5);
  AssertEquals('Result fits panel (cells)', 5, CellWidth(fit));
  AssertEquals('Trailing /中文 preserved on cluster boundaries',
    '/中文', fit);
end;

initialization
  RegisterTest(TFitInfoPathTest);

end.
