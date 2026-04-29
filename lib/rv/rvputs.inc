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

procedure cmCentre(paper, ink: byte; y: word; const s: UnicodeString);
var
  x: integer;
begin
  x := 1 + (HalfMaxX - (StringDisplayWidth(s) div 2));
  CMPrint(paper, ink, x, y, s);
end;

{ Format: alternating color segments separated by ~` toggle
  markers.  focus=1 -> start in normal color; focus<>1 -> start
  in selected color. }
procedure cStatusBar(bkNT, txtNT, bkST, txtST, focus: byte;
  const s: UnicodeString);
var
  f, x: integer;
  norm: boolean;
  segment: UnicodeString;

  procedure FlushSegment;
  var
    cw: integer;
  begin
    if (segment = '') or (x > GmaxX) then begin
      segment := '';
      exit;
    end;
    cw := StringDisplayWidth(segment);
    if norm then
      CMPrint(bkNT, txtNT, x, GmaxY, segment)
    else
      CMPrint(bkST, txtST, x, GmaxY, segment);
    Inc(x, cw);
    segment := '';
  end;

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
  segment := '';
  while f <= Length(s) do begin
    { Detect ~` toggle marker (both chars consumed, no output) }
    if (s[f] = '~') and (f < Length(s)) and
       (s[f + 1] = '`') then begin
      FlushSegment;
      norm := not norm;
      Inc(f, 2);
      continue;
    end;
    { Backtick alone is a no-op separator }
    if s[f] = '`' then begin
      Inc(f);
      continue;
    end;
    segment := segment + s[f];
    Inc(f);
  end;
  FlushSegment;
  if x <= GmaxX then
    CMPrint(bkNT, txtNT, x, GmaxY, Fill(GmaxX - x + 1, ' '));
  UpdateScreen(false);
end;

procedure cButton(bkA, txtA, bkSh, txtSh: byte; x, y: word;
  const s: UnicodeString; active: boolean);
var
  t, egc, middle: UnicodeString;
  i, clusters, w: integer;
begin
  t := s;
  if active then begin
    { Active style overwrites the first and last grapheme clusters
      with '►' and '◄'.  The caller therefore needs to supply a
      sacrificial cluster at each end (typically a space) for the
      arrows to consume; the inner content is preserved verbatim.
      Cluster-aware so a surrogate pair or combining sequence at an
      end is not split. }
    clusters := 0;
    for egc in
      TUnicodeStringExtendedGraphemeClustersEnumerator.Create(t) do
      Inc(clusters);
    if clusters >= 2 then begin
      middle := '';
      i := 0;
      for egc in
        TUnicodeStringExtendedGraphemeClustersEnumerator.Create(t) do
      begin
        Inc(i);
        if (i > 1) and (i < clusters) then
          middle := middle + egc;
      end;
      t := '►' + middle + '◄';
    end else
      { 0 or 1 clusters: wrap whatever is there with both markers
        so the button still reads as active. }
      t := '►' + t + '◄';
  end;
  w := StringDisplayWidth(t);
  CMPrint(bkA, txtA, x, y, t);
  { Shadow: one cell right, one cell below }
  CMPrint(bkSh, txtSh, x + word(w), y, '▄');
  CMPrint(bkSh, txtSh, x + 1, y + 1, Fill(w, '▀'));
end;

{ ===== CCLen ===== }

