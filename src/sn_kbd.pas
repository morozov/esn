Unit SN_KBD;
{$mode objfpc}{$H+}

Interface

uses rv, vars;

Type
  TKbd = record
          sn_kb1_TAB,      sn_kb2_TAB,
          sn_kb1_EXIT,     sn_kb2_EXIT,
          sn_kb1_SETUP,    sn_kb2_SETUP,
          sn_kb1_CLEAN,    sn_kb2_CLEAN,
          sn_kb1_PACK,     sn_kb2_PACK,
          sn_kb1_HHAR,     sn_kb2_HHAR,
          sn_kb1_LIST,     sn_kb2_LIST,
          sn_kb1_HOBS,     sn_kb2_HOBS,
          sn_kb1_CHBACK,   sn_kb2_CHBACK,
          sn_kb1_CHFORW,   sn_kb2_CHFORW,
          sn_kb1_DESCRIP,  sn_kb2_DESCRIP,
          sn_kb1_ASCIITAB, sn_kb2_ASCIITAB,
          sn_kb1_JOIN,     sn_kb2_JOIN,
          sn_kb1_SAVEND,   sn_kb2_SAVEND,
          sn_kb1_FATTRS,   sn_kb2_FATTRS,
          sn_kb1_TRDOS3,   sn_kb2_TRDOS3,
          sn_kb1_ABOUT,    sn_kb2_ABOUT,
          sn_kb1_USERMENU, sn_kb2_USERMENU,
          sn_kb1_APACK,    sn_kb2_APACK,
          sn_kb1_AUNPACK,  sn_kb2_AUNPACK,
          sn_kb1_LPANEL,   sn_kb2_LPANEL,
          sn_kb1_RPANEL,   sn_kb2_RPANEL,
          sn_kb1_INSERT,   sn_kb2_INSERT,
          sn_kb1_SBYNAME,  sn_kb2_SBYNAME,
          sn_kb1_SBYEXT,   sn_kb2_SBYEXT,
          sn_kb1_SBYLEN,   sn_kb2_SBYLEN,
          sn_kb1_SBYNON,   sn_kb2_SBYNON,
          sn_kb1_VIDEO1,   sn_kb2_VIDEO1,
          sn_kb1_VIDEO2,   sn_kb2_VIDEO2,
          sn_kb1_LPONOFF,  sn_kb2_LPONOFF,
          sn_kb1_RPONOFF,  sn_kb2_RPONOFF,
          sn_kb1_NFPONOFF, sn_kb2_NFPONOFF,
          sn_kb1_BPONOFF,  sn_kb2_BPONOFF,
          sn_kb1_INFO,     sn_kb2_INFO,
          sn_kb1_REREAD,   sn_kb2_REREAD,
          sn_kb1_LFIND,    sn_kb2_LFIND,
          sn_kb1_GFIND,    sn_kb2_GFIND,
          sn_kb1_PCOLUMNS, sn_kb2_PCOLUMNS:   word;
         end;

Var
     kbd: Tkbd;

procedure LoadKBD;
procedure LoadDefaultKBD;

Implementation

Uses SysUtils;

procedure LoadKBD;
var
  fw: file of TKbd;
  s, path: string;
Begin
s := '';
GetProfile(IncludeTrailingPathDelimiter(StartDir) + 'sn.ini',
           'Interface', 'KeyboardFile', s);
if s = '' then exit;
path := IncludeTrailingPathDelimiter(StartDir) + 'KEYS' +
        PathDelim + s + '.kbd';
if not FileExists(path) then exit;
{$I-}
AssignFile(fw, path);
FileMode := 0;
Reset(fw);
if FileSize(fw) <> 1 then begin CloseFile(fw); exit; end;
Read(fw, kbd);
CloseFile(fw);
{$I+}
if IOResult <> 0 then;
End;

