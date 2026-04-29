unit test_fdi;
{ Unit tests for fdi.pas and fdi_ovr.pas.

  Each test builds a tiny 2-track FDI in a temp file with rotational
  skew on every track, so the bpos-style "logical = physical" assumption
  is wrong. A correct implementation must consult the per-track sector
  descriptors to find each sector's physical offset.

  Layout:
    cyl=1, heads=2 → 2 logical tracks (cyl 0/head 0, cyl 0/head 1).
    cyl 0/head 0 has rotational skew 1: sec_id k → physical pos k mod 16.
    cyl 0/head 1 has rotational skew 2: sec_id k → physical pos (k+1) mod 16.
    Every sector's 256 bytes are filled with its sec_id, except
    sec_id 1 of cyl 0/head 0 (TR-DOS directory: one entry "TEST") and
    sec_id 9 of cyl 0/head 0 (disk-info area at byte 0xe0..0xff).
    The "TEST" file has n1tr=1, n1sec=0, totalsec=16 — its body fills
    cyl 0/head 1 entirely. Reading byte (k-1)*256 of the body must
    return k (the sec_id) when sectors are accessed in CHRN order. }
{$mode objfpc}{$H+}

interface

uses fpcunit, testregistry, sn_obj;

type
  TFdiTest = class(TTestCase)
  protected
    procedure SetUp; override;
    procedure TearDown; override;
  private
    FPanel: TPanel;
    FFdiPath: string;
  published
    procedure TestIsFDI_AcceptsSynth;
    procedure TestMDF_FileCount;
    procedure TestMDF_FreeSectors;
    procedure TestMDF_DiskLabel;
    procedure TestMDF_DirEntry_Name;
    procedure TestMDF_DirEntry_Geometry;
    procedure TestLoad_BodyInChrnOrder;
  end;

implementation

uses fdi, fdi_ovr, vars, sn_mem, SysUtils;

const
  NSEC          = 16;
  NTRK          = 2;
  HDR_SIZE      = 14;
  TRK_HDR_SIZE  = 7;
  SEC_DESC_SIZE = 7;
  TRACK_HDRS    = NTRK * (TRK_HDR_SIZE + NSEC * SEC_DESC_SIZE);
  OFF_DATA      = HDR_SIZE + TRACK_HDRS;            { 14 + 2*119 = 252 }
  TRACK_BYTES   = NSEC * 256;
  FDI_SIZE      = OFF_DATA + NTRK * TRACK_BYTES;    { 252 + 8192 = 8444 }

  TestFile_Typ      = 'B';
  TestFile_Start    = 0;
  TestFile_Length   = 4096;
  TestFile_TotalSec = NSEC;
  TestFile_N1Tr     = 1;        { cyl 0/head 1 }
  TestFile_N1Sec    = 0;
  DiskLabel         = 'SYNTH   ';