{ Display width (terminal cells) of a `~`-marker string, ignoring
  the `~` and `` ` `` markers themselves. Strips markers first,
  then defers to StringDisplayWidth so that surrogate pairs,
  combining marks, and emoji ZWJ sequences count as one cluster. }
function CCLen(const s: UnicodeString): integer;
var
  i: integer;
  stripped: UnicodeString;
begin
  stripped := '';
  i := 1;
  while i <= Length(s) do begin
    if (s[i] = '~') and (i < Length(s)) and
       (s[i + 1] = '`') then
      Inc(i, 2)
    else if s[i] = '`' then
      Inc(i)
    else begin
      stripped := stripped + s[i];
      Inc(i);
    end;
  end;
  CCLen := StringDisplayWidth(stripped);
end;

{ ===== StatusLineColor ===== }

procedure StatusLineColor(paper, ink, papermark, inkmark,
  x, y: integer; const s: UnicodeString);
var
  i: integer;
  active: boolean;
  segment: UnicodeString;

  procedure FlushSegment;
  begin
    if segment = '' then exit;
    if active then
      CMPrint(paper, ink, x, y, segment)
    else
      CMPrint(papermark, inkmark, x, y, segment);
    Inc(x, StringDisplayWidth(segment));
    segment := '';
  end;

begin
  active := true;
  i := 1;
  segment := '';
  while i <= Length(s) do begin
    if (s[i] = '~') and (i < Length(s)) and
       (s[i + 1] = '`') then begin
      FlushSegment;
      active := not active;
      Inc(i, 2);
    end else if s[i] = '`' then begin
      Inc(i);
    end else begin
      segment := segment + s[i];
      Inc(i);
    end;
  end;
  FlushSegment;
end;

{ ===== CStatusLineColor ===== }

{ Print s centered on row y within the standard dialog width
  (40 chars), filling the interior columns with the given colors.
  txt2 unused. }
procedure CStatusLineColor(bk, txt1, txt2: byte; y: word;
  const s: UnicodeString);
var
  x, w: word;
  line, fit, egc: UnicodeString;
  fitW, cw: integer;
begin
  { Suppress unused param warning }
  if txt2 = 0 then ;
  w := 38;
  line := s;
  while StringDisplayWidth(line) < w do line := ' ' + line + ' ';
  if StringDisplayWidth(line) > w then
  begin
    fitW := 0; fit := '';
    for egc in
      TUnicodeStringExtendedGraphemeClustersEnumerator.Create(line) do
    begin
      cw := ExtendedGraphemeClusterDisplayWidth(egc);
      if fitW + cw > w then break;
      fit := fit + egc;
      Inc(fitW, cw);
    end;
    line := fit;
  end;
  x := HalfMaxX - (w div 2) + 1;
  CMPrint(bk, txt1, x, y, line);
  UpdateScreen(false);
end;

{ ===== scanf — single-line text input =====

  The buffer is kept as UnicodeString and edited in grapheme clusters
  so that multi-byte UTF-8 characters (Cyrillic, accented Latin, CJK,
  emoji) behave as single editable units.  pos_ and dispFrom are
  cluster indices; visLen is interpreted as terminal display cells
  and maxLen as a UTF-8 byte cap on the returned string.  The result
  is encoded back to UTF-8 for the AnsiString return type. }

function scanf(x, y: word; const def: string;
  maxLen, visLen, startPos: byte): string;
var
  s: UnicodeString;
  clusters: array of UnicodeString;
  widths: array of integer;
  byteLen: integer;
  pos_: integer;
  dispFrom: integer;
  k: word;
  ch: char;

  procedure Recompute;
  var
    egc: UnicodeString;
    n: integer;
  begin
    SetLength(clusters, 0);
    SetLength(widths, 0);
    n := 0;
    for egc in
      TUnicodeStringExtendedGraphemeClustersEnumerator.Create(s) do
    begin
      Inc(n);
      SetLength(clusters, n);
      SetLength(widths, n);
      clusters[n - 1] := egc;
      widths[n - 1] := ExtendedGraphemeClusterDisplayWidth(egc);
    end;
    byteLen := Length(UTF8Encode(s));
  end;

  function CodeUnitOffset(n: integer): integer;
  var
    i: integer;
  begin
    Result := 1;
    for i := 1 to n - 1 do
      Inc(Result, Length(clusters[i - 1]));
  end;

  function CellsBetween(a, b: integer): integer;
  var
    i, last: integer;
  begin
    Result := 0;
    last := b - 1;
    if last > Length(clusters) then last := Length(clusters);
    for i := a to last do
      Inc(Result, widths[i - 1]);
  end;

  procedure Redraw;
  var
    i, cells, cellsToCursor: integer;
    vis: UnicodeString;
  begin
    if pos_ < dispFrom then dispFrom := pos_;
    while CellsBetween(dispFrom, pos_) > visLen do
      Inc(dispFrom);

    vis := '';
    cells := 0;
    cellsToCursor := -1;
    i := dispFrom;
    while i <= Length(clusters) do
    begin
      if i = pos_ then cellsToCursor := cells;
      if cells + widths[i - 1] > visLen then break;
      vis := vis + clusters[i - 1];
      Inc(cells, widths[i - 1]);
      Inc(i);
    end;
    if cellsToCursor < 0 then cellsToCursor := cells;
    while cells < visLen do
    begin
      vis := vis + ' ';
      Inc(cells);
    end;

    CMPrint(TextAttr shr 4, TextAttr and $0F, x, y, vis);
    if cellsToCursor > visLen then cellsToCursor := visLen;
    GotoXY(x + word(cellsToCursor), y);
    UpdateScreen(false);
  end;

begin
  s := UTF8Decode(def);
  Recompute;
  if startPos > Length(clusters) + 1 then
    pos_ := Length(clusters) + 1
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
      _Enter, PadEnter, _Up, _Down: break;
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
        if pos_ <= Length(clusters) then Inc(pos_);
      end;
      _Home: begin
        pos_ := 1;
        dispFrom := 1;
      end;
      _End: begin
        pos_ := Length(clusters) + 1;
      end;
      _BkSp: begin
        if (pos_ > 1) and (Length(clusters) > 0) then begin
          Delete(s, CodeUnitOffset(pos_ - 1),
            Length(clusters[pos_ - 2]));
          Dec(pos_);
          if dispFrom > 1 then Dec(dispFrom);
          Recompute;
        end;
      end;
      _Del: begin
        if pos_ <= Length(clusters) then begin
          Delete(s, CodeUnitOffset(pos_),
            Length(clusters[pos_ - 1]));
          Recompute;
        end;
      end;
    else
      ch := Chr(Lo(k));
      { rKey reports nav keys not handled above (Up, Down, PgUp,
        PgDn, …) with low byte $E0; reject so they are not inserted
        as a stray byte. }
      if (ch >= ' ') and (Lo(k) <> $E0)
         and (byteLen < maxLen) then begin
        Insert(UnicodeString(ch), s, CodeUnitOffset(pos_));
        Inc(pos_);
        Recompute;
      end;
    end;
    Redraw;
  until false;
  CurOff;
  scanf := UTF8Encode(s);
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
        '╟' + Fill(inttemp + 6, '─') + '╢')
    else
      CMPrint(menu_bkNT, menu_txtNT, px, py + 2,
        ' ├' + Fill(inttemp + 4, '─') + '┤ ');
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
                   x:word; y:integer; s0:UnicodeString;
                   pw:integer);
var s:UnicodeString; leadW:integer;
begin
  leadW:=(pw-CCLen(s0)) div 2;
  if leadW<0 then leadW:=0;
  s:=Fill(leadW,' ')+s0;
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
  cmprint(Blue,White,x1+5,cm-1,DupeString('▒',total));
 end;
ops:=round((total/100)*per);
mprint(x1+4+ops,cm-1,'█');
UpdateScreen(false);
end;
