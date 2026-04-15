# Easy Spectrum Navigator

A dual-panel file manager for ZX Spectrum disk images, ported from the
original DOS program by [RomanRom2](https://zxsn.ru/) to Free Pascal
for macOS and Linux.

<p align="center">
  <img src="docs/esn.png" alt="Easy Spectrum Navigator">
</p>

ESN provides a Norton Commander-style interface for browsing, copying,
moving, and deleting files across ZX Spectrum disk and archive formats.

## Supported Formats

| Format | Description                          |
|--------|--------------------------------------|
| TRD    | TR-DOS virtual disk image            |
| SCL    | Multi-file container                 |
| FDI    | Full Disk Image with track metadata  |
| FDD    | Floppy disk image (Scorpion256)      |
| TAP    | Tape image                           |
| ZXZIP  | Compressed archive                   |
| Hobeta | Individual files with TR-DOS headers |

## Building

Requires [Free Pascal Compiler](https://www.freepascal.org/) (fpc).

```
make
```

The binary is produced at `bin/esn`.

### Windows

- Install [Free Pascal](https://www.freepascal.org/download.html)
  for Windows and ensure `fpc` is on `PATH`.
- If the compiler cannot find standard units (`Video`, `Keyboard`,
  etc.), generate the default configuration file:

```powershell
$fpcBin = Split-Path (Get-Command fpc).Source
fpcmkcfg -d "basepath=$(Split-Path (Split-Path $fpcBin))" -o "$fpcBin\fpc.cfg"
```

- Build from PowerShell:

```powershell
.\build.ps1
```

The binary is produced at `bin\esn.exe`.

## Usage

```
./bin/esn
```

### Windows

```powershell
.\bin\esn.exe
```

## Testing

```
make test             # run all tests
make unit-test        # run unit tests only
make integration-test # run integration tests (requires tmux)
```

Notes for Windows:
- Unit tests can be run if you have a compatible `make` environment (e.g. MSYS2).
- Integration tests are bash+tmux based and are intended for macOS/Linux (or Windows via WSL/MSYS2 with tmux).

## License

See the [original program's website](https://zxsn.ru/) for license
information.
