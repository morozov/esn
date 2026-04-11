unit test_trd;
{ Unit tests for trd.pas, trd_ovr.pas, and sn_utils.pas helpers. }
{$mode objfpc}{$H+}

interface

uses fpcunit, testregistry, sn_obj;

type
  TTrdTest = class(TTestCase)
  protected
    procedure SetUp; override;
    procedure TearDown; override;
  private
    FPanel: TPanel;
    { Access trdDir entry i (1-based) via pointer; avoids compile-time
      bounds check on the placeholder array[1..1] type. }
    function TrdDir(i: integer): zxDirRec;
    { Same for an arbitrary panel. }
    function PanelTrdDir(var p: TPanel; i: integer): zxDirRec;
    { Set the mark flag on trdDir entry i. }
    procedure SetMark(i: integer; val: boolean);
  published
    procedure TestIsTRD_ValidEmpty;
    procedure TestIsTRD_ValidSample;
    procedure TestIsTRD_BadFile;
    procedure TestIsTRD_Missing;

    procedure TestBpos_Track0Sector0;
    procedure TestBpos_Track0Sector8;
    procedure TestBpos_Track1Sector0;

    procedure TestMDF_Empty_FileCount;
    procedure TestMDF_Empty_FreeSectors;

    procedure TestMDF_SampleFileCount;
    procedure TestMDF_SampleEntry1_Name;
    procedure TestMDF_SampleEntry1_Type;
    procedure TestMDF_SampleEntry1_Length;
    procedure TestMDF_SampleEntry2_Name;
    procedure TestMDF_SampleEntry2_Start;
    procedure TestMDF_SampleEntry3_TotalSec;
    procedure TestMDF_DiskLabel;
    procedure TestMDF_DiskFree;
    procedure TestMDF_DiskType;

    procedure TestTRDOSe3_TypeB;
    procedure TestTRDOSe3_TypeC;
    procedure TestTRDOSe31_TypeB;
    procedure TestTRDOSe31_TypeC;

    procedure TestNameLine_ContainsName;
    procedure TestNameLine_ContainsType;

    procedure TestLoadSave_RoundTrip;

    procedure TestMakeImageFile_80Track_IsValid;
    procedure TestMakeImageFile_80Track_FreeSectors;
    procedure TestMakeImageFile_40Track_DiskTyp;

    procedure TestDel_IncreasesDelCount;
    procedure TestDel_FileDisappearsAfterReload;

    procedure TestMatchMask_Star;
    procedure TestMatchMask_Question;
    procedure TestMatchMask_Exact;
    procedure TestMatchMask_NoMatch;

    procedure TestStrR_Zero;
    procedure TestStrR_Positive;
    procedure TestStrR_Negative;
    procedure TestExtNum_Thousands;
    procedure TestExtNum_Small;
    procedure TestChangeChar_Space;
    procedure TestChangeChar_NoOp;
    procedure TestLeftPad_Pads;
    procedure TestLeftPad_NoOp;
    procedure TestRightPad_Pads;

    procedure TestCrc16_Consistent;
    procedure TestCrc16_Differs;

    procedure TestIniWrite_Read;
    procedure TestIniMissing_KeyPreservesDefault;

    procedure TestItHobeta_NonHobeta;
  end;

implementation

uses trd, trd_ovr, vars, sn_mem, rv, crc, SysUtils;

const
  FixDir = '../fixtures/';

{ ===== Private helpers ===== }

function TTrdTest.TrdDir(i: integer): zxDirRec;
var
  ep: ^zxDirRec;
begin
  ep := @FPanel.trdDir^[1];
  Inc(ep, i - 1);
  TrdDir := ep^;
end;

function TTrdTest.PanelTrdDir(var p: TPanel; i: integer): zxDirRec;
var
  ep: ^zxDirRec;
begin
  ep := @p.trdDir^[1];
  Inc(ep, i - 1);
  PanelTrdDir := ep^;
end;

