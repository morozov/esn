unit test_sn_utils;
{ Tests for sn_utils helpers, including FormatFreeBytes. }
{$mode objfpc}{$H+}

interface

uses fpcunit, testregistry, rv;

type
  TFormatFreeBytesTest = class(TTestCase)
  published
    procedure TestNegative;
    procedure TestZero;
    procedure TestBytes;
    procedure TestKilo;
    procedure TestKiloFraction;
    procedure TestKiloExact;
    procedure TestKiloLarge;
    procedure TestMega;
    procedure TestMegaFraction;
    procedure TestMegaLarge;
    procedure TestGiga;
    procedure TestGigaFraction;
    procedure TestGigaLarge;
    procedure TestTera;
    procedure TestTeraFraction;
    procedure TestTeraLarge;
    procedure TestTeraMax;
  end;

implementation

procedure TFormatFreeBytesTest.TestNegative;
begin
  AssertEquals('0', FormatFreeBytes(-1));
end;

procedure TFormatFreeBytesTest.TestZero;
begin
  AssertEquals('0', FormatFreeBytes(0));
end;

procedure TFormatFreeBytesTest.TestBytes;
begin
  AssertEquals('500', FormatFreeBytes(500));
  AssertEquals('1023', FormatFreeBytes(1023));
end;

procedure TFormatFreeBytesTest.TestKilo;
begin
  { 1024 -> 1.0K }
  AssertEquals('1.0K', FormatFreeBytes(1024));
end;

procedure TFormatFreeBytesTest.TestKiloFraction;
begin
  { 1536 = 1.5 * 1024 -> 1.5K }
  AssertEquals('1.5K', FormatFreeBytes(1536));
end;

procedure TFormatFreeBytesTest.TestKiloExact;
begin
  { 5 * 1024 = 5120 -> 5.0K }
  AssertEquals('5.0K', FormatFreeBytes(5120));
end;

procedure TFormatFreeBytesTest.TestKiloLarge;
begin
  { 10 * 1024 -> 10K }
  AssertEquals('10K', FormatFreeBytes(10240));
  { 100 * 1024 -> 100K }
  AssertEquals('100K', FormatFreeBytes(102400));
end;

procedure TFormatFreeBytesTest.TestMega;
begin
  { 1 * 1024^2 -> 1.0M }
  AssertEquals('1.0M', FormatFreeBytes(1048576));
end;

procedure TFormatFreeBytesTest.TestMegaFraction;
begin
  { 5 * 1024^2 -> 5.0M }
  AssertEquals('5.0M', FormatFreeBytes(5242880));
end;

procedure TFormatFreeBytesTest.TestMegaLarge;
begin
  { 512 * 1024^2 -> 512M }
  AssertEquals('512M', FormatFreeBytes(536870912));
end;

procedure TFormatFreeBytesTest.TestGiga;
begin
  { 1 * 1024^3 -> 1.0G }
  AssertEquals('1.0G', FormatFreeBytes(Int64(1073741824)));
end;

procedure TFormatFreeBytesTest.TestGigaFraction;
begin
  { 5 * 1024^3 -> 5.0G }
  AssertEquals('5.0G', FormatFreeBytes(Int64(5) * 1024 * 1024 * 1024));
end;

procedure TFormatFreeBytesTest.TestGigaLarge;
begin
  { 100 * 1024^3 -> 100G }
  AssertEquals('100G',
    FormatFreeBytes(Int64(100) * 1024 * 1024 * 1024));
end;

procedure TFormatFreeBytesTest.TestTera;
begin
  { 1 * 1024^4 -> 1.0T }
  AssertEquals('1.0T',
    FormatFreeBytes(Int64(1024) * 1024 * 1024 * 1024));
end;

procedure TFormatFreeBytesTest.TestTeraFraction;
begin
  { 1.5 * 1024^4 -> 1.5T }
  AssertEquals('1.5T',
    FormatFreeBytes(Int64(1536) * 1024 * 1024 * 1024));
end;

procedure TFormatFreeBytesTest.TestTeraLarge;
begin
  { 10 * 1024^4 -> 10T }
  AssertEquals('10T',
    FormatFreeBytes(Int64(10240) * 1024 * 1024 * 1024));
end;

procedure TFormatFreeBytesTest.TestTeraMax;
begin
  { Stays at T even for very large values }
  AssertEquals('100T',
    FormatFreeBytes(Int64(102400) * 1024 * 1024 * 1024));
end;

initialization
  RegisterTest(TFormatFreeBytesTest);

end.
