function CurentDir: string;
begin
  CurentDir := GetCurrentDir;
end;

{ Returns 0 if path is an existing directory, 2 otherwise. }
function CheckDir(path: string): byte;
begin
  if DirectoryExists(path) then
    CheckDir := 0
  else
    CheckDir := 2;
end;

{ Returns 0 if path exists (file or directory), 2 otherwise. }
function CheckDirFile(path: string): byte;
begin
  if FileExists(path) or DirectoryExists(path) then
    CheckDirFile := 0
  else
    CheckDirFile := 2;
end;

{ Creates a full directory path (all intermediate directories).
  Shadows SysUtils.CreateDir intentionally — this version
  accepts deep paths. }
function CreateDir(path: string): boolean;
begin
  CreateDir := ForceDirectories(path);
end;

{ Returns file size in bytes, or -1 if file does not exist. }
function FileLen(path: string): int64;
var
  sr: TSearchRec;
begin
  if FindFirst(path, faAnyFile, sr) = 0 then begin
    FileLen := sr.Size;
    FindClose(sr);
  end else
    FileLen := -1;
end;

function GetOf(fullpath: string; what: byte): string;
var
  dir, base, ext: string;
begin
  dir  := ExtractFilePath(fullpath);
  base := ExtractFileName(fullpath);
  ext  := ExtractFileExt(fullpath);
  { Strip leading dot from extension }
  if (Length(ext) > 0) and (ext[1] = '.') then
    Delete(ext, 1, 1);
  { Strip name extension to get bare name }
  if Length(ext) > 0 then
    base := Copy(base, 1, Length(base) - Length(ext) - 1);
  { Strip trailing separator from dir }
  if (Length(dir) > 0) and
     (dir[Length(dir)] = PathDelim) and
     (Length(dir) > 1) then
    Delete(dir, Length(dir), 1);
  case what of
    _dir  : GetOf := dir;
    _name : GetOf := base;
    _ext  : GetOf := ext;
  else
    GetOf := '';
  end;
end;

{ ===== INI file helpers ===== }

{ Reads value for key in section from inifile.
  value is unchanged if not found. }
procedure GetProfile(inifile, section, key: string;
  var value: string);
var
  f: TextFile;
  line, curSection, k, v: string;
  inSection: boolean;
  eqPos: integer;
begin
  if not FileExists(inifile) then
    exit;
  AssignFile(f, inifile);
  try
    Reset(f);
    try
      inSection := false;
      while not EOF(f) do begin
        ReadLn(f, line);
        line := Trim(line);
        if (Length(line) >= 2) and
           (line[1] = '[') and
           (line[Length(line)] = ']') then begin
          curSection := Copy(line, 2, Length(line) - 2);
          inSection  := SameText(curSection, section);
        end else if inSection then begin
          eqPos := Pos('=', line);
          if eqPos > 0 then begin
            k := Trim(Copy(line, 1, eqPos - 1));
            v := Trim(Copy(line, eqPos + 1, MaxInt));
            if SameText(k, key) then begin
              value := v;
              exit;
            end;
          end;
        end;
      end;
    finally
      CloseFile(f);
    end;
  except
    { Silently ignore I/O errors — caller keeps the default value. }
  end;
end;

{ Writes (or updates) key=value in section within inifile. }
procedure WriteProfile(inifile, section, key, value: string);
var
  lines: TStringList;
  i, secLine, keyLine: integer;
  line, k: string;
  eqPos: integer;
  inSection: boolean;
begin
  lines := TStringList.Create;
  try
    if FileExists(inifile) then
      lines.LoadFromFile(inifile);

    { Find section and key positions }
    secLine  := -1;
    keyLine  := -1;
    inSection := false;
    for i := 0 to lines.Count - 1 do begin
      line := Trim(lines[i]);
      if (Length(line) >= 2) and
         (line[1] = '[') and
         (line[Length(line)] = ']') then begin
        if inSection then
          break;  { Left our section without finding key }
        if SameText(Copy(line, 2, Length(line) - 2), section)
        then begin
          secLine   := i;
          inSection := true;
        end;
      end else if inSection then begin
        eqPos := Pos('=', line);
        if eqPos > 0 then begin
          k := Trim(Copy(line, 1, eqPos - 1));
          if SameText(k, key) then begin
            keyLine := i;
            break;
          end;
        end;
      end;
    end;

    if keyLine >= 0 then begin
      { Update existing key }
      lines[keyLine] := key + '=' + value;
    end else if secLine >= 0 then begin
      { Insert key after section header }
      lines.Insert(secLine + 1, key + '=' + value);
    end else begin
      { Append new section and key }
      if lines.Count > 0 then
        lines.Add('');
      lines.Add('[' + section + ']');
      lines.Add(key + '=' + value);
    end;

    lines.SaveToFile(inifile);
  finally
    lines.Free;
  end;
end;

{ ===== Disk / media helpers ===== }

function DiskStatus(drive: byte): byte;
begin
  if SysUtils.DiskFree(drive) >= 0 then
    DiskStatus := 0
  else
    DiskStatus := 1;
end;

function DiskFree(drive: byte): longint;
var
  free: int64;
begin
  free := SysUtils.DiskFree(drive);
  if free < 0 then
    DiskFree := 0
  else if free > High(longint) then
    DiskFree := High(longint)
  else
    DiskFree := longint(free);
end;

function DiskFreePath(const dir: string): Int64;
var
  saved: string;
  free: Int64;
begin
  saved := GetCurrentDir;
  if SetCurrentDir(dir) then begin
    free := SysUtils.DiskFree(0);
    SetCurrentDir(saved);
    if free < 0 then
      DiskFreePath := 0
    else
      DiskFreePath := free;
  end else
    DiskFreePath := 0;
end;

function GetDevId(const dir: string): Int64;
{$IFDEF UNIX}
var
  info: BaseUnix.Stat;
  path: AnsiString;
begin
  info := Default(BaseUnix.Stat);
  path := dir;
  if fpStat(path, info) = 0 then
    GetDevId := info.st_dev
  else
    GetDevId := -1;
end;
{$ELSE}
begin
  GetDevId := 0;
end;
{$ENDIF}

function DiskSize(drive: byte): longint;
var
  sz: int64;
begin
  sz := SysUtils.DiskSize(drive);
  if sz < 0 then
    DiskSize := 0
  else if sz > High(longint) then
    DiskSize := High(longint)
  else
    DiskSize := longint(sz);
end;

function FormatFreeBytes(freeBytes: Int64): string;
const
  suffixes: array[0..4] of char = ('B', 'K', 'M', 'G', 'T');
var
  idx: integer;
  whole, frac: Int64;
begin
  if freeBytes < 0 then freeBytes := 0;
  idx := 0;
  whole := freeBytes;
  frac := 0;
  while (idx < 4) and (whole >= 1024) do begin
    frac := whole mod 1024;
    whole := whole div 1024;
    Inc(idx);
  end;
  if idx = 0 then
    FormatFreeBytes := IntToStr(whole)
  else if whole < 10 then
    FormatFreeBytes := IntToStr(whole) + '.' +
      IntToStr((frac * 10) div 1024) + suffixes[idx]
  else
    FormatFreeBytes := IntToStr(whole) + suffixes[idx];
end;