procedure TTrdTest.SetMark(i: integer; val: boolean);
var
  ep: ^zxDirRec;
begin
  ep := @FPanel.trdDir^[1];
  Inc(ep, i - 1);
  ep^.mark := val;
end;

procedure TTrdTest.SetUp;
begin
  GetMemPCDirs;
  {$push}{$notes off}
  FillChar(FPanel, SizeOf(FPanel), 0);
  {$pop}
  FPanel.PanelType := trdPanel;
  GetMem(FPanel.trdDir, 257 * SizeOf(zxDirRec));
  GetMem(FPanel.trdIns, 257 * SizeOf(zxInsedRec));
  {$push}{$notes off}
  FillChar(FPanel.trdDir^, 257 * SizeOf(zxDirRec),  0);
  FillChar(FPanel.trdIns^, 257 * SizeOf(zxInsedRec), 0);
  {$pop}
  TRDOS3 := false;
end;

procedure TTrdTest.TearDown;
begin
  FreeMem(FPanel.trdDir, 257 * SizeOf(zxDirRec));
  FreeMem(FPanel.trdIns, 257 * SizeOf(zxInsedRec));
  FreeMemPCDirs;
end;

{ Helper: copy a binary file; returns true on success. }
function CopyBinaryFile(const src, dst: string): boolean;
var
  sf, df: file;
  buf: array[1..4096] of byte;
  nr, nw: word;
begin
  CopyBinaryFile := false;
  nr := 0; nw := 0;
  buf[1] := 0;  { satisfy FPC flow analysis; BlockRead fills the rest }
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
    { Caller checks return value }
  end;
end;

