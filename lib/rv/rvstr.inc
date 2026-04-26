function StrR(n: int64): string;
var
  s: string;
begin
  Str(n, s);
  result := s;
end;

function ExtNum(const s: string): string;
var
  rev: string;
  i, grp: integer;
begin
  rev := '';
  grp := 0;
  for i := Length(s) downto 1 do begin
    rev := rev + s[i];
    Inc(grp);
    if (grp = 3) and (i > 1) then begin
      rev := rev + ' ';
      grp := 0;
    end;
  end;
  { Reverse rev to get the result }
  result := '';
  for i := Length(rev) downto 1 do
    result := result + rev[i];
  { Strip any leading space }
  while (Length(result) > 0) and (result[1] = ' ') do
    Delete(result, 1, 1);
end;

function ChangeChar(s: string; fromCh, toCh: char): string;
var
  i: integer;
begin
  for i := 1 to Length(s) do
    if s[i] = fromCh then
      s[i] := toCh;
  result := s;
end;

function LeftStr(const s: string; n: byte): string;
begin
  result := Copy(s, 1, n);
end;

function RightStr(const s: string; n: byte): string;
var
  len: integer;
begin
  len := Length(s);
  if n >= len then
    result := s
  else
    result := Copy(s, len - n + 1, n);
end;

function NoSpace(s: string): string;
var
  f: integer;
  a: string;
begin
  a := '';
  for f := 1 to Length(s) do
    if s[f] <> ' ' then a := a + s[f];
  NoSpace := a;
end;

function NoSpaceLR(s: string): string;
var
  l, r: integer;
begin
  l := 1;
  while (l <= Length(s)) and (s[l] = ' ') do Inc(l);
  r := Length(s);
  while (r >= l) and (s[r] = ' ') do Dec(r);
  NoSpaceLR := Copy(s, l, r - l + 1);
end;

{$push}{$notes off}
function Vall(tempein: string): longint;
var
  rrr: longint;
  code: integer;
begin
  Val(tempein, rrr, code);
  Vall := rrr;
end;
{$pop}

function Fill(len: integer; const symb: string): string;
begin
  Fill := DupeString(symb, len);
end;

function WithOut(s, chars: string): string;
var
  a, b, f: integer;
  st: string;
begin
  st := s;
  for f := 1 to Length(chars) do
    for b := 1 to Length(st) do begin
      a := Pos(chars[f], st);
      if a <> 0 then Delete(st, a, 1);
    end;
  WithOut := st;
end;

function CLen(s: string): integer;
begin
  CLen := Length(WithOut(s, '~'));
end;

Function LZ(w:Word):String;
var
   s:String;
Begin
Str(w:0,s); if Length(s)=1 then s:='0'+s; LZ:=s;
End;

function eFiles(n: longint): string;
begin
  if n = 1 then eFiles := '' else eFiles := 's';
end;

function ewFiles(n: longint): string;
begin
  if n = 1 then ewFiles := '' else ewFiles := 's';
end;

function ReverseStr(s: string): string;
var
  i: integer;
  a: string;
begin
  a := '';
  for i := Length(s) downto 1 do a := a + s[i];
  ReverseStr := a;
end;

function StrHi(s: string): string;
var
  f: integer;
begin
  for f := 1 to Length(s) do s[f] := UpCase(s[f]);
  StrHi := s;
end;

Function Wild(input_word,wilds:String;upcase_wish:boolean):Boolean;

 function search_next(var wilds:string):word;
 var position:word;
 begin
  position:=pos('*',wilds);
  if position<>0 then wilds:= copy(wilds,1,position-1);
  search_next:= position;
 end;

 function find_part(helpwilds,input_word:string):word;
 var q,q2:word;
     diff:integer;
 begin
  q:= pos('?',helpwilds);
  if q= 0 then begin find_part:= pos(helpwilds,input_word); exit; end;
  diff:= length(input_word)-length(helpwilds);
  if diff<0 then begin find_part:= 0;exit;end;
  for q:= 0 to diff do
   begin
    for q2:= 1 to length(helpwilds) do
     begin
      if (input_word[q+q2]= helpwilds[q2]) or (helpwilds[q2]= '?') then
       begin if q2= length(helpwilds) then begin find_part:= q+1;exit;end;end
        else break;
     end;
   end;
  find_part:= 0;
 end;

var cwild,cinput_word:word;
    q,lengthhelpwilds:word;
    maxinput_word,maxwilds:word;
    helpwilds:string;
