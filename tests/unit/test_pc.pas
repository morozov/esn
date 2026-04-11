unit test_pc;
{ Unit tests for pc.pas (pcNameLine) and pcMDF filename handling. }
{$mode objfpc}{$H+}

interface

uses fpcunit, testregistry, sn_obj, vars;

type
  TPcTest = class(TTestCase)
  protected
    procedure SetUp; override;
    procedure TearDown; override;
  private
    FPanel: TPanel;
    procedure SetEntry(idx: integer; const aFullname: string;
                       aLength: longint; aIsDir: boolean = false);
  published
    { Regression: normal subdir name line must contain ►SUB-DIR◄ (#16…#17) }
    procedure TestNameLine_SubDir_InwardTriangles;
    { Regression: parent ".." name line must contain ◄SUB-DIR► (#17…#16) }
    procedure TestNameLine_DotDot_OutwardTriangles;
    { Normal file: no triangle chars, numeric size present }
    procedure TestNameLine_File_NoTriangles;

    { Full filename stored and returned unchanged (no 8-char truncation) }
    procedure TestPcDir_FullnameStored;
    { Case preserved: mixed-case name comes back unchanged }
    procedure TestPcDir_CasePreserved;
    { Long name displayed truncated to 12 chars in name line }
    procedure TestNameLine_LongName_Truncated;
    { Extension beyond 3 chars stored and matched correctly }
    procedure TestPcDir_LongExtension;

    { PcColumnEntry: result is always exactly dx-1 chars (no separator overrun) }
    procedure TestColumnEntry_Width_3col;
    { PcColumnEntry: 4-char ext is capped at 3 chars in display }
    procedure TestColumnEntry_LongExt_Capped;
    { PcColumnEntry: 3-char ext fits exactly }
    procedure TestColumnEntry_ShortExt_Unchanged;
    { PcColumnEntry: leading space in fname is stripped }
    procedure TestColumnEntry_DotDot_SpaceStripped;
    { Regression: 1-char ext must still produce dx-1 = 12 chars }
    procedure TestColumnEntry_Width_1charExt;
    { Regression: empty ext must produce dx-1 = 12 chars (not 9) }
    procedure TestColumnEntry_Width_NoExt;
    { Regression: ext shorter than 3 chars is right-padded with spaces }
    procedure TestColumnEntry_ShortExt_Padded;
  end;

implementation

uses pc, SysUtils;

const
  MaxEntries = 10;

type
  PpcDirRec = ^pcDirRec;

function PcEntry(var p: TPanel; i: integer): PpcDirRec;
var
  base: PpcDirRec;
begin
  base := @p.pcDir^[1];
  Inc(base, i - 1);
  PcEntry := base;
end;

procedure TPcTest.SetUp;
begin
  {$push}{$notes off}
  FillChar(FPanel, SizeOf(FPanel), 0);
  {$pop}
  FPanel.PanelType := pcPanel;
  GetMem(FPanel.pcDir, MaxEntries * SizeOf(pcDirRec));
  {$push}{$notes off}
  FillChar(FPanel.pcDir^, MaxEntries * SizeOf(pcDirRec), 0);
  {$pop}
  FPanel.pctdirs := 2;   { entries 1..2 are dirs; entries 3+ are files }
end;

procedure TPcTest.TearDown;
begin
  FreeMem(FPanel.pcDir, MaxEntries * SizeOf(pcDirRec));
end;

procedure TPcTest.SetEntry(idx: integer; const aFullname: string;
                            aLength: longint; aIsDir: boolean);
var
  ext: string;
begin
  PcEntry(FPanel, idx)^.fullname := aFullname;
  PcEntry(FPanel, idx)^.fname    := ChangeFileExt(aFullname, '');
  ext := ExtractFileExt(aFullname);
  if ext <> '' then
    PcEntry(FPanel, idx)^.fext := Copy(ext, 2, MaxInt)
  else
    PcEntry(FPanel, idx)^.fext := '';
  PcEntry(FPanel, idx)^.flength := aLength;
  if aIsDir then
    PcEntry(FPanel, idx)^.flength := -1;
end;

{ ===== TestNameLine_SubDir_InwardTriangles ===== }

procedure TPcTest.TestNameLine_SubDir_InwardTriangles;
{ Subdirectory must display SUB-DIR in the size column. }
var
  s: string;
begin
  SetEntry(1, 'DOCS', -1, true);
  s := pcNameLine(FPanel, 1);
  AssertTrue('SUB-DIR present',
    Pos('SUB-DIR', s) > 0);
end;

{ ===== TestNameLine_DotDot_OutwardTriangles ===== }

procedure TPcTest.TestNameLine_DotDot_OutwardTriangles;
{ Parent ".." entry must display SUB-DIR in the size column. }
var
  s: string;
begin
  PcEntry(FPanel, 2)^.fullname := '..';
  PcEntry(FPanel, 2)^.fname    := '..';
  PcEntry(FPanel, 2)^.fext     := '';
  PcEntry(FPanel, 2)^.flength  := -1;
  s := pcNameLine(FPanel, 2);
  AssertTrue('SUB-DIR present',
    Pos('SUB-DIR', s) > 0);
end;

{ ===== TestNameLine_File_NoTriangles ===== }

procedure TPcTest.TestNameLine_File_NoTriangles;
{ Regular file: size is numeric, no triangle characters. }
var
  s: string;
begin
  SetEntry(3, 'README.TXT', 1234);
  s := pcNameLine(FPanel, 3);
  AssertTrue('no #16 in file line', Pos(#16, s) = 0);
  AssertTrue('no #17 in file line', Pos(#17, s) = 0);
  AssertTrue('size present', Pos('1,234', s) > 0);
end;

{ ===== TestPcDir_FullnameStored ===== }

procedure TPcTest.TestPcDir_FullnameStored;
{ fullname must hold the complete OS filename without 8-char truncation. }
begin
  SetEntry(3, 'Manic Miner.tap', 12345);
  AssertEquals('fullname untruncated',
    'Manic Miner.tap', PcEntry(FPanel, 3)^.fullname);
  AssertEquals('fname base name',
    'Manic Miner', PcEntry(FPanel, 3)^.fname);
  AssertEquals('fext extension',
    'tap', PcEntry(FPanel, 3)^.fext);
end;

{ ===== TestPcDir_CasePreserved ===== }

procedure TPcTest.TestPcDir_CasePreserved;
{ Mixed-case names must be returned exactly as stored — no LowerCase/UpperCase. }
var
  s: string;
begin
  SetEntry(3, 'Agent X II.tap', 1000);
  AssertEquals('fullname case preserved',
    'Agent X II.tap', PcEntry(FPanel, 3)^.fullname);
  s := pcNameLine(FPanel, 3);
  AssertTrue('original case in name line',
    Pos('Agent X II', s) > 0);
end;

{ ===== TestNameLine_LongName_Truncated ===== }

procedure TPcTest.TestNameLine_LongName_Truncated;
{ A name longer than 12 chars must be truncated to 12 in the name line. }
var
  s: string;
begin
  SetEntry(3, 'Arkanoid Revenge of Doh.tap', 50000);
  s := pcNameLine(FPanel, 3);
  { The name portion is the first 12 chars of the result. }
  AssertEquals('name truncated to 12', 'Arkanoid Rev', Copy(s, 1, 12));
end;

{ ===== TestPcDir_LongExtension ===== }

procedure TPcTest.TestPcDir_LongExtension;
{ Extensions beyond 3 chars must be stored in full. }
begin
  SetEntry(3, 'snapshot.z80x', 2048);
  AssertEquals('full ext stored', 'z80x', PcEntry(FPanel, 3)^.fext);
  AssertEquals('fullname stored',
    'snapshot.z80x', PcEntry(FPanel, 3)^.fullname);
end;

{ ===== PcColumnEntry tests ===== }

procedure TPcTest.TestColumnEntry_Width_3col;
{ Result must be exactly dx-1 = 12 chars for 3-col mode (dx=13). }
var
  s: string;
begin
  { 4-char ext: without the cap this would be 13 chars and overwrite separator }
  s := PcColumnEntry('snapshot', 'z80x', 13, 0);
  AssertEquals('entry width 3col', 12, Length(s));
end;

procedure TPcTest.TestColumnEntry_LongExt_Capped;
{ A 4-char extension must be truncated to 3 chars in the display string. }
var
  s: string;
begin
  s := PcColumnEntry('snapshot', 'z80x', 13, 0);
  { Last 3 chars of a 12-char result are the ext; position 10 is attr space }
  AssertEquals('ext capped at 3', 'z80', Copy(s, 10, 3));
end;

procedure TPcTest.TestColumnEntry_ShortExt_Unchanged;
{ A 3-char extension is passed through unchanged. }
var
  s: string;
begin
  s := PcColumnEntry('README', 'TXT', 13, 0);
  AssertEquals('3-char ext unchanged', 'TXT', Copy(s, 10, 3));
  AssertEquals('entry width 12', 12, Length(s));
end;

procedure TPcTest.TestColumnEntry_DotDot_SpaceStripped;
{ The ".." entry is stored as ' ..' — leading space must be stripped. }
var
  s: string;
begin
  s := PcColumnEntry(' ..', '', 13, 0);
  AssertEquals('starts with dot', '.', s[1]);
end;

{ ===== Regression: short/empty extension width ===== }

procedure TPcTest.TestColumnEntry_Width_1charExt;
{ A 1-char extension must still produce a 12-char result (not 10). }
var
  s: string;
begin
  s := PcColumnEntry('Makefile', 'c', 13, 0);
  AssertEquals('1-char ext: entry width 12', 12, Length(s));
end;

procedure TPcTest.TestColumnEntry_Width_NoExt;
{ An empty extension must produce a 12-char result (not 9). }
var
  s: string;
begin
  s := PcColumnEntry('Makefile', '', 13, 0);
  AssertEquals('no ext: entry width 12', 12, Length(s));
end;

procedure TPcTest.TestColumnEntry_ShortExt_Padded;
{ A 1-char extension must be right-padded with spaces to fill 3 ext cols. }
var
  s: string;
begin
  s := PcColumnEntry('main', 'c', 13, 0);
  { Entry is 12 chars: 8 base + 1 attr space + 3 ext.
    With ext='c', last 3 chars must be 'c  ' (c + two spaces). }
  AssertEquals('ext right-padded', 'c  ', Copy(s, 10, 3));
end;

initialization
  RegisterTest(TPcTest);

end.
