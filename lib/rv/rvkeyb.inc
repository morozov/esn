{ Translate FPC key event code to DOS BIOS word format.
  FPC TKeyEvent layout: bits 0-15 = key code,
  bits 24-31 = flags byte.
  GetKeyEventFlags returns the flags byte; kbFnKey=2 means
  function/nav key.
  On macOS/aarch64, FPC returns $FFxx codes for nav/F keys
  (not DOS $xxxx). }
function rKey: word;
var
  ke, rawKe: TKeyEvent;
  kcode: word;
  kflags: byte;
  rawFlags: byte;
  rawCode: word;
  ch: char;
  lastSec: word;
  h, m, s, ms: word;
  {$IFDEF ESN_KEY_DEBUG}
  dbgF: Text;
  {$ENDIF}
begin
  DecodeTime(Now, h, m, s, ms);
  lastSec := s;
  { Poll for key; invoke OnIdle callback once per second
    while waiting. }
  repeat
    ke := PollKeyEvent;
    if ke <> 0 then begin
      {$IFDEF ESN_KEY_DEBUG}
      rawKe := GetKeyEvent;
      Assign(dbgF, '/tmp/esn_keys.log');
      if FileExists('/tmp/esn_keys.log') then
        Append(dbgF)
      else
        Rewrite(dbgF);
      WriteLn(dbgF, Format(
        'PRE  kflags=$%02x kcode=$%04x char=$%02x',
        [GetKeyEventFlags(rawKe),
         GetKeyEventCode(rawKe),
         Ord(GetKeyEventChar(rawKe))]));
      ke := TranslateKeyEvent(rawKe);
      WriteLn(dbgF, Format(
        'POST kflags=$%02x kcode=$%04x char=$%02x'
        + ' keep=%d',
        [GetKeyEventFlags(ke), GetKeyEventCode(ke),
         Ord(GetKeyEventChar(ke)), Ord(ke <> 0)]));
      Close(dbgF);
      {$ELSE}
      rawKe := GetKeyEvent;
      ke := TranslateKeyEvent(rawKe);
      {$ENDIF}
      if ke <> 0 then break;
    end else begin
      Sleep(50);
      { Redraw clock on every poll so erasures are repaired
        within 50ms, matching the original interrupt-driven
        (18 Hz) behaviour. }
      DrawClock;
      DecodeTime(Now, h, m, s, ms);
      if s <> lastSec then begin
        lastSec := s;
        if Assigned(OnIdle) then OnIdle;
      end;
      if needResize then
      begin
        needResize := false;
        { DoneVideo/InitVideo forces FPC to re-read the
          terminal size via ioctl(TIOCGWINSZ) and reallocate
          VideoBuf.  SetVideoMode alone is a no-op on Unix
          and leaves ScreenWidth/ScreenHeight stale.
          DoneVideo restores the terminal from raw mode, so
          DoneKeyboard/InitKeyboard must bracket it to keep
          the keyboard in raw mode. }
        MouseOff;
        DoneKeyboard;
        DoneVideo;
        InitVideo;
        InitKeyboard;
        MouseOn;
        { InitVideo restores the terminal cursor to visible;
          hide it again so it does not appear as a white spot
          at (1,1) after Cls. }
        CurOff;
        {$IFDEF UNIX}
        { InitVideo may have reinstalled FPC's own SIGWINCH
          handler, replacing ours.  Reinstall so future
          resizes are detected. }
        fpSignal(SIGWINCH, @SigWinchHandler);
        {$ENDIF}
        { Drain any bytes that accumulated in stdin between
          DoneKeyboard and InitKeyboard (e.g. from DoneVideo
          escape sequences being echoed, or a pending
          SIGWINCH delivering bytes).  If consumed as a key
          event they would move the cursor spuriously. }
        while PollKeyEvent <> 0 do GetKeyEvent;
        GmaxX := ScreenWidth;
        GmaxY := ScreenHeight;
        HalfMaxX := GmaxX div 2;
        HalfMaxY := GmaxY div 2;
        if Assigned(OnResize) then OnResize;
        UpdateScreen(false);
      end;
    end;
  until false;

  kflags := GetKeyEventFlags(ke);
  kcode  := GetKeyEventCode(ke);
  rawFlags := GetKeyEventFlags(rawKe);
  rawCode  := GetKeyEventCode(rawKe);

  {$IFDEF ESN_KEY_DEBUG}
  Assign(dbgF, '/tmp/esn_keys.log');
  if FileExists('/tmp/esn_keys.log') then
    Append(dbgF)
  else
    Rewrite(dbgF);
  WriteLn(dbgF, Format('kflags=$%02x kcode=$%04x char=$%02x',
    [kflags, kcode, Ord(GetKeyEventChar(ke))]));
  Close(dbgF);
  {$ENDIF}

  { TranslateKeyEvent converts Shift/Ctrl/Alt+Fn into plain Fn
    events (kflags changes from 3 to kbFnKey, kcode becomes
    $FFxx), losing the modifier.  The raw kcode already matches
    our _ShFn/_CtrlFn/_AltFn constants, so use it directly.
    Ranges: ShF1..ShF10 $5400..$5D00, CtrlF1..CtrlF10
    $5E00..$6700, AltF1..AltF10 $6800..$7100,
    ShF11..ShF12 $8700..$8800, CtrlF11..AltF12
    $8900..$8C00. }
  if (rawFlags = 3) and (kflags = kbFnKey) and
     (((rawCode >= $5400) and (rawCode <= $7100)) or
      ((rawCode >= $8700) and (rawCode <= $8C00))) then
  begin
    rKey := rawCode;
    exit;
  end;

  if kflags = kbFnKey then begin
    { Navigation and F-keys: FPC uses $FFxx on this platform. }
    case kcode of
      { F1-F12 }
      $FF01: result := $3B00;   { F1  }
      $FF02: result := $3C00;   { F2  }
      $FF03: result := $3D00;   { F3  }
      $FF04: result := $3E00;   { F4  }
      $FF05: result := $3F00;   { F5  }
      $FF06: result := $4000;   { F6  }
      $FF07: result := $4100;   { F7  }
      $FF08: result := $4200;   { F8  }
      $FF09: result := $4300;   { F9  }
      $FF0A: result := $4400;   { F10 }
      $FF0B: result := $8500;   { F11 }
      $FF0C: result := $8600;   { F12 }
      { Navigation (plain) }
      $FF20: result := $47E0;   { Home  }
      $FF21: result := $48E0;   { Up    }
      $FF22: result := $49E0;   { PgUp  }
      $FF23: result := $4BE0;   { Left  }
      $FF25: result := $4DE0;   { Right }
      $FF26: result := $4FE0;   { End   }
      $FF27: result := $50E0;   { Down  }
      $FF28: result := $51E0;   { PgDn  }
      $FF29: result := $52E0;   { Ins   }
      $FF2A: result := $53E0;   { Del   }
      else   result := kcode;
    end;
  end else if kflags = 3 then begin
    { Alt+letters (kcode=$xx00 matching _AltX), bare Esc
      (kcode=0), Shift+Tab ($0F00), and Ctrl+navigation
      ($7300-$9300). }
    case kcode of
      $0000: result := $011B;   { Esc (bare) — fallback }
      $2400: result := $011B;   { Esc — macOS Terminal.app }
      $0F00: result := $0F00;   { Shift+Tab -> _ShTab }
      { Ctrl+navigation }
      $7300: result := $73E0;   { Ctrl+Left  }
      $7400: result := $74E0;   { Ctrl+Right }
      $7500: result := $75E0;   { Ctrl+End   }
      $7600: result := $76E0;   { Ctrl+PgDn  }
      $7700: result := $77E0;   { Ctrl+Home  }
      $8400: result := $84E0;   { Ctrl+PgUp  }
      $8D00: result := $8DE0;   { Ctrl+Up    }
      $9100: result := $91E0;   { Ctrl+Down  }
      $9200: result := $92E0;   { Ctrl+Ins   }
      $9300: result := $93E0;   { Ctrl+Del   }
      else   result := kcode;
    end;
  end else begin
    { ASCII key — add scan code in high byte. }
    ch := GetKeyEventChar(ke);
    case Ord(ch) of
      $1B:      result := $011B;  { Esc (ASCII path) }
      $0D:      result := $1C0D;  { Enter }
      $09:      result := $0F09;  { Tab }
      $08, $7F: result := $0E08;  { Backspace }
      $20:      result := $3920;  { Space }
      else begin
        if (Ord(ch) >= 1) and (Ord(ch) <= 26) then
          result := (word(ctrlScanTab[Ord(ch)]) shl 8)
                    or word(Ord(ch))
        else
          result := (word(charScan(ch)) shl 8)
                    or word(Ord(ch));
      end;
    end;
  end;
end;

procedure rPause;
begin
  UpdateScreen(false);
  rKey;
end;
