unit test_sn_utils;
{ Tests for sn_utils helpers, including FormatFreeBytes. }
{$mode objfpc}{$H+}

interface

uses fpcunit, testregistry, rv;

type
  TSnUtilsTest = class(TTestCase)
  published
    { FormatFreeBytes: correct formatting, no negative values }
    procedure TestFormatFreeBytes_Zero;
    procedure TestFormatFreeBytes_Small;
    procedure TestFormatFreeBytes_AtThreshold;
    procedure TestFormatFreeBytes_AboveThreshold;
    procedure TestFormatFreeBytes_LargeInt64;
    procedure TestFormatFreeBytes_Negative;
  end;

implementation

{ FormatFreeBytes }

procedure TSnUtilsTest.TestFormatFreeBytes_Zero;
begin
  AssertEquals('0', FormatFreeBytes(0));
end;

procedure TSnUtilsTest.TestFormatFreeBytes_Small;
begin
  AssertEquals('1,234', FormatFreeBytes(1234));
end;

procedure TSnUtilsTest.TestFormatFreeBytes_AtThreshold;
begin
  { 999 999 999 is the last value shown in bytes }
  AssertEquals('999,999,999', FormatFreeBytes(999999999));
end;

procedure TSnUtilsTest.TestFormatFreeBytes_AboveThreshold;
begin
  { 1 000 000 000 → 1000 div 1 000 000 = 1000 — actually 1G }
  AssertEquals('1,000G', FormatFreeBytes(1000000000));
end;

procedure TSnUtilsTest.TestFormatFreeBytes_LargeInt64;
begin
  { 100 GB — must not be negative or truncated }
  { 100 * 1024^3 = 107 374 182 400 → div 1 000 000 = 107 374 }
  AssertEquals('107,374G', FormatFreeBytes(Int64(100) * 1024 * 1024 * 1024));
end;

procedure TSnUtilsTest.TestFormatFreeBytes_Negative;
begin
  { Negative = DiskFree error; must display as 0, not a negative string }
  AssertEquals('0', FormatFreeBytes(-1));
end;

initialization
  RegisterTest(TSnUtilsTest);

end.
