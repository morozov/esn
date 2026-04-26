unit test_tap;
{ Unit tests for tap.pas and tap_ovr.pas. }
{$mode objfpc}{$H+}

interface

uses fpcunit, testregistry, sn_obj;

type
  TTapTest = class(TTestCase)
  protected
    procedure SetUp; override;
    procedure TearDown; override;
  private
    FPanel: TPanel;
    function TrdDir(i: integer): zxDirRec;
    procedure SetMark(i: integer; val: boolean);
  published
    procedure TestIsTAP_ValidEmpty;
    procedure TestIsTAP_ValidSample;
    procedure TestIsTAP_BadExtension;
    procedure TestIsTAP_Missing;

    procedure TestMDF_Empty_FileCount;

    procedure TestMDF_SampleFileCount;
    procedure TestMDF_SampleEntry2_Name;
    procedure TestMDF_SampleEntry2_TapFlag;
    procedure TestMDF_SampleEntry3_Name;
    procedure TestMDF_SampleEntry3_Length;
    procedure TestMDF_SampleEntry4_Name;
    procedure TestMDF_SampleEntry4_TapFlag;

    { Regression: data block name must be shade blocks, not "Data" text }
    procedure TestMDF_DataBlockName_IsShadeBlocks;

    procedure TestNameLine_Header;
    procedure TestNameLine_Data;
    { Regression: data block name line must start with shade block (#177) }
    procedure TestNameLine_Data_StartsWithShadeBlock;

    procedure TestLoad_HeaderProgram;

    procedure TestDel_CompactsFile;

    { Regression: copying all marked TRD files to TAP must produce
      2 blocks per file (header + data).  Bug: last file was lost. }
    procedure TestSave_AllTrdFiles;
  end;

implementation

uses tap, tap_ovr, trd, trd_ovr, vars, sn_mem, SysUtils;

const
  FixDir = '../fixtures/';

{ ===== Private helpers ===== }

function TTapTest.TrdDir(i: integer): zxDirRec;
var
  ep: ^zxDirRec;
begin
  ep := @FPanel.trdDir^[1];
  Inc(ep, i - 1);
  TrdDir := ep^;
end;

procedure TTapTest.SetMark(i: integer; val: boolean);
var
  ep: ^zxDirRec;
begin
  ep := @FPanel.trdDir^[1];
  Inc(ep, i - 1);
  ep^.mark := val;
end;

procedure TTapTest.SetUp;
begin
  GetMemPCDirs;
  lp.PanelType := pcPanel;
  rp.PanelType := pcPanel;
  focus := Left;
  {$push}{$notes off}
  FillChar(FPanel, SizeOf(FPanel), 0);
  {$pop}
  FPanel.PanelType := tapPanel;
  GetMem(FPanel.trdDir, 257 * SizeOf(zxDirRec));
  GetMem(FPanel.trdIns, 257 * SizeOf(zxInsedRec));
  {$push}{$notes off}
  FillChar(FPanel.trdDir^, 257 * SizeOf(zxDirRec),  0);
  FillChar(FPanel.trdIns^, 257 * SizeOf(zxInsedRec), 0);
  {$pop}
end;

procedure TTapTest.TearDown;
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

{ ===== isTAP ===== }

procedure TTapTest.TestIsTAP_ValidEmpty;
begin
  AssertTrue('empty.tap valid', isTAP(FixDir + 'empty.tap'));
end;

procedure TTapTest.TestIsTAP_ValidSample;
begin
  AssertTrue('sample.tap valid', isTAP(FixDir + 'sample.tap'));
end;

procedure TTapTest.TestIsTAP_BadExtension;
var
  tmp: string;
  f: TextFile;
begin
  { GetTempFileName returns a path with no .tap extension }
  tmp := GetTempFileName('', 'tst');
  AssignFile(f, tmp);
  Rewrite(f); WriteLn(f, 'not a tap'); CloseFile(f);
  try
    AssertFalse('no .tap ext', isTAP(tmp));
  finally
    DeleteFile(tmp);
  end;
end;

procedure TTapTest.TestIsTAP_Missing;
begin
  AssertFalse('missing not TAP',
    isTAP(FixDir + 'does_not_exist.tap'));
end;

{ ===== tapMDF: empty ===== }

procedure TTapTest.TestMDF_Empty_FileCount;
begin
  FPanel.tapFile := FixDir + 'empty.tap';
  tapMDF(FPanel, FixDir + 'empty.tap');
  AssertEquals('empty: taptfiles', 1, FPanel.taptfiles);
  AssertEquals('empty: files', 0, FPanel.zxDisk.files);
end;

{ ===== tapMDF: sample =====
  sample.tap layout (406 bytes):
    block 0: header "hello     " Program  LINE=10 datalen=100  (21 bytes)
    block 1: data   100 zero bytes                             (104 bytes)
    block 2: header "code      " Code     start=32768 datalen=256 (21 bytes)
    block 3: data   256 zero bytes                             (260 bytes)

  tapMDF entries (trdDir):
    [1] "<<"
    [2] header "hello     "  tapflag=0  length=17 (=w-2=19-2)
    [3] data   10x#177       tapflag=FF length=100
    [4] header "code      "  tapflag=0  length=17
    [5] data   10x#177       tapflag=FF length=254 (=w-2=256-2)
}

procedure TTapTest.TestMDF_SampleFileCount;
begin
  FPanel.tapFile := FixDir + 'sample.tap';
  tapMDF(FPanel, FixDir + 'sample.tap');
  AssertEquals('sample: taptfiles', 5, FPanel.taptfiles);
  AssertEquals('sample: files', 4, FPanel.zxDisk.files);
end;

procedure TTapTest.TestMDF_SampleEntry2_Name;
begin
  FPanel.tapFile := FixDir + 'sample.tap';
  tapMDF(FPanel, FixDir + 'sample.tap');
  AssertEquals('entry2 name', 'hello     ', TrdDir(2).name);
end;

procedure TTapTest.TestMDF_SampleEntry2_TapFlag;
begin
  FPanel.tapFile := FixDir + 'sample.tap';
  tapMDF(FPanel, FixDir + 'sample.tap');
  AssertEquals('entry2 tapflag=0', 0, integer(TrdDir(2).tapflag));
end;

procedure TTapTest.TestMDF_SampleEntry3_Name;
begin
  FPanel.tapFile := FixDir + 'sample.tap';
  tapMDF(FPanel, FixDir + 'sample.tap');
  { Data blocks have no real name; tapflag<>0 marks them and the
    display layer renders the ▒×10 placeholder. }
  AssertEquals('entry3 name empty', '', TrdDir(3).name);
  AssertTrue('entry3 is data block', TrdDir(3).tapflag <> 0);
end;

procedure TTapTest.TestMDF_SampleEntry3_Length;
begin
  FPanel.tapFile := FixDir + 'sample.tap';
  tapMDF(FPanel, FixDir + 'sample.tap');
  { data block: w=102, length=w-2=100 }
  AssertEquals('entry3 length', 100, integer(TrdDir(3).length));
end;

procedure TTapTest.TestMDF_SampleEntry4_Name;
begin
  FPanel.tapFile := FixDir + 'sample.tap';
  tapMDF(FPanel, FixDir + 'sample.tap');
  AssertEquals('entry4 name', 'code      ', TrdDir(4).name);
end;

procedure TTapTest.TestMDF_SampleEntry4_TapFlag;
begin
  FPanel.tapFile := FixDir + 'sample.tap';
  tapMDF(FPanel, FixDir + 'sample.tap');
  AssertEquals('entry4 tapflag=0', 0, integer(TrdDir(4).tapflag));
end;

procedure TTapTest.TestMDF_DataBlockName_IsShadeBlocks;
{ Regression: data block must be flagged via tapflag<>0; the
  visible ▒×10 placeholder is composed by the display layer. }
begin
  FPanel.tapFile := FixDir + 'sample.tap';
  tapMDF(FPanel, FixDir + 'sample.tap');
  AssertTrue('data block flagged', TrdDir(3).tapflag <> 0);
  AssertEquals('data block name empty', '', TrdDir(3).name);
end;

{ ===== tapNameLine ===== }

procedure TTapTest.TestNameLine_Header;
var
  s: string;
begin
  FPanel.tapFile := FixDir + 'sample.tap';
  tapMDF(FPanel, FixDir + 'sample.tap');
  s := tapNameLine(FPanel, 2);
  AssertTrue('nameLine header has name', Pos('hello', s) > 0);
end;

procedure TTapTest.TestNameLine_Data;
var
  s: string;
begin
  FPanel.tapFile := FixDir + 'sample.tap';
  tapMDF(FPanel, FixDir + 'sample.tap');
  s := tapNameLine(FPanel, 3);
  AssertTrue('nameLine data has Data', Pos('Data', s) > 0);
end;

procedure TTapTest.TestNameLine_Data_StartsWithShadeBlock;
{ Regression: name line for data block must start with the shade
  block ▒ glyph (U+2592), not 'D'. }
var
  s: string;
const
  Shade: string = '▒';
begin
  FPanel.tapFile := FixDir + 'sample.tap';
  tapMDF(FPanel, FixDir + 'sample.tap');
  s := tapNameLine(FPanel, 3);
  AssertEquals('nameLine data starts with shade block',
               Shade, Copy(s, 1, Length(Shade)));
end;

{ ===== tapLoad ===== }

procedure TTapTest.TestLoad_HeaderProgram;
begin
  FPanel.tapFile := FixDir + 'sample.tap';
  tapMDF(FPanel, FixDir + 'sample.tap');
  { Load entry 3 (data block); entry 2 (preceding header) has the metadata }
  AssertTrue('tapLoad ok', tapLoad(FPanel, 3));
  AssertEquals('loaded name',   'hello     ', HobetaInfo.name);
  AssertEquals('loaded typ',    'B',          HobetaInfo.typ);
  AssertEquals('loaded length', 100,          integer(HobetaInfo.length));
  FreeMem(HobetaInfo.body, 256 * longint(HobetaInfo.totalsec));
end;

{ ===== tapDel ===== }

procedure TTapTest.TestDel_CompactsFile;
{ Delete the data block for "hello" (entry 3, 104 bytes) and verify
  the file shrinks by exactly that amount. }
var
  tmp: string;
  sizeBefore, sizeAfter: longint;
  f: file;
begin
  tmp := ChangeFileExt(GetTempFileName('', 'tap'), '.tap');
  try
    AssertTrue('copy ok', CopyBinaryFile(FixDir + 'sample.tap', tmp));

    FPanel.tapFile := tmp;
    FPanel.PanelType := tapPanel;
    FPanel.tfiles := 0;
    tapMDF(FPanel, tmp);
    { Set focus so PanelTypeOf(oFocus)=tapPanel (TAP-to-TAP path) }
    lp.PanelType := tapPanel;
    rp.PanelType := tapPanel;
    focus := Left;

    Assign(f, tmp); FileMode := 0; Reset(f, 1);
    sizeBefore := FileSize(f);
    Close(f);

    SetMark(3, true);
    AssertTrue('tapDel ok', tapDel(FPanel));

    Assign(f, tmp); FileMode := 0; Reset(f, 1);
    sizeAfter := FileSize(f);
    Close(f);

    { Block 1 (data for hello): 2-byte prefix + w=102 = 104 bytes removed }
    AssertEquals('file shrank by 104', sizeBefore - 104, sizeAfter);
  finally
    DeleteFile(tmp);
  end;
end;

{ ===== TestSave_AllTrdFiles ===== }

procedure TTapTest.TestSave_AllTrdFiles;
{ Load each file from sample.trd via trdLoad, save into a fresh TAP
  via tapSave, then re-read the TAP with tapMDF and verify all
  files are present.  sample.trd has 3 files → expect 6 TAP blocks. }
var
  trdP, tapP: TPanel;
  tmp: string;
  f: file;
  i: integer;
  ok: boolean;
begin
  { Set up TRD source panel. }
  {$push}{$hints off}{$notes off}
  FillChar(trdP, SizeOf(trdP), 0);
  {$pop}
  trdP.PanelType := trdPanel;
  trdP.trdFile   := FixDir + 'sample.trd';
  GetMem(trdP.trdDir, 257 * SizeOf(zxDirRec));
  GetMem(trdP.trdIns, 257 * SizeOf(zxInsedRec));
  {$push}{$notes off}
  FillChar(trdP.trdDir^, 257 * SizeOf(zxDirRec),  0);
  FillChar(trdP.trdIns^, 257 * SizeOf(zxInsedRec), 0);
  {$pop}
  trdMDF(trdP, FixDir + 'sample.trd');
  AssertEquals('trd files', 3, trdP.zxDisk.files);

  tmp := ChangeFileExt(GetTempFileName('', 'tap'), '.tap');
  try
    { Create empty TAP. }
    Assign(f, tmp); Rewrite(f, 1); Close(f);

    { Set up TAP destination panel. }
    {$push}{$hints off}{$notes off}
    FillChar(tapP, SizeOf(tapP), 0);
    {$pop}
    tapP.PanelType := tapPanel;
    tapP.tapFile   := tmp;
    GetMem(tapP.trdDir, 257 * SizeOf(zxDirRec));
    GetMem(tapP.trdIns, 257 * SizeOf(zxInsedRec));
    {$push}{$notes off}
    FillChar(tapP.trdDir^, 257 * SizeOf(zxDirRec),  0);
    FillChar(tapP.trdIns^, 257 * SizeOf(zxInsedRec), 0);
    {$pop}
    tapMDF(tapP, tmp);

    { Copy each TRD file (indices 2..4, skipping << at 1). }
    for i := 2 to trdP.trdtfiles do begin
      ok := trdLoad(trdP, i);
      AssertTrue('trdLoad #' + IntToStr(i), ok);
      ok := tapSave(tapP);
      AssertTrue('tapSave #' + IntToStr(i), ok);
    end;

    { Verify all 3 files were written (943 bytes total). }
    Assign(f, tmp); FileMode := 0; Reset(f, 1);
    AssertEquals('tap file size', 943, FileSize(f));
    Close(f);

    { Re-read TAP and check all files are present. }
    tapMDF(tapP, tmp);
    AssertEquals('tap blocks', 6, tapP.zxDisk.files);
    AssertEquals('tap taptfiles', 7, tapP.taptfiles);

    FreeMem(tapP.trdDir, 257 * SizeOf(zxDirRec));
    FreeMem(tapP.trdIns, 257 * SizeOf(zxInsedRec));
  finally
    DeleteFile(tmp);
  end;
  FreeMem(trdP.trdDir, 257 * SizeOf(zxDirRec));
  FreeMem(trdP.trdIns, 257 * SizeOf(zxInsedRec));
end;

initialization
  RegisterTest(TTapTest);

end.
