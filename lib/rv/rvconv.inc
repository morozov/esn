{$push}{$notes off}
function Dec2Hex(decn: string): string;
var hex: string; i,f,h3,h4: word; tdec,valcode: longint;
    decm: array[1..2] of real;
label fin;
begin
 hex := ''; Val(decn, tdec, valcode);
 if (tdec < 0) or (tdec > 65535) then
   begin hex := 'error'; goto fin; end;
 decm[1] := Int(tdec / 256);
 decm[2] := tdec - 256 * decm[1];
 for i := 1 to 2 do
  begin
   h3 := 48; h4 := 48;
   for f := 1 to Round(decm[i]) do
    begin
     h4 := h4 + 1;
     if (h4 > 57) and (h4 < 65) then h4 := h4 + 7;
     if h4 > 70 then begin h3 := h3 + 1; h4 := 48; end;
     if (h3 > 57) and (h3 < 65) then h3 := h3 + 7;
    end;
   hex := hex + Chr(h3) + Chr(h4);
  end;
fin:
 if Vall(decn) > 255 then Dec2Hex := hex
 else Dec2Hex := Copy(hex, 3, 2);
end;
{$pop}