begin
 wild:= false;
 repeat
  q:= pos('**',wilds);
  if q<>0 then wilds:= copy(wilds,1,q-1)+'*'+copy(wilds,q+2,255);
 until q= 0;
 for q:=1 to length(input_word) do if input_word[q]='*' then input_word[q]:='?';
 if wilds= '*' then begin wild:= true;exit;end;
 maxinput_word:= length(input_word);
 maxwilds     := length(wilds);
 if upcase_wish then
  begin
   for q:= 1 to maxinput_word do input_word[q]:= upcase(input_word[q]);
   for q:= 1 to maxwilds do wilds[q]:= upcase(wilds[q]);
  end;
 cinput_word:= 1;cwild:= 1;
 wild:= true;
 repeat
  if input_word[cinput_word]= wilds[cwild] then
   begin inc(cwild); inc(cinput_word); continue; end;
  if wilds[cwild]= '?' then
   begin inc(cwild); inc(cinput_word); continue; end;
  if wilds[cwild]= '*' then
   begin
    helpwilds:= copy(wilds,cwild+1,maxwilds);
    q:= search_next(helpwilds);
    lengthhelpwilds:= length(helpwilds);
    if q= 0 then
     begin
      if helpwilds= '' then exit;
      for q:= 0 to lengthhelpwilds-1 do
       if (helpwilds[lengthhelpwilds-q]<>input_word[maxinput_word-q]) and
          (helpwilds[lengthhelpwilds-q]<>'?') then
         begin wild:= false;exit;end;
      exit;
     end;
    inc(cwild,1+lengthhelpwilds);
    q:= find_part(helpwilds,copy(input_word,cinput_word,255));
    if q= 0 then begin wild:= false;exit;end;
    cinput_word:= q+lengthhelpwilds;
    continue;
   end;
  wild:= false;exit;
 until (cinput_word>maxinput_word) or (cwild>maxwilds);
 if cinput_word<= maxinput_word then wild:= false;
 if cwild<= maxwilds then wild:= false;
end;

{ DOS-style wildcard match: * matches any sequence, ? matches any char. }
function MatchMask(name, mask: string): boolean;
var
  ni, mi: integer;
begin
  ni := 1;
  mi := 1;
  while (mi <= Length(mask)) and (ni <= Length(name)) do begin
    if mask[mi] = '*' then begin
      { Skip consecutive stars }
      while (mi <= Length(mask)) and (mask[mi] = '*') do
        Inc(mi);
      if mi > Length(mask) then begin
        MatchMask := true;
        exit;
      end;
      { Try matching the rest of mask against each suffix of name }
      while ni <= Length(name) do begin
        if MatchMask(Copy(name, ni, MaxInt), Copy(mask, mi, MaxInt)) then begin
          MatchMask := true;
          exit;
        end;
        Inc(ni);
      end;
      MatchMask := false;
      exit;
    end else if (mask[mi] = '?') or
                (UpCase(mask[mi]) = UpCase(name[ni])) then begin
      Inc(mi);
      Inc(ni);
    end else begin
      MatchMask := false;
      exit;
    end;
  end;
  { Skip trailing stars in mask }
  while (mi <= Length(mask)) and (mask[mi] = '*') do
    Inc(mi);
  MatchMask := (mi > Length(mask)) and (ni > Length(name));
end;

function SPlural(n: longint): string;
begin
  if n = 1 then SPlural := '' else SPlural := 's';
end;

function sRexpand(s: string; tob: byte): string;
begin
if tob <= length(s) then begin sRexpand := s; exit; end;
sRexpand := s + Space(tob - length(s));
end;

function LeftPad(s: string; n: byte): string;
begin
  while Length(s) < n do
    s := ' ' + s;
  LeftPad := s;
end;

function RightPad(s: string; n: byte): string;
begin
  while Length(s) < n do
    s := s + ' ';
  RightPad := s;
end;

function ConsoleText(const s: string): string;
{$IFDEF WINDOWS}
var
  src, dst: AnsiString;
{$ENDIF}
begin
  {$IFDEF WINDOWS}
  src := AnsiString(s);
  if Length(src) = 0 then begin
    ConsoleText := s;
    exit;
  end;
  SetLength(dst, Length(src));
  CharToOemBuffA(PAnsiChar(src), PAnsiChar(dst), Length(src));
  ConsoleText := string(dst);
  {$ELSE}
  ConsoleText := s;
  {$ENDIF}
end;
