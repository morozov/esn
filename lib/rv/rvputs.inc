procedure sPutWin(x1, y1, x2, y2: word);
var
  i: integer;
  sx2, sy2: word;
begin
  { Save region including the shadow area
    (2 cols right, 1 row below). }
  sx2 := x2 + 2;
  sy2 := y2 + 1;
  SaveRegion(x1, y1, sx2, sy2);
  DrawBox(TextAttr shr 4, TextAttr and $0F, x1, y1, x2, y2);
  { Right shadow — two columns }
  for i := y1 + 1 to y2 + 1 do
    PrintSelf(Black, DarkGray, x2 + 1, i, 2);
  { Bottom shadow }
  PrintSelf(Black, DarkGray, x1 + 2, y2 + 1, x2 - x1 + 1);
  UpdateScreen(false);
end;

procedure scPutWin(paper, ink: byte; x1, y1, x2, y2: word);
var
  i: integer;
  sx2, sy2: word;
begin
  sx2 := x2 + 2;
  sy2 := y2 + 1;
  SaveRegion(x1, y1, sx2, sy2);
  DrawBox(paper, ink, x1, y1, x2, y2);
  for i := y1 + 1 to y2 + 1 do
    PrintSelf(Black, DarkGray, x2 + 1, i, 2);
  PrintSelf(Black, DarkGray, x1 + 2, y2 + 1, x2 - x1 + 1);
  UpdateScreen(false);
end;

procedure RestScr;
var
  row, col: integer;
  k, ofs: longword;
  x1, y1, x2, y2: word;
begin
  if winTop = 0 then
    exit;
  x1 := winStack[winTop].x1;
  y1 := winStack[winTop].y1;
  x2 := winStack[winTop].x2;
  y2 := winStack[winTop].y2;
  k := 0;
  for row := y1 - 1 to y2 - 1 do
    for col := x1 - 1 to x2 - 1 do begin
      ofs := longword(row) * ScreenWidth + longword(col);
      if ofs < longword(ScreenWidth) * ScreenHeight then
        EnhancedVideoBuf[ofs] := winStack[winTop].buf[k];
      Inc(k);
    end;
  SetLength(winStack[winTop].buf, 0);
  Dec(winTop);
  UpdateScreen(false);
  DrawClock;
end;

procedure FlushWinStack;
begin
  while winTop > 0 do begin
    SetLength(winStack[winTop].buf, 0);
    Dec(winTop);
  end;
end;

{ ===== Dialog helpers ===== }

procedure cmCentre(paper, ink: byte; y: word; const s: string);
var
  x: integer;
begin
  x := 1 + (HalfMaxX - (Length(s) div 2));
  CMPrint(paper, ink, x, y, s);
end;

{ Format: alternating color segments separated by ~` toggle
  markers.  focus=1 -> start in normal color; focus<>1 -> start
  in selected color. }
procedure cStatusBar(bkNT, txtNT, bkST, txtST, focus: byte;
  const s: string);
var
  f, x: integer;
  norm: boolean;
begin
  { Leading space color depends on focus;
    text always starts normal. }
  if focus = 1 then
    CMPrint(bkNT, txtNT, 1, GmaxY, ' ')
  else
    CMPrint(bkST, txtST, 1, GmaxY, ' ');
  norm := true;
  f := 1;
  x := 2;
  while f <= Length(s) do begin
    if x > GmaxX then
      break;
    { Detect ~` toggle marker (both chars consumed, no output) }
    if (s[f] = '~') and (f < Length(s)) and
       (s[f + 1] = '`') then begin
      norm := not norm;
      Inc(f, 2);
      continue;
    end;
    { Backtick alone is a no-op separator }
    if s[f] = '`' then begin
      Inc(f);
      continue;
    end;
    if norm then
      CMPrint(bkNT, txtNT, x, GmaxY, s[f])
    else
      CMPrint(bkST, txtST, x, GmaxY, s[f]);
    Inc(x);
    Inc(f);
  end;
  if x <= GmaxX then
    CMPrint(bkNT, txtNT, x, GmaxY, Space(GmaxX - x + 1));
  UpdateScreen(false);
end;

procedure cButton(bkA, txtA, bkSh, txtSh: byte; x, y: word;
  const s: string; active: boolean);
var
  t: string;
