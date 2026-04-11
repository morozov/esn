unit test_scl;
{ Unit tests for scl.pas and scl_ovr.pas. }
{$mode objfpc}{$H+}

interface

uses fpcunit, testregistry, sn_obj;

type
  TSclTest = class(TTestCase)
  protected
    procedure SetUp; override;
    procedure TearDown; override;
  private
    FPanel: TPanel;
    function TrdDir(i: integer): zxDirRec;
    procedure SetMark(i: integer; val: boolean);
  published
    procedure TestIsSCL_ValidSample;
    procedure TestIsSCL_BadFile;
    procedure TestIsSCL_Missing;

    procedure TestMDF_SampleFileCount;
    procedure TestMDF_SampleEntry2_Name;
    procedure TestMDF_SampleEntry2_Type;
    procedure TestMDF_SampleEntry2_Length;
    procedure TestMDF_SampleEntry3_Start;
    procedure TestMDF_SampleEntry4_TotalSec;
    procedure TestMDF_DiskLabel;

    procedure TestNameLine_ContainsName;
    procedure TestNameLine_ContainsType;

    procedure TestLoad_Entry;

    procedure TestDel_FileCount;
  end;

implementation

uses scl, scl_ovr, vars, sn_mem, SysUtils;

const
  FixDir = '../fixtures/';

{ ===== Private helpers ===== }

function TSclTest.TrdDir(i: integer): zxDirRec;
var
  ep: ^zxDirRec;
begin
  ep := @FPanel.trdDir^[1];
  Inc(ep, i - 1);
  TrdDir := ep^;
end;

procedure TSclTest.SetMark(i: integer; val: boolean);
var
  ep: ^zxDirRec;
begin
  ep := @FPanel.trdDir^[1];
  Inc(ep, i - 1);
  ep^.mark := val;
end;

procedure TSclTest.SetUp;
begin
  GetMemPCDirs;
  {$push}{$notes off}
  FillChar(FPanel, SizeOf(FPanel), 0);
  {$pop}
  FPanel.PanelType := sclPanel;
  GetMem(FPanel.trdDir, 257 * SizeOf(zxDirRec));
  GetMem(FPanel.trdIns, 257 * SizeOf(zxInsedRec));
  {$push}{$notes off}
  FillChar(FPanel.trdDir^, 257 * SizeOf(zxDirRec),  0);
  FillChar(FPanel.trdIns^, 257 * SizeOf(zxInsedRec), 0);
  {$pop}
end;

procedure TSclTest.TearDown;
begin
  FreeMem(FPanel.trdDir, 257 * SizeOf(zxDirRec));
  FreeMem(FPanel.trdIns, 257 * SizeOf(zxInsedRec));
  FreeMemPCDirs;
end;

{ Copy a binary file src → dst; returns true on success. }
function CopyBinaryFile(const src, dst: string): boolean;
var
  sf, df: file;
  buf: array[1..4096] of byte;
  nr, nw: word;
begin
  CopyBinaryFile := false;
  nr := 0; nw := 0; buf[1] := 0;
  try
    Assign(sf, src); FileMode := 0; Reset(sf, 1);
    try
      Assign(df, dst); FileMode := 2; Rewrite(df, 1);
      try
        repeat
          BlockRead(sf, buf[1], SizeOf(buf), nr);
          if nr > 0 then BlockWrite(df, buf[1], nr, nw);
        until nr = 0;
        CopyBinaryFile := true;
      finally
        Close(df);
      end;
    finally
      Close(sf);
    end;
  except
  end;
end;

{ ===== isSCL ===== }

procedure TSclTest.TestIsSCL_ValidSample;
begin
  AssertTrue('sample.scl valid', isSCL(FixDir + 'sample.scl'));
end;

procedure TSclTest.TestIsSCL_BadFile;
var
  tmp: string;
  f: TextFile;
begin
  tmp := GetTempFileName('', 'tst');
  AssignFile(f, tmp);
  Rewrite(f); WriteLn(f, 'not an scl file'); CloseFile(f);
  try
    AssertFalse('text not SCL', isSCL(tmp));
  finally
    DeleteFile(tmp);
  end;
end;

procedure TSclTest.TestIsSCL_Missing;
begin
  AssertFalse('missing not SCL',
    isSCL(FixDir + 'does_not_exist.scl'));
end;

{ ===== sclMDF: sample =====
  sample.scl layout (1079 bytes):
    "SINCLAIR" + count=3 + directory(42 bytes) + bodies(1024 bytes) + cs(4)

  directory entries:
    [2] "hello   " B  start=0      length=100  totalsec=1
    [3] "data    " C  start=32768  length=256  totalsec=1
    [4] "code    " D  start=0      length=512  totalsec=2
}

