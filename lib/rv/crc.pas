unit crc;
{ CRC-16/CCITT — used by format parsers to persist file marks
  across reloads.  Ported from RV/CRC32C.PAS. }
{$mode objfpc}{$H+}

interface

function Crc16(const s: string): word;

implementation

function Crc16(const s: string): word;
var
  c: word;
  i, b: integer;
begin
  c := 0;
  for i := 1 to Length(s) do begin
    c := c xor (word(ord(s[i])) shl 8);
    for b := 1 to 8 do begin
      if (c and $8000) <> 0 then
        c := (c shl 1) xor $1021
      else
        c := c shl 1;
    end;
  end;
  Crc16 := c and $FFFF;
end;

end.