procedure LoadDefaultKBD;
begin
          kbd.sn_kb1_TAB:=_Tab;         kbd.sn_kb2_TAB:=_Tab;
          kbd.sn_kb1_EXIT:=_AltX;       kbd.sn_kb2_EXIT:=_F10;
          kbd.sn_kb1_SETUP:=_AltF9;     kbd.sn_kb2_SETUP:=_AltF9;
          kbd.sn_kb1_CLEAN:=_AltC;      kbd.sn_kb2_CLEAN:=_AltC;
          kbd.sn_kb1_PACK:=_AltP;       kbd.sn_kb2_PACK:=_AltP;
          kbd.sn_kb1_HHAR:=_AltR;       kbd.sn_kb2_HHAR:=_AltR;
          kbd.sn_kb1_LIST:=_AltL;       kbd.sn_kb2_LIST:=_AltL;
          kbd.sn_kb1_HOBS:=_AltH;       kbd.sn_kb2_HOBS:=_AltH;
          kbd.sn_kb1_CHBACK:=_CtrlE;    kbd.sn_kb2_CHBACK:=_CtrlE;
          kbd.sn_kb1_CHFORW:=_CtrlX;    kbd.sn_kb2_CHFORW:=_CtrlX;
          kbd.sn_kb1_DESCRIP:=_CtrlK;   kbd.sn_kb2_DESCRIP:=_CtrlK;
          kbd.sn_kb1_ASCIITAB:=_CtrlB;  kbd.sn_kb2_ASCIITAB:=_CtrlB;
          kbd.sn_kb1_JOIN:=_CtrlJ;      kbd.sn_kb2_JOIN:=_CtrlJ;
          kbd.sn_kb1_SAVEND:=_AltPlus;  kbd.sn_kb2_SAVEND:=_AltPlus;
          kbd.sn_kb1_FATTRS:=_AltF;     kbd.sn_kb2_FATTRS:=_AltF;
          kbd.sn_kb1_TRDOS3:=_AltT;     kbd.sn_kb2_TRDOS3:=_AltT;
          kbd.sn_kb1_ABOUT:=_F1;        kbd.sn_kb2_ABOUT:=_F1;
          kbd.sn_kb1_USERMENU:=_F2;     kbd.sn_kb2_USERMENU:=_F2;
          kbd.sn_kb1_APACK:=_ShF1;      kbd.sn_kb2_APACK:=_ShF1;
          kbd.sn_kb1_AUNPACK:=_ShF2;    kbd.sn_kb2_AUNPACK:=_ShF2;
          kbd.sn_kb1_LPANEL:=_AltF1;    kbd.sn_kb2_LPANEL:=_AltF1;
          kbd.sn_kb1_RPANEL:=_AltF2;    kbd.sn_kb2_RPANEL:=_AltF2;
          kbd.sn_kb1_INSERT:=_Ins;      kbd.sn_kb2_INSERT:=Pad0;
          kbd.sn_kb1_SBYNAME:=_CtrlF3;  kbd.sn_kb2_SBYNAME:=_CtrlF3;
          kbd.sn_kb1_SBYEXT:=_CtrlF4;   kbd.sn_kb2_SBYEXT:=_CtrlF4;
          kbd.sn_kb1_SBYLEN:=_CtrlF5;   kbd.sn_kb2_SBYLEN:=_CtrlF5;
          kbd.sn_kb1_SBYNON:=_CtrlF6;   kbd.sn_kb2_SBYNON:=_CtrlF6;
          kbd.sn_kb1_VIDEO1:=_AltF10;   kbd.sn_kb2_VIDEO1:=_AltF10;
          kbd.sn_kb1_VIDEO2:=_CtrlF10;  kbd.sn_kb2_VIDEO2:=_CtrlF10;
          kbd.sn_kb1_LPONOFF:=_CtrlF1;  kbd.sn_kb2_LPONOFF:=_CtrlF1;
          kbd.sn_kb1_RPONOFF:=_CtrlF2;  kbd.sn_kb2_RPONOFF:=_CtrlF2;
          kbd.sn_kb1_NFPONOFF:=_CtrlP;  kbd.sn_kb2_NFPONOFF:=_CtrlP;
          kbd.sn_kb1_BPONOFF:=_CtrlO;   kbd.sn_kb2_BPONOFF:=_CtrlO;
          kbd.sn_kb1_INFO:=_CtrlL;      kbd.sn_kb2_INFO:=_CtrlL;
          kbd.sn_kb1_REREAD:=_CtrlR;    kbd.sn_kb2_REREAD:=_CtrlR;
          kbd.sn_kb1_LFIND:=_AltS;      kbd.sn_kb2_LFIND:=_AltS;
          kbd.sn_kb1_GFIND:=_AltF7;     kbd.sn_kb2_GFIND:=_AltF7;
          kbd.sn_kb1_PCOLUMNS:=_CtrlV;  kbd.sn_kb2_PCOLUMNS:=_CtrlV;
end;

end.