procedure TSclTest.TestMDF_SampleFileCount;
begin
  FPanel.sclFile := FixDir + 'sample.scl';
  sclMDF(FPanel, FixDir + 'sample.scl');
  AssertEquals('scltfiles', 4, FPanel.scltfiles);
  AssertEquals('files', 3, FPanel.zxDisk.files);
end;

procedure TSclTest.TestMDF_SampleEntry2_Name;
begin
  FPanel.sclFile := FixDir + 'sample.scl';
  sclMDF(FPanel, FixDir + 'sample.scl');
  AssertEquals('entry2 name', 'hello   ', TrdDir(2).name);
end;

procedure TSclTest.TestMDF_SampleEntry2_Type;
begin
  FPanel.sclFile := FixDir + 'sample.scl';
  sclMDF(FPanel, FixDir + 'sample.scl');
  AssertEquals('entry2 type', 'B', TrdDir(2).typ);
end;

procedure TSclTest.TestMDF_SampleEntry2_Length;
begin
  FPanel.sclFile := FixDir + 'sample.scl';
  sclMDF(FPanel, FixDir + 'sample.scl');
  AssertEquals('entry2 length', 100, integer(TrdDir(2).length));
end;

procedure TSclTest.TestMDF_SampleEntry3_Start;
begin
  FPanel.sclFile := FixDir + 'sample.scl';
  sclMDF(FPanel, FixDir + 'sample.scl');
  AssertEquals('entry3 start', 32768, integer(TrdDir(3).start));
end;

procedure TSclTest.TestMDF_SampleEntry4_TotalSec;
begin
  FPanel.sclFile := FixDir + 'sample.scl';
  sclMDF(FPanel, FixDir + 'sample.scl');
  AssertEquals('entry4 totalsec', 2, integer(TrdDir(4).totalsec));
end;

procedure TSclTest.TestMDF_DiskLabel;
begin
  FPanel.sclFile := FixDir + 'sample.scl';
  sclMDF(FPanel, FixDir + 'sample.scl');
  AssertEquals('disk label', 'Hobeta98', FPanel.zxDisk.diskLabel);
end;

{ ===== sclNameLine ===== }

procedure TSclTest.TestNameLine_ContainsName;
var
  s: string;
begin
  FPanel.sclFile := FixDir + 'sample.scl';
  sclMDF(FPanel, FixDir + 'sample.scl');
  s := sclNameLine(FPanel, 2);
  AssertTrue('nameLine has hello', Pos('hello', s) > 0);
end;

procedure TSclTest.TestNameLine_ContainsType;
var
  s: string;
begin
  FPanel.sclFile := FixDir + 'sample.scl';
  sclMDF(FPanel, FixDir + 'sample.scl');
  s := sclNameLine(FPanel, 2);
  AssertTrue('nameLine has B', Pos('B', s) > 0);
end;

{ ===== sclLoad ===== }

procedure TSclTest.TestLoad_Entry;
begin
  FPanel.sclFile := FixDir + 'sample.scl';
  sclMDF(FPanel, FixDir + 'sample.scl');
  AssertTrue('sclLoad ok', sclLoad(FPanel, 2));
  AssertEquals('loaded name',   'hello   ', HobetaInfo.name);
  AssertEquals('loaded typ',    'B',        HobetaInfo.typ);
  AssertEquals('loaded length', 100,        integer(HobetaInfo.length));
  FreeMem(HobetaInfo.body, 256 * longint(HobetaInfo.totalsec));
end;

{ ===== sclDel ===== }

procedure TSclTest.TestDel_FileCount;
{ Delete entry 2 ("hello") and verify file count drops to 2. }
var
  tmp: string;
begin
  tmp := GetTempFileName('', 'scl');
  try
    AssertTrue('copy ok', CopyBinaryFile(FixDir + 'sample.scl', tmp));

    FPanel.sclFile := tmp;
    sclMDF(FPanel, tmp);
    SetMark(2, true);
    AssertTrue('sclDel ok', sclDel(FPanel));

    { Reload from the modified file into the same panel }
    {$push}{$notes off}
    FillChar(FPanel.trdDir^, 257 * SizeOf(zxDirRec), 0);
    FillChar(FPanel.trdIns^, 257 * SizeOf(zxInsedRec), 0);
    {$pop}
    FPanel.scltfiles := 0;
    sclMDF(FPanel, tmp);
    AssertEquals('2 files remain', 2, FPanel.zxDisk.files);
  finally
    DeleteFile(tmp);
  end;
end;

initialization
  RegisterTest(TSclTest);

end.