{ Returns a fresh zeroed panel with trdDir/trdIns allocated.
  Returned via function so the caller's variable is considered initialized. }
function NewPanel(const trdFile: string): TPanel;
begin
  Result.PanelType := noPanel;  { explicit init so FPC tracks Result as assigned }
  {$push}{$notes off}
  FillChar(Result, SizeOf(Result), 0);
  {$pop}
  Result.PanelType := trdPanel;
  Result.trdFile   := trdFile;
  GetMem(Result.trdDir, 257 * SizeOf(zxDirRec));
  GetMem(Result.trdIns, 257 * SizeOf(zxInsedRec));
  {$push}{$notes off}
  FillChar(Result.trdDir^, 257 * SizeOf(zxDirRec),  0);
  FillChar(Result.trdIns^, 257 * SizeOf(zxInsedRec), 0);
  {$pop}
end;

procedure FreePanel(var p: TPanel);
begin
  FreeMem(p.trdDir, 257 * SizeOf(zxDirRec));
  FreeMem(p.trdIns, 257 * SizeOf(zxInsedRec));
end;

{ ===== isTRD ===== }

procedure TTrdTest.TestIsTRD_ValidEmpty;
begin
  AssertTrue('empty.trd valid', isTRD(FixDir + 'empty.trd'));
end;

procedure TTrdTest.TestIsTRD_ValidSample;
begin
  AssertTrue('sample.trd valid', isTRD(FixDir + 'sample.trd'));
end;

procedure TTrdTest.TestIsTRD_BadFile;
var
  tmp: string;
  f: TextFile;
begin
  tmp := GetTempFileName('', 'tst');
  AssignFile(f, tmp);
  Rewrite(f);
  WriteLn(f, 'not a trd file');
  CloseFile(f);
  try
    AssertFalse('text file is not TRD', isTRD(tmp));
  finally
    DeleteFile(tmp);
  end;
end;

procedure TTrdTest.TestIsTRD_Missing;
begin
  AssertFalse('missing file is not TRD',
    isTRD(FixDir + 'does_not_exist.trd'));
end;

{ ===== bpos ===== }

procedure TTrdTest.TestBpos_Track0Sector0;
begin
  AssertEquals('bpos(0,0)', 0, bpos(0, 0));
end;

procedure TTrdTest.TestBpos_Track0Sector8;
begin
  AssertEquals('bpos(0,8)', 2048, bpos(0, 8));
end;

procedure TTrdTest.TestBpos_Track1Sector0;
begin
  AssertEquals('bpos(1,0)', 4096, bpos(1, 0));
end;

{ ===== trdMDF: empty ===== }

procedure TTrdTest.TestMDF_Empty_FileCount;
begin
  FPanel.trdFile := FixDir + 'empty.trd';
  trdMDF(FPanel, FixDir + 'empty.trd');
  AssertEquals('empty: trdtfiles', 1, FPanel.trdtfiles);
  AssertEquals('empty: zxDisk.files', 0, FPanel.zxDisk.files);
end;

procedure TTrdTest.TestMDF_Empty_FreeSectors;
begin
  FPanel.trdFile := FixDir + 'empty.trd';
  trdMDF(FPanel, FixDir + 'empty.trd');
  AssertEquals('empty: free', 2544, FPanel.zxDisk.free);
end;

{ ===== trdMDF: sample ===== }

procedure TTrdTest.TestMDF_SampleFileCount;
begin
  FPanel.trdFile := FixDir + 'sample.trd';
  trdMDF(FPanel, FixDir + 'sample.trd');
  AssertEquals('sample: trdtfiles', 4, FPanel.trdtfiles);
  AssertEquals('sample: files', 3, FPanel.zxDisk.files);
end;

procedure TTrdTest.TestMDF_SampleEntry1_Name;
begin
  FPanel.trdFile := FixDir + 'sample.trd';
  trdMDF(FPanel, FixDir + 'sample.trd');
  AssertEquals('entry2 name', 'hello   ', TrdDir(2).name);
end;

procedure TTrdTest.TestMDF_SampleEntry1_Type;
begin
  FPanel.trdFile := FixDir + 'sample.trd';
  trdMDF(FPanel, FixDir + 'sample.trd');
  AssertEquals('entry2 type', 'B', TrdDir(2).typ);
end;

procedure TTrdTest.TestMDF_SampleEntry1_Length;
begin
  FPanel.trdFile := FixDir + 'sample.trd';
  trdMDF(FPanel, FixDir + 'sample.trd');
  AssertEquals('entry2 length', 100, integer(TrdDir(2).length));
end;

procedure TTrdTest.TestMDF_SampleEntry2_Name;
begin
  FPanel.trdFile := FixDir + 'sample.trd';
  trdMDF(FPanel, FixDir + 'sample.trd');
  AssertEquals('entry3 name', 'data    ', TrdDir(3).name);
end;

procedure TTrdTest.TestMDF_SampleEntry2_Start;
begin
  FPanel.trdFile := FixDir + 'sample.trd';
  trdMDF(FPanel, FixDir + 'sample.trd');
  AssertEquals('entry3 start', 32768, integer(TrdDir(3).start));
end;

procedure TTrdTest.TestMDF_SampleEntry3_TotalSec;
begin
  FPanel.trdFile := FixDir + 'sample.trd';
  trdMDF(FPanel, FixDir + 'sample.trd');
  AssertEquals('entry4 totalsec', 2, integer(TrdDir(4).totalsec));
end;

procedure TTrdTest.TestMDF_DiskLabel;
begin
  FPanel.trdFile := FixDir + 'sample.trd';
  trdMDF(FPanel, FixDir + 'sample.trd');
  AssertEquals('disk label', 'SAMPLE  ', FPanel.zxDisk.diskLabel);
end;

procedure TTrdTest.TestMDF_DiskFree;
begin
  FPanel.trdFile := FixDir + 'sample.trd';
  trdMDF(FPanel, FixDir + 'sample.trd');
  AssertEquals('disk free', 2540, FPanel.zxDisk.free);
end;

procedure TTrdTest.TestMDF_DiskType;
begin
  FPanel.trdFile := FixDir + 'sample.trd';
  trdMDF(FPanel, FixDir + 'sample.trd');
  AssertEquals('diskTyp', $16, FPanel.zxDisk.DiskTyp);
end;

{ ===== TRDOSe3 / TRDOSe31 ===== }

procedure TTrdTest.TestTRDOSe3_TypeB;
begin
  FPanel.trdFile := FixDir + 'sample.trd';
  trdMDF(FPanel, FixDir + 'sample.trd');
  AssertEquals('TRDOSe3 B', '<B>', TRDOSe3(FPanel, 2));
end;

procedure TTrdTest.TestTRDOSe3_TypeC;
begin
  FPanel.trdFile := FixDir + 'sample.trd';
  trdMDF(FPanel, FixDir + 'sample.trd');
  AssertEquals('TRDOSe3 C', '<C>', TRDOSe3(FPanel, 3));
end;

procedure TTrdTest.TestTRDOSe31_TypeB;
begin
  FPanel.trdFile := FixDir + 'sample.trd';
  trdMDF(FPanel, FixDir + 'sample.trd');
  AssertEquals('TRDOSe31 B', 'B', TRDOSe31(FPanel, 2));
end;

procedure TTrdTest.TestTRDOSe31_TypeC;
begin
  FPanel.trdFile := FixDir + 'sample.trd';
  trdMDF(FPanel, FixDir + 'sample.trd');
  AssertEquals('TRDOSe31 C', 'C', TRDOSe31(FPanel, 3));
end;

{ ===== trdNameLine ===== }

procedure TTrdTest.TestNameLine_ContainsName;
var
  s: string;
begin
  FPanel.trdFile := FixDir + 'sample.trd';
  trdMDF(FPanel, FixDir + 'sample.trd');
  s := trdNameLine(FPanel, 2);
  AssertTrue('nameLine has hello', Pos('hello', s) > 0);
end;

procedure TTrdTest.TestNameLine_ContainsType;
var
  s: string;
begin
  FPanel.trdFile := FixDir + 'sample.trd';
  trdMDF(FPanel, FixDir + 'sample.trd');
  s := trdNameLine(FPanel, 2);
  AssertTrue('nameLine has <B>', Pos('<B>', s) > 0);
end;

{ ===== trdLoad / trdSave round-trip ===== }

procedure TTrdTest.TestLoadSave_RoundTrip;
var
  tmp: string;
  ok: boolean;
  p2: TPanel;
  ep: ^zxDirRec;
begin
  FPanel.trdFile := FixDir + 'sample.trd';
  trdMDF(FPanel, FixDir + 'sample.trd');
  ok := trdLoad(FPanel, 2);
  AssertTrue('trdLoad ok', ok);
  AssertEquals('loaded name', 'hello   ', HobetaInfo.name);

  tmp := GetTempFileName('', 'trd');
  try
    ok := trdMakeImageFile(tmp, 80);
    AssertTrue('make image ok', ok);

    p2 := NewPanel(tmp);
    try
      trdMDF(p2, tmp);
      ok := trdSave(p2);
      AssertTrue('trdSave ok', ok);

      FreePanel(p2);
      p2 := NewPanel(tmp);
      trdMDF(p2, tmp);
      AssertEquals('after save: 1 file', 1, p2.zxDisk.files);
      ep := @p2.trdDir^[1]; Inc(ep);  { entry 2 }
      AssertEquals('saved name',   'hello   ', ep^.name);
      AssertEquals('saved type',   'B',        ep^.typ);
      AssertEquals('saved length', 100, integer(ep^.length));
      FreePanel(p2);
    except
      FreePanel(p2);
      raise;
    end;
  finally
    DeleteFile(tmp);
  end;
end;

{ ===== trdMakeImageFile ===== }

procedure TTrdTest.TestMakeImageFile_80Track_IsValid;
var
  tmp: string;
begin
  tmp := GetTempFileName('', 'trd');
  try
    AssertTrue('make 80-track', trdMakeImageFile(tmp, 80));
    AssertTrue('80-track is valid TRD', isTRD(tmp));
  finally
    DeleteFile(tmp);
  end;
end;

procedure TTrdTest.TestMakeImageFile_80Track_FreeSectors;
var
  tmp: string;
  p2: TPanel;
begin
  tmp := GetTempFileName('', 'trd');
  try
    trdMakeImageFile(tmp, 80);
    p2 := NewPanel(tmp);
    try
      trdMDF(p2, tmp);
      AssertEquals('80-track free', 2544, p2.zxDisk.free);
    finally
      FreePanel(p2);
    end;
  finally
    DeleteFile(tmp);
  end;
end;

procedure TTrdTest.TestMakeImageFile_40Track_DiskTyp;
var
  tmp: string;
  p2: TPanel;
begin
  tmp := GetTempFileName('', 'trd');
  try
    trdMakeImageFile(tmp, 40);
    p2 := NewPanel(tmp);
    try
      trdMDF(p2, tmp);
      AssertEquals('40-track diskTyp', $17, p2.zxDisk.DiskTyp);
      AssertEquals('40-track free', 1264, p2.zxDisk.free);
    finally
      FreePanel(p2);
    end;
  finally
    DeleteFile(tmp);
  end;
end;

{ ===== trdDel ===== }

procedure TTrdTest.TestDel_IncreasesDelCount;
var
  tmp: string;
  p2: TPanel;
begin
  tmp := GetTempFileName('', 'trd');
  try
    AssertTrue('copy fixture', CopyBinaryFile(FixDir + 'sample.trd', tmp));
    FPanel.trdFile := tmp;
    trdMDF(FPanel, tmp);
    FPanel.tfiles := FPanel.trdtfiles;
    SetMark(2, true);
    AssertTrue('trdDel ok', trdDel(FPanel));

    p2 := NewPanel(tmp);
    try
      trdMDF(p2, tmp);
      AssertEquals('delfiles = 1', 1, p2.zxDisk.delfiles);
    finally
      FreePanel(p2);
    end;
  finally
    DeleteFile(tmp);
  end;
end;

procedure TTrdTest.TestDel_FileDisappearsAfterReload;
var
  tmp: string;
  p2: TPanel;
  ep: ^zxDirRec;
begin
  tmp := GetTempFileName('', 'trd');
  try
    CopyBinaryFile(FixDir + 'sample.trd', tmp);
    FPanel.trdFile := tmp;
    trdMDF(FPanel, tmp);
    FPanel.tfiles := FPanel.trdtfiles;
    SetMark(2, true);
    trdDel(FPanel);

    p2 := NewPanel(tmp);
    try
      trdMDF(p2, tmp);
      { Original behaviour: deleted entries (name[1]=chr(1)) are NOT
        skipped.  The disk header file count stays at 3, and the
        deleted entry is still present in the directory listing. }
      AssertEquals('file count unchanged', 3, p2.zxDisk.files);
      ep := @p2.trdDir^[1]; Inc(ep);  { entry 2 }
      AssertEquals('deleted marker', Chr(1), ep^.name[1]);
    finally
      FreePanel(p2);
    end;
  finally
    DeleteFile(tmp);
  end;
end;

{ ===== MatchMask ===== }

procedure TTrdTest.TestMatchMask_Star;
begin
  AssertTrue('*.pas',  MatchMask('foo.pas',   '*.pas'));
  AssertTrue('*.*',    MatchMask('hello.trd', '*.*'));
  AssertFalse('*.pas no .trd', MatchMask('foo.trd', '*.pas'));
end;

procedure TTrdTest.TestMatchMask_Question;
begin
  AssertTrue('f?o',  MatchMask('foo', 'f?o'));
  AssertFalse('f?o no fo', MatchMask('fo', 'f?o'));
end;

procedure TTrdTest.TestMatchMask_Exact;
begin
  AssertTrue('exact',    MatchMask('hello', 'hello'));
  AssertFalse('no match', MatchMask('hello', 'world'));
end;

procedure TTrdTest.TestMatchMask_NoMatch;
begin
  AssertFalse('x vs empty', MatchMask('x', ''));
  AssertTrue('empty vs empty', MatchMask('', ''));
  AssertTrue('star vs empty', MatchMask('', '*'));
end;

{ ===== String helpers ===== }

procedure TTrdTest.TestStrR_Zero;
begin
  AssertEquals('StrR(0)', '0', StrR(0));
end;

procedure TTrdTest.TestStrR_Positive;
begin
  AssertEquals('StrR(42)',   '42',   StrR(42));
  AssertEquals('StrR(9999)', '9999', StrR(9999));
end;

procedure TTrdTest.TestStrR_Negative;
begin
  AssertEquals('StrR(-1)', '-1', StrR(-1));
end;

procedure TTrdTest.TestExtNum_Thousands;
begin
  AssertEquals('ExtNum 1234',    '1 234',     ExtNum('1234'));
  AssertEquals('ExtNum 1000000', '1 000 000', ExtNum('1000000'));
end;

procedure TTrdTest.TestExtNum_Small;
begin
  AssertEquals('ExtNum 99', '99', ExtNum('99'));
  AssertEquals('ExtNum 0',  '0',  ExtNum('0'));
end;

procedure TTrdTest.TestChangeChar_Space;
begin
  AssertEquals('space->comma', 'a,b,c', ChangeChar('a b c', ' ', ','));
end;

procedure TTrdTest.TestChangeChar_NoOp;
begin
  AssertEquals('no-op', 'abc', ChangeChar('abc', 'x', 'y'));
end;

procedure TTrdTest.TestLeftPad_Pads;
begin
  AssertEquals('LeftPad to 5', '  abc', LeftPad('abc', 5));
end;

procedure TTrdTest.TestLeftPad_NoOp;
begin
  AssertEquals('LeftPad no-op', 'abcde', LeftPad('abcde', 3));
end;

procedure TTrdTest.TestRightPad_Pads;
begin
  AssertEquals('RightPad to 5', 'abc  ', RightPad('abc', 5));
end;

{ ===== Crc16 ===== }

procedure TTrdTest.TestCrc16_Consistent;
begin
  AssertEquals('Crc16 same', Crc16('hello'), Crc16('hello'));
end;

procedure TTrdTest.TestCrc16_Differs;
begin
  AssertFalse('Crc16 differs', Crc16('hello') = Crc16('world'));
end;

{ ===== INI ===== }

procedure TTrdTest.TestIniWrite_Read;
var
  tmp, v: string;
begin
  tmp := GetTempFileName('', 'ini');
  try
    WriteProfile(tmp, 'Interface', 'Lang', '2');
    v := '0';
    GetProfile(tmp, 'Interface', 'Lang', v);
    AssertEquals('INI Lang', '2', v);
  finally
    DeleteFile(tmp);
  end;
end;

procedure TTrdTest.TestIniMissing_KeyPreservesDefault;
var
  tmp, v: string;
begin
  tmp := GetTempFileName('', 'ini');
  try
    WriteProfile(tmp, 'A', 'x', '1');
    v := 'default';
    GetProfile(tmp, 'A', 'NoSuchKey', v);
    AssertEquals('missing key', 'default', v);
  finally
    DeleteFile(tmp);
  end;
end;

{ ===== itHobeta ===== }

procedure TTrdTest.TestItHobeta_NonHobeta;
var
  tmp: string;
  rec: HobRec;
  f: TextFile;
begin
  rec.tapFlag := 0;  { explicit field assignment satisfies FPC flow analysis }
  tmp := GetTempFileName('', 'dat');
  AssignFile(f, tmp);
  Rewrite(f);
  WriteLn(f, 'not a hobeta file at all');
  CloseFile(f);
  try
    AssertFalse('text is not Hobeta', itHobeta(tmp, rec));
  finally
    DeleteFile(tmp);
  end;
end;

initialization
  RegisterTest(TTrdTest);

end.