{ Build a synthetic 2-track FDI at `path`. See unit header for layout. }
procedure BuildSyntheticFdi(const path: string);
var
  buf: array[0..FDI_SIZE - 1] of byte;
  fb: file;
  i: integer;
  trk0Data, sec1Off, sec9Off: integer;

  procedure W16(off: integer; v: word);
  begin
    buf[off]     := byte(v);
    buf[off + 1] := byte(v shr 8);
  end;

  procedure W32(off: integer; v: longint);
  begin
    buf[off]     := byte(v);
    buf[off + 1] := byte(v shr 8);
    buf[off + 2] := byte(v shr 16);
    buf[off + 3] := byte(v shr 24);
  end;

  { Write track `trkIdx` (= cyl*heads + head) with rotational `skew`.
    Sector k's payload is `k` repeated 256 times. }
  procedure WriteTrack(trkIdx, skew: integer);
  var
    hdrOff, dataOff: integer;
    secId, physPos, offInTrk, descOff: integer;
  begin
    hdrOff  := HDR_SIZE + trkIdx * (TRK_HDR_SIZE + NSEC * SEC_DESC_SIZE);
    dataOff := OFF_DATA + trkIdx * TRACK_BYTES;
    W32(hdrOff, trkIdx * TRACK_BYTES);  { track_off, relative to OFF_DATA }
    buf[hdrOff + 4] := 0;
    buf[hdrOff + 5] := 0;
    buf[hdrOff + 6] := NSEC;
    for secId := 1 to NSEC do
    begin
      physPos  := (secId - 1 + skew) mod NSEC;
      offInTrk := physPos * 256;
      descOff  := hdrOff + TRK_HDR_SIZE + (secId - 1) * SEC_DESC_SIZE;
      buf[descOff + 0] := 0;        { cyl }
      buf[descOff + 1] := trkIdx;   { head — fine here since cyl=0 }
      buf[descOff + 2] := secId;
      buf[descOff + 3] := 1;        { size_code: 1 → 256 bytes }
      buf[descOff + 4] := 2;        { flags: DAM mark, no errors }
      W16(descOff + 5, offInTrk);
      {$push}{$notes off}
      FillChar(buf[dataOff + offInTrk], 256, secId);
      {$pop}
    end;
  end;

begin
  {$push}{$notes off}
  FillChar(buf, SizeOf(buf), 0);
  {$pop}

  { FDI header. }
  buf[0] := ord('F'); buf[1] := ord('D'); buf[2] := ord('I');
  buf[3] := 0;
  W16(4,  1);          { cyl = 1 }
  W16(6,  NTRK);       { heads = 2 }
  W16(8,  0);          { offText (unused) }
  W16(10, OFF_DATA);
  W16(12, 0);          { extDataLen = 0 }

  { Per-track headers + filler data (sec_id-valued bytes). }
  WriteTrack(0, 1);
  WriteTrack(1, 2);

  { Overlay TR-DOS directory in sec_id 1 of cyl 0/head 0.
    With skew=1, sec_id 1 sits at physical position 1, byte offset 256
    of cyl 0/head 0's data. }
  trk0Data := OFF_DATA;
  sec1Off  := trk0Data + 1 * 256;
  {$push}{$notes off}
  FillChar(buf[sec1Off], 256, 0);  { entire dir sector zeroed first }
  {$pop}
  buf[sec1Off + 0] := ord('T');
  buf[sec1Off + 1] := ord('E');
  buf[sec1Off + 2] := ord('S');
  buf[sec1Off + 3] := ord('T');
  buf[sec1Off + 4] := ord(' ');
  buf[sec1Off + 5] := ord(' ');
  buf[sec1Off + 6] := ord(' ');
  buf[sec1Off + 7] := ord(' ');
  buf[sec1Off + 8] := ord(TestFile_Typ);
  W16(sec1Off +  9, TestFile_Start);
  W16(sec1Off + 11, TestFile_Length);
  buf[sec1Off + 13] := TestFile_TotalSec;
  buf[sec1Off + 14] := TestFile_N1Sec;
  buf[sec1Off + 15] := TestFile_N1Tr;

  { Overlay disk-info area in sec_id 9 of cyl 0/head 0, bytes $e0..$ff.
    With skew=1, sec_id 9 sits at physical position 9. }
  sec9Off := trk0Data + 9 * 256;
  {$push}{$notes off}
  FillChar(buf[sec9Off + $e0], $20, 0);
  {$pop}
  buf[sec9Off + $e1] := NSEC;     { n1freesec }
  buf[sec9Off + $e2] := 2;        { ntr1freesec — past the 2 tracks }
  buf[sec9Off + $e3] := $16;      { disktyp: 80T DS (closest valid) }
  buf[sec9Off + $e4] := 1;        { files }
  W16(sec9Off + $e5, 0);          { free }
  buf[sec9Off + $e7] := $10;      { trdoscode — required by isFDI }
  buf[sec9Off + $f4] := 0;        { delfiles }
  for i := 1 to 8 do
    buf[sec9Off + $f4 + i] := byte(DiskLabel[i]);

  Assign(fb, path);
  FileMode := 2;
  Rewrite(fb, 1);
  try
    BlockWrite(fb, buf[0], FDI_SIZE);
  finally
    Close(fb);
  end;
end;

procedure TFdiTest.SetUp;
begin
  GetMemPCDirs;
  {$push}{$notes off}
  FillChar(FPanel, SizeOf(FPanel), 0);
  {$pop}
  FPanel.PanelType := fdiPanel;
  GetMem(FPanel.trdDir, 257 * SizeOf(zxDirRec));
  GetMem(FPanel.trdIns, 257 * SizeOf(zxInsedRec));
  GetMem(FPanel.fdiSecOff, SizeOf(TFdiSecOffMap));
  {$push}{$notes off}
  FillChar(FPanel.trdDir^,    257 * SizeOf(zxDirRec),   0);
  FillChar(FPanel.trdIns^,    257 * SizeOf(zxInsedRec), 0);
  FillChar(FPanel.fdiSecOff^, SizeOf(TFdiSecOffMap),    0);
  {$pop}
  FFdiPath := GetTempFileName('', 'esnfdi');
  BuildSyntheticFdi(FFdiPath);
end;

procedure TFdiTest.TearDown;
begin
  DeleteFile(FFdiPath);
  FreeMem(FPanel.trdDir,    257 * SizeOf(zxDirRec));
  FreeMem(FPanel.trdIns,    257 * SizeOf(zxInsedRec));
  FreeMem(FPanel.fdiSecOff, SizeOf(TFdiSecOffMap));
  FreeMemPCDirs;
end;

{ ===== isFDI ===== }

procedure TFdiTest.TestIsFDI_AcceptsSynth;
begin
  AssertTrue('synthetic FDI detected', isFDI(FPanel, FFdiPath));
end;

{ ===== fdiMDF =====

  These tests prove fdiTrk0Abs routes the disk-info and directory
  reads through the per-track sector map. Without the fix, fdiMDF
  would seek to physical positions 8 and 0 of cyl 0/head 0 (which
  hold sec_id 8 and sec_id 16 of pure filler) and parse garbage. }

procedure TFdiTest.TestMDF_FileCount;
begin
  FPanel.fdiFile := FFdiPath;
  fdiMDF(FPanel, FFdiPath);
  AssertEquals('zxDisk.files', 1, FPanel.zxDisk.files);
end;

procedure TFdiTest.TestMDF_FreeSectors;
begin
  FPanel.fdiFile := FFdiPath;
  fdiMDF(FPanel, FFdiPath);
  AssertEquals('zxDisk.free', 0, FPanel.zxDisk.free);
end;

procedure TFdiTest.TestMDF_DiskLabel;
begin
  FPanel.fdiFile := FFdiPath;
  fdiMDF(FPanel, FFdiPath);
  AssertEquals('disk label', DiskLabel, FPanel.zxDisk.diskLabel);
end;

procedure TFdiTest.TestMDF_DirEntry_Name;
var
  ep: ^zxDirRec;
begin
  FPanel.fdiFile := FFdiPath;
  fdiMDF(FPanel, FFdiPath);
  ep := @FPanel.trdDir^[1]; Inc(ep);  { entry 2 = first user file }
  AssertEquals('entry name', 'TEST    ', ep^.name);
end;

procedure TFdiTest.TestMDF_DirEntry_Geometry;
var
  ep: ^zxDirRec;
begin
  FPanel.fdiFile := FFdiPath;
  fdiMDF(FPanel, FFdiPath);
  ep := @FPanel.trdDir^[1]; Inc(ep);
  AssertEquals('totalsec', TestFile_TotalSec, integer(ep^.totalsec));
  AssertEquals('n1tr',     TestFile_N1Tr,     integer(ep^.n1tr));
  AssertEquals('n1sec',    TestFile_N1Sec,    integer(ep^.n1sec));
end;

{ ===== fdiLoad =====

  The TEST file occupies all 16 sectors of cyl 0/head 1, which has
  rotational skew 2. In CHRN order, sec_id k's data (= byte k repeated)
  must land at body offset (k-1)*256. A bpos-based read would deliver
  the *physical* order [sec 15, 16, 1, ..., 14] — body[1] would be 15,
  not 1. }

procedure TFdiTest.TestLoad_BodyInChrnOrder;
const
  IxTest = 2;   { entry 1 is the synthetic '<<' parent }
var
  k, i, base: integer;
  b: byte;
begin
  FPanel.fdiFile := FFdiPath;
  fdiMDF(FPanel, FFdiPath);
  AssertTrue('fdiLoad ok', fdiLoad(FPanel, IxTest));
  try
    AssertEquals('totalsec', TestFile_TotalSec,
                 integer(HobetaInfo.totalsec));
    for k := 1 to NSEC do
    begin
      base := (k - 1) * 256;
      for i := 0 to 255 do
      begin
        b := HobetaInfo.body^[base + i + 1];
        AssertEquals('sec ' + IntToStr(k) + ' byte ' + IntToStr(i),
                     k, integer(b));
      end;
    end;
  finally
    FreeMem(HobetaInfo.body, 256 * longint(HobetaInfo.totalsec));
  end;
end;

initialization
  RegisterTest(TFdiTest);

end.
