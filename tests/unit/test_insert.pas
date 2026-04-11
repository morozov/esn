unit test_insert;
{ Tests for TPanel.Insert (mark toggle via Space / Ins). }
{$mode objfpc}{$H+}

interface

uses fpcunit, testregistry, sn_obj, vars, rv;

type
  TInsertTest = class(TTestCase)
  protected
    procedure SetUp; override;
    procedure TearDown; override;
  private
    FPanel: TPanel;
  published
    { PC panel: marking a regular file toggles mark on }
    procedure TestPcPanel_MarkFile;
    { PC panel: calling Insert twice toggles mark back off }
    procedure TestPcPanel_ToggleOff;
    { PC panel: index beyond file count does nothing }
    procedure TestPcPanel_OutOfBounds;
    { PC panel: index 0 (before first entry) does nothing }
    procedure TestPcPanel_IndexZero;
    { TRD panel: marking a file toggles mark on }
    procedure TestTrdPanel_MarkFile;
    { TRD panel: index beyond tfiles does nothing }
    procedure TestTrdPanel_OutOfBounds;
  end;

implementation

const
  MaxEntries = 10;
  TrdBufSize = 10;

type
  PpcDirRec = ^pcDirRec;
  PzxDirRec = ^zxDirRec;

function PcAt(var p: TPanel; i: integer): PpcDirRec;
var base: PpcDirRec;
begin
  base := @p.pcDir^[1];
  Inc(base, i - 1);
  PcAt := base;
end;

function ZxAt(var p: TPanel; i: integer): PzxDirRec;
var base: PzxDirRec;
begin
  base := @p.trdDir^[1];
  Inc(base, i - 1);
  ZxAt := base;
end;

procedure TInsertTest.SetUp;
begin
  {$push}{$notes off}
  FillChar(FPanel, SizeOf(FPanel), 0);
  {$pop}
  GetMem(FPanel.pcDir, MaxEntries * SizeOf(pcDirRec));
  {$push}{$notes off}
  FillChar(FPanel.pcDir^, MaxEntries * SizeOf(pcDirRec), 0);
  {$pop}
  GetMem(FPanel.trdDir, TrdBufSize * SizeOf(zxDirRec));
  {$push}{$notes off}
  FillChar(FPanel.trdDir^, TrdBufSize * SizeOf(zxDirRec), 0);
  {$pop}
  GmaxX := 80;
  GmaxY := 25;
  HalfMaxX := GmaxX div 2;
  HalfMaxY := GmaxY div 2;
end;

procedure TInsertTest.TearDown;
begin
  FreeMem(FPanel.trdDir, TrdBufSize * SizeOf(zxDirRec));
  FreeMem(FPanel.pcDir, MaxEntries * SizeOf(pcDirRec));
end;

{ ===== PC panel tests ===== }

procedure TInsertTest.TestPcPanel_MarkFile;
begin
  FPanel.PanelType := pcPanel;
  FPanel.pctdirs := 1;
  FPanel.pctfiles := 3;
  FPanel.from := 1;
  FPanel.f := 2;  { Index = from + f - 1 = 2 }
  PcAt(FPanel, 2)^.fname := 'test';
  PcAt(FPanel, 2)^.mark := false;

  FPanel.Insert;

  AssertTrue('file should be marked', PcAt(FPanel, 2)^.mark);
end;

procedure TInsertTest.TestPcPanel_ToggleOff;
begin
  FPanel.PanelType := pcPanel;
  FPanel.pctdirs := 0;
  FPanel.pctfiles := 2;
  FPanel.from := 1;
  FPanel.f := 1;  { Index = 1 }
  FPanel.pcDir^[1].mark := false;

  FPanel.Insert;
  AssertTrue('first call marks', FPanel.pcDir^[1].mark);

  FPanel.f := 1;  { Reset cursor — Insert advances it }
  FPanel.Insert;
  AssertFalse('second call unmarks', FPanel.pcDir^[1].mark);
end;

procedure TInsertTest.TestPcPanel_OutOfBounds;
begin
  FPanel.PanelType := pcPanel;
  FPanel.pctdirs := 1;
  FPanel.pctfiles := 2;  { valid range: 1..3 }
  FPanel.from := 1;
  FPanel.f := 5;  { Index = 5, beyond range }

  { Should not crash or change anything }
  FPanel.Insert;
end;

procedure TInsertTest.TestPcPanel_IndexZero;
begin
  FPanel.PanelType := pcPanel;
  FPanel.pctdirs := 1;
  FPanel.pctfiles := 2;
  FPanel.from := 0;
  FPanel.f := 1;  { Index = 0 }

  { Should not crash or change anything }
  FPanel.Insert;
end;

{ ===== TRD panel tests ===== }

procedure TInsertTest.TestTrdPanel_MarkFile;
begin
  FPanel.PanelType := trdPanel;
  FPanel.tfiles := 5;
  FPanel.from := 1;
  FPanel.f := 3;  { Index = 3 }
  ZxAt(FPanel, 3)^.name := 'loader    ';
  ZxAt(FPanel, 3)^.mark := false;

  FPanel.Insert;

  AssertTrue('TRD file should be marked', ZxAt(FPanel, 3)^.mark);
end;

procedure TInsertTest.TestTrdPanel_OutOfBounds;
begin
  FPanel.PanelType := trdPanel;
  FPanel.tfiles := 3;  { valid range: 1..3 }
  FPanel.from := 1;
  FPanel.f := 5;  { Index = 5, beyond range }

  { Should not crash or change anything }
  FPanel.Insert;
end;

initialization
  RegisterTest(TInsertTest);

end.