begin
  t := s;
  if active then begin
    t[1] := #16;   { ► }
    t[Length(t)] := #17;  { ◄ }
  end;
  CMPrint(bkA, txtA, x, y, t);
  { Shadow: one cell right, one cell below }
  CMPrint(bkSh, txtSh, x + Length(t), y, #220);  { ▄ }
  CMPrint(bkSh, txtSh, x + 1, y + 1,
    StringOfChar(#223, Length(t)));  { ▀ }
end;

{ ===== CCLen ===== }

{ Display width (terminal cells) of a `~`-marker UTF-8 string,
  ignoring the `~` and `` ` `` markers themselves. Strips markers
  first, then defers to StringDisplayWidth so that surrogate pairs,
  combining marks, and emoji ZWJ sequences count as one cluster. }
function CCLen(const s: string): integer;
var
  i: integer;
  us, stripped: UnicodeString;
  raw: RawByteString;
begin
  raw := s;
  SetCodePage(raw, CP_UTF8, false);
  us := UnicodeString(raw);
  stripped := '';
  i := 1;
  while i <= Length(us) do begin
    if (us[i] = '~') and (i < Length(us)) and
       (us[i + 1] = '`') then
      Inc(i, 2)
    else if us[i] = '`' then
      Inc(i)
    else begin
      stripped := stripped + us[i];
      Inc(i);
    end;
  end;
  CCLen := StringDisplayWidth(stripped);
end;

{ ===== StatusLineColor ===== }

procedure StatusLineColor(paper, ink, papermark, inkmark,
  x, y: integer; const s: string);
var
  i, cw: integer;
  us: UnicodeString;
  raw: RawByteString;
  active: boolean;
begin
  raw := s;
  SetCodePage(raw, CP_UTF8, false);
  us := UnicodeString(raw);
  active := true;
  i := 1;
  while i <= Length(us) do begin
    if (us[i] = '~') and (i < Length(us)) and
       (us[i + 1] = '`') then begin
      active := not active;
      Inc(i, 2);
    end else if us[i] = '`' then begin
      Inc(i);
    end else begin
      cw := ExtendedGraphemeClusterDisplayWidth(us[i]);
      if cw <= 0 then cw := 1;
      if active then
        CMPrintU(paper, ink, x, y, UTF8Encode(UnicodeString(us[i])))
      else
        CMPrintU(papermark, inkmark, x, y,
                 UTF8Encode(UnicodeString(us[i])));
      Inc(x, cw);
      Inc(i);
    end;
  end;
end;

{ ===== CStatusLineColor ===== }

{ Print s centered on row y within the standard dialog width
  (40 chars), filling the interior columns with the given colors.
  txt2 unused. }
procedure CStatusLineColor(bk, txt1, txt2: byte; y: word;
  const s: string);
var
  x, w: word;
  line: string;
begin
  { Suppress unused param warning }
  if txt2 = 0 then ;
  w := 38;
  line := s;
  while Length(line) < w do line := ' ' + line + ' ';
  if Length(line) > w then
    line := Copy(line, 1, w);
  x := HalfMaxX - (w div 2) + 1;
  CMPrint(bk, txt1, x, y, line);
  UpdateScreen(false);
end;

{ ===== scanf — single-line text input ===== }

function scanf(x, y: word; const def: string;
  maxLen, visLen, startPos: byte): string;
var
  s: string;
  pos_: byte;  { cursor position in s, 1-based }
  k: word;
  ch: char;
  dispFrom: byte;  { first char of s visible at column x }

  procedure Redraw;
  var
    vis: string;
    coff: word;
  begin
    if pos_ > dispFrom + visLen - 1 then
      dispFrom := pos_ - visLen + 1;
    if (dispFrom > 1) and (pos_ < dispFrom) then
      dispFrom := pos_;
    vis := Copy(s, dispFrom, visLen);
    while Length(vis) < visLen do
      vis := vis + ' ';
    CMPrint(TextAttr shr 4, TextAttr and $0F, x, y, vis);
    coff := x + pos_ - dispFrom;
    GotoXY(coff, y);
    UpdateScreen(false);
  end;

begin
  s := def;
  if startPos > Length(s) + 1 then
    pos_ := Length(s) + 1
  else if startPos < 1 then
    pos_ := 1
  else
    pos_ := startPos;
  dispFrom := 1;
  scanf_esc    := false;
  scanf_tab    := false;
  scanf_shtab  := false;
  CurOn;
  Redraw;
  repeat
    k := rKey;
    case k of
      _Esc: begin
        scanf_esc := true;
        break;
      end;
      _Enter, PadEnter: break;
      _Tab: begin
        scanf_tab := true;
        break;
      end;
      _ShTab: begin
        scanf_shtab := true;
        break;
      end;
      _Left, Pad4: begin
        if pos_ > 1 then Dec(pos_);
      end;
      _Right, Pad6: begin
        if pos_ <= Length(s) then Inc(pos_);
      end;
      _Home: begin
        pos_ := 1;
        dispFrom := 1;
      end;
      _End: begin
        pos_ := Length(s) + 1;
      end;
      _BkSp: begin
        if (pos_ > 1) and (Length(s) > 0) then begin
          Delete(s, pos_ - 1, 1);
          Dec(pos_);
          if dispFrom > 1 then Dec(dispFrom);
        end;
      end;
      _Del: begin
        if pos_ <= Length(s) then
          Delete(s, pos_, 1);
      end;
    else
      ch := Chr(Lo(k));
      if (ch >= ' ') and (Length(s) < maxLen) then begin
        Insert(ch, s, pos_);
        Inc(pos_);
      end;
    end;
    Redraw;
  until false;
  CurOff;
  scanf := s;
end;

{ ===== ChooseItem popup menu ===== }

function ChooseItem: byte;
var
  f, inttemp, fr, visibleCount: integer;
  i: integer;
  px, py: integer;
  k: word;

  procedure PutItems;
  var
    fi, row, v: integer;
    bkN, txN, bkS, txS: byte;
  begin
    if menu_visible > menu_Total then v := menu_Total
    else v := fr + menu_visible - 1;
    row := 1;
    for fi := fr to v do begin
      if fi = menu_f then begin
        bkN := menu_bkMarkNT; txN := menu_txtMarkNT;
        bkS := menu_bkMarkST; txS := menu_txtMarkST;
      end else begin
        bkN := menu_bkNT; txN := menu_txtNT;
        bkS := menu_bkST; txS := menu_txtST;
      end;
      if menu_title = '' then
        StatusLineColor(bkN, txN, bkS, txS,
          px + 2, py + row, '  ' + menu_Name[fi] + '  ')
      else
        StatusLineColor(bkN, txN, bkS, txS,
          px + 2, py + row + 2,
          '  ' + menu_Name[fi] + '  ');
      Inc(row);
    end;
  end;

begin
  { Apply color defaults }
  if menu_bkNT    < 0 then menu_bkNT    := LightGray;
  if menu_txtNT   < 0 then menu_txtNT   := Black;
  if menu_bkST    < 0 then menu_bkST    := LightGray;
  if menu_txtST   < 0 then menu_txtST   := White;
  if menu_bkMarkNT < 0 then menu_bkMarkNT := Blue;
  if menu_txtMarkNT < 0 then
    menu_txtMarkNT := LightCyan;
  if menu_bkMarkST < 0 then menu_bkMarkST := Blue;
  if menu_txtMarkST < 0 then
    menu_txtMarkST := White;

  { Clamp menu_visible }
  if menu_visible = 255 then
    menu_visible := GmaxY div 3;
  if menu_visible > menu_Total then
    menu_visible := menu_Total;
  if (menu_visible <= 0) or
     (menu_visible > GmaxY - 9) then
    menu_visible := GmaxY - 9;
  if (menu_f < 1) or (menu_f > menu_Total) then
    menu_f := 1;

  { Compute max item width }
  inttemp := CCLen(menu_Name[1]);
  for f := 2 to menu_Total do
    if CCLen(menu_Name[f]) > inttemp then
      inttemp := CCLen(menu_Name[f]);
  if CCLen(menu_title) > inttemp then
    inttemp := CCLen(menu_title);
  if inttemp > 65 then inttemp := 65;

  { Pad item names to equal width }
  for f := 1 to menu_Total do begin
    i := inttemp - CCLen(menu_Name[f]);
    while i > 0 do begin
      menu_Name[f] := menu_Name[f] + ' ';
      Dec(i);
    end;
  end;

  { Auto-position window }
  if menu_posx = 255 then
    menu_posx := HalfMaxX - (6 + inttemp) div 2;
  if menu_visible > menu_Total then
    visibleCount := menu_Total
  else visibleCount := menu_visible;
  if menu_posy = 255 then
    menu_posy := HalfMaxY - visibleCount div 2 - 2;
  px := menu_posx; py := menu_posy;

  { Draw window }
  if menu_title = '' then
    scPutWin(menu_bkNT, menu_txtNT,
      px, py, px + inttemp + 7, py + visibleCount + 1)
  else begin
    scPutWin(menu_bkNT, menu_txtNT,
      px, py, px + inttemp + 7,
      py + visibleCount + 3);
    if w_twosided then
      CMPrint(menu_bkNT, menu_txtNT, px, py + 2,
        Chr(199) + StringOfChar(#196, inttemp + 6)
        + Chr(182))
    else
      CMPrint(menu_bkNT, menu_txtNT, px, py + 2,
        ' ' + Chr(195)
        + StringOfChar(#196, inttemp + 4)
        + Chr(180) + ' ');
    CMPrint(menu_bkNT, menu_txtNT,
      px + (inttemp + 8) div 2
      - CCLen(menu_title) div 2,
      py + 1, menu_title);
  end;

  fr := menu_f - menu_visible + 1;
  if fr < 1 then fr := 1;

  repeat
    PutItems;
    UpdateScreen(false);
    k := rKey;
    case k of
      _Enter: begin
        RestScr;
        ChooseItem := menu_f;
        menu_posx := 255; menu_posy := 255;
        exit;
      end;
      _Esc: begin
        scanf_esc := true;
        RestScr;
        ChooseItem := 0;
        menu_posx := 255; menu_posy := 255;
        exit;
      end;
      _Tab: begin
        scanf_tab := true;
        RestScr;
        ChooseItem := menu_f;
        menu_posx := 255; menu_posy := 255;
        exit;
      end;
      _Down: begin
        Inc(menu_f);
        if menu_f > fr + menu_visible - 1 then begin
          Inc(fr);
          if fr > menu_Total - menu_visible + 1 then
            Dec(fr);
        end;
      end;
      _Up: begin
        Dec(menu_f);
        if menu_f < fr then begin
          Dec(fr);
          if fr < 1 then Inc(fr);
        end;
      end;
      _PgDn: begin
        Inc(menu_f, menu_visible);
        if menu_f > fr + menu_visible - 1 then begin
          Inc(fr, menu_visible);
          if fr > menu_Total - menu_visible + 1 then
            fr := menu_Total - menu_visible + 1;
        end;
        if menu_f > menu_Total then
          menu_f := menu_Total;
      end;
      _PgUp: begin
        Dec(menu_f, menu_visible);
        if menu_f < fr then begin
          Dec(fr, menu_visible);
          if fr < 1 then fr := 1;
        end;
        if menu_f < 1 then menu_f := 1;
      end;
      _Home: begin fr := 1; menu_f := 1; end;
      _End:  begin
        fr := menu_Total - menu_visible + 1;
        if fr < 1 then fr := 1;
        menu_f := menu_Total;
      end;
    end;
    if menu_f > menu_Total then menu_f := 1;
    if menu_f < 1 then menu_f := menu_Total;
  until false;
end;

{ Clip a `~`-marker-tagged string to pw display cells.  The
  `~`+`` ` `` toggles and lone `` ` `` are zero-width and pass
  through; visible content is iterated by grapheme cluster and
  truncated on a cluster boundary. }
function ClipToCells(const s: UnicodeString; pw: integer): UnicodeString;
var
  i, acc, cw: integer;
  egc, chunk: UnicodeString;
  done: boolean;
begin
  if pw <= 0 then begin Result := ''; exit; end;
  Result := '';
  acc := 0;
  i := 1;
  done := false;
  while (i <= Length(s)) and (not done) do
  begin
    if (s[i] = '~') and (i < Length(s)) and (s[i+1] = '`') then
    begin
      Result := Result + '~`';
      Inc(i, 2);
    end
    else if s[i] = '`' then
    begin
      Result := Result + '`';
      Inc(i);
    end
    else
    begin
      chunk := '';
      while i <= Length(s) do
      begin
        if (s[i] = '~') and (i < Length(s)) and (s[i+1] = '`') then break;
        if s[i] = '`' then break;
        chunk := chunk + s[i];
        Inc(i);
      end;
      for egc in
        TUnicodeStringExtendedGraphemeClustersEnumerator.Create(chunk) do
      begin
        cw := ExtendedGraphemeClusterDisplayWidth(egc);
        if acc + cw > pw then begin done := true; break; end;
        Result := Result + egc;
        Inc(acc, cw);
      end;
    end;
  end;
end;

procedure InfoLine(bkNT,txtNT,bkST,txtST:byte;
                   x:word; y:integer; s0:string;
                   pw:integer);
var s:string; leadW:integer;
begin
  leadW:=(pw-CCLen(s0)) div 2;
  if leadW<0 then leadW:=0;
  s:=space(leadW)+s0;
  while CClen(s)<pw do s:=s+' ';
  if CClen(s)>pw then s:=ClipToCells(s,pw);
  StatusLineColor(bkNT,txtNT,bkST,txtST,x,y,s);
end;

{============================================================================}
procedure ProcessBar(act,per,total:byte; title:string);
const run=1;
var
   cm,ops:integer;
   x1,x2,dx:word;
begin
dx:=4;
cm:=halfmaxy;
x1:=halfmaxx-round(total/2)-dx;
Colour(Blue,White);
if act=run then
 begin
  x2:=halfmaxx+round(total/2)+dx;
  sPutWin(x1,cm-3,x2,cm);
  cmprint(Blue,White,x1+5,cm-2,title);
  cmprint(Blue,White,x1+5,cm-1,StringOfChar(#177,total));
 end;
ops:=round((total/100)*per);
mprint(x1+4+ops,cm-1,#$DB);
UpdateScreen(false);
end;
