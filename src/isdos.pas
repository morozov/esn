{$O+,F+}
unit isdos;
interface
const
{ коды ошибок }
    eOk=0;
    eBadController =1;
    eTimeOut       =2;
    eSeekError     =3;
    eDriveNotReady =4;
    eEndOfCylinder =5;
    eBadSector     =6;
    eDMAError      =7;
    eSectorNotFound=8;
    eWriteProtect  =9;
    eUnknownError  =10;
Type
    TFDCBuf=array[0..1024*5] of byte;
Var
    FDCbuf              :TFDCBuf;
    status              :array[0..7] of byte;
    IOError             :Byte;
    DMAPage, DMAOfs     :word;
    HobetaBug           :boolean;

function iErrorStr(err:byte):string;
procedure iStartDrive(drv:byte);
procedure izxSeek(drv,trck:byte);
procedure iReadSector(drv,trck,hd,sctr:byte);
procedure iWriteSector(drv,trck,hd,sctr:byte);
Procedure iFormatTrack(Drv,Trck,Had:Byte);

function iInitFDD(drv:byte; init:boolean):boolean;

procedure Format_ISDOS;
procedure Load_ISDOS;

implementation
uses Dos, Crt, rv, pc, main, main_ovr, vars, palette, TRD, FDD, FDI, sn_obj{};


{----------------------------------------------------------------------------}
function iErrorStr(err:byte):string;
begin
 Case err of
  0: iErrorStr:='Ok              ';
  1: iErrorStr:='Bad Controller  ';
  2: iErrorStr:='Time Out        ';
  3: iErrorStr:='Seek Error      ';
  4: iErrorStr:='Drive Not Ready ';
  5: iErrorStr:='End Of Cylinder ';
  6: iErrorStr:='Bad Sector      ';
  7: iErrorStr:='DMA Error       ';
  8: iErrorStr:='Sector Not Found';
  9: iErrorStr:='Write Protect   ';
  10:iErrorStr:='Unknown Error   ';
  27:iErrorStr:='User Break      ';
 End;
end;


{----------------------------------------------------------------------------}
Function TestBit(Num, Bit: Byte): Boolean;
Const Bits: ARRAY[0..7] OF Word = (1,2,4,8,16,32,64,128);
begin
  TestBit:=(Num AND Bits[Bit])<>0;
end;


{----------------------------------------------------------------------------}
Function In_FDC: Byte; VAR i: LongInt; begin
  i:=128;
  While (port[$3F4] AND $C0)<>$C0 DO BEGIN Dec(i); IF i=0 THEN Exit; END;
  IF i<>0 THEN In_FDC:=port[$3F5] ELSE IOError:=eTimeOut;
end;


{----------------------------------------------------------------------------}
Procedure Out_FDC(Comm: Byte); VAR i: LongInt; begin
  i:=128;
  While (port[$3F4] AND $C0)<>$80 DO BEGIN Dec(i); IF i=0 THEN Exit; END;
  IF i<>0 THEN port[$3F5]:=Comm ELSE IOError:=eTimeOut;
end;


{----------------------------------------------------------------------------}
Procedure WaitInt;
var timer:word; WasInt:byte;
begin
  WasInt:=0; timer:=2000;
  While (WasInt=0)AND(Timer>0) DO begin
   dec(timer); delay(1);
   asm
      push DS
      push AX
      xor  AX, AX
      mov  DS, AX
      test byte ptr DS:[43Eh], 80h
      jz   @noInt
      and  byte ptr DS:[43Eh], 7Fh
      mov  WasInt, 1
   @noInt:
      pop  AX
      pop  DS
   end;
  end;
  IF WasInt=0 then IOError:=eTimeOut;
end;


{----------------------------------------------------------------------------}
procedure iStartDrive(drv:byte);
begin
if drv=0 then port[$3F2]:=28 else port[$3F2]:=45;
delay(100);{}
end;


{----------------------------------------------------------------------------}
procedure izxSeek(drv,trck:byte);
begin
iStartDrive(drv);
out_fdc(15);
out_fdc(drv);
out_fdc(trck);
waitint;
delay(25);{}
end;


{----------------------------------------------------------------------------}
{ Увеличить значение указателя p на величину Off}
procedure IncPtr(VAR p:pointer; Off:Word);
  begin
    asm
      push      ds
      lds       di,p
      mov       ax,Off
      add       [di],ax
      jnc       @1
      add       word ptr [di+2],1000h
  @1: pop       ds
    end;
  end;
{ Преобразовать указатель в страницу и смещение для DMA}
procedure ConvPtr(p:Pointer; VAR Page,Off:Word);
  begin
    asm
      push      ds
      lds       dx,p
      mov       bx,ds
      mov       ax,bx
      mov       cl,4
      shl       ax,cl
      add       ax,dx
      pushf
      lds       di,off
      mov       [di],ax
      mov       ax,bx
      mov       cl,12
      shr       ax,cl
      popf
      jnc        @1
      inc       ax
  @1: lds       di,page
      mov       [di],ax
      pop       ds
    end;
  end;
{----------------------------------------------------------------------------}
procedure iReadSector(drv,trck,hd,sctr:byte);
var
    BlockSize:word;
begin
{заносим 5 сек для отключения мотора после чтения данных}
  asm
   push DS
   push AX
   xor  AX, AX
   mov  DS, AX
   mov  byte ptr DS:[440h], 90
   pop  AX
   pop  DS
  end;
{Программирование DMA}
  ConvPtr(@FDCbuf,DMAPage,DMAOfs);{}
  BlockSize:=1024;
  asm cli end;
{  port[$0A]:=$06;                   { маскировать 2 канал }
  port[$0C]:=$46;                   { сбросить триггер }
  port[$0B]:=$46;                   { режим: FDD -> Memory }
  port[$04]:=DMAOfs AND $FF;        { смещение в странице DMA, мл. байт }
  port[$04]:=DMAOfs SHR 8;          { смещение в странице DMA, ст. байт }
  port[$81]:=DMAPage AND $FF;       { страница DMA }
  port[$05]:=(BlockSize-1) AND $FF; { размер блока, мл. байт }
  port[$05]:=(BlockSize-1) SHR 8;   { размер блока, ст. байт }
  port[$0A]:=$02;                   { размаскировать 2 канал }
  asm sti end;
{команды чтения}
Out_FDC($46);
IF hd>0 THEN Out_FDC(drv OR $04) ELSE Out_FDC(drv);
Out_FDC(Trck);
Out_FDC(Hd);
Out_FDC(Sctr);
Out_FDC(3);
Out_FDC(9);
Out_FDC($1B);
Out_FDC($FF);
{выполняем}
WaitInt;
{читаем результат}
status[0]:=in_fdc;
status[1]:=in_fdc;
status[2]:=in_fdc;
status[3]:=in_fdc;
status[4]:=in_fdc;
status[5]:=in_fdc;
status[6]:=in_fdc;
Out_FDC(4);
Out_FDC(drv);
status[7]:=in_fdc;
{анализируем}
IOError:=0;
if (status[0] and $C0)<>0 then
 begin
  IOError:=eUnknownError;
  if TestBit(status[0],3) then IOError:=eDriveNotReady;
  if TestBit(status[1],7) then IOError:=eEndOfCylinder;
  if TestBit(status[1],5) or TestBit(status[2],5) or TestBit(status[2],0)
     then IOError:=eBadSector;
  if TestBit(status[1],2) or TestBit(status[1],4) then IOError:=eSectorNotFound;
  if TestBit(status[1],4) then IOError:=eDMAError;
 end;
if (TestBit(status[7],1)) then IOError:=eDriveNotReady;
end;


{----------------------------------------------------------------------------}
procedure iWriteSector(drv,trck,hd,sctr:byte);
var
    BlockSize:word;
begin
{заносим 5 сек для отключения мотора после чтения данных}
  asm
   push DS
   push AX
   xor  AX, AX
   mov  DS, AX
   mov  byte ptr DS:[440h], 90
   pop  AX
   pop  DS
  end;
{Программирование DMA}
  ConvPtr(@FDCbuf,DMAPage,DMAOfs);{}
  BlockSize:=1024;
  asm cli end;
{  port[$0A]:=$06;                   { маскировать 2 канал }
  port[$0C]:=$4A;                   { сбросить триггер }
  port[$0B]:=$4A;                   { режим: Memory -> FDD }
  port[$04]:=DMAOfs AND $FF;        { смещение в странице DMA, мл. байт }
  port[$04]:=DMAOfs SHR 8;          { смещение в странице DMA, ст. байт }
  port[$81]:=DMAPage AND $FF;       { страница DMA }
  port[$05]:=(BlockSize-1) AND $FF; { размер блока, мл. байт }
  port[$05]:=(BlockSize-1) SHR 8;   { размер блока, ст. байт }
  port[$0A]:=$02;                   { размаскировать 2 канал }
  asm sti end;
{команды записи}
Out_FDC($45);
IF hd>0 THEN Out_FDC(drv OR $04) ELSE Out_FDC(drv);
Out_FDC(Trck);
Out_FDC(Hd);
Out_FDC(Sctr);
Out_FDC(3);
Out_FDC(9);
Out_FDC($1B);
Out_FDC($FF);
{выполняем}
WaitInt;
{читаем результат}
status[0]:=in_fdc;
status[1]:=in_fdc;
status[2]:=in_fdc;
status[3]:=in_fdc;
status[4]:=in_fdc;
status[5]:=in_fdc;
status[6]:=in_fdc;
Out_FDC(4);
Out_FDC(drv);
status[7]:=in_fdc;
{анализируем}
IOError:=0;
if (status[0] and $C0)<>0 then
 begin
  IOError:=eUnknownError;
  if TestBit(status[0],3) then IOError:=eDriveNotReady;
  if TestBit(status[1],7) then IOError:=eEndOfCylinder;
  if TestBit(status[1],5) or TestBit(status[2],5) or TestBit(status[2],0)
     then IOError:=eBadSector;
  if TestBit(status[1],2) or TestBit(status[1],4) then IOError:=eSectorNotFound;
  if TestBit(status[1],4) then IOError:=eDMAError;
 end;
if (TestBit(status[7],1)) then IOError:=eDriveNotReady;
end;


{----------------------------------------------------------------------------}
Procedure iFormatTrack(Drv,Trck,Had:Byte);
var
    BlockSize: Word;
    i:integer;
    si:byte;
begin
  asm {в счетчик [0:440] ведающий остановкой мотора дискеты заносим 5 сек}
   push DS
   push AX
   xor  AX, AX
   mov  DS, AX
   mov  byte ptr DS:[440h], 90
   pop  AX
   pop  DS
  end;
  IOError:=eOk;
{ Параметры C,H,R,N для каждого сектора на дорожке}
FDCbuf[00]:=Trck;  FDCbuf[01]:=had;  FDCbuf[02]:=1;  FDCbuf[03]:=3;
FDCbuf[04]:=Trck;  FDCbuf[05]:=had;  FDCbuf[06]:=2;  FDCbuf[07]:=3;
FDCbuf[08]:=Trck;  FDCbuf[09]:=had;  FDCbuf[10]:=3;  FDCbuf[11]:=3;
FDCbuf[12]:=Trck;  FDCbuf[13]:=had;  FDCbuf[14]:=4;  FDCbuf[15]:=3;
FDCbuf[16]:=Trck;  FDCbuf[17]:=had;  FDCbuf[18]:=9;  FDCbuf[19]:=3;
{Программирование DMA}
  ConvPtr(@FDCbuf,DMAPage,DMAOfs);{}
  BlockSize:=20;
  asm cli end;
{  port[$0A]:=$06;                   { маскировать 2 канал }
  port[$0C]:=$4A;                   { сбросить триггер }
  port[$0B]:=$4A;                   { режим: Memory -> FDD }
  port[$04]:=DMAOfs AND $FF;        { смещение в странице DMA, мл. байт }
  port[$04]:=DMAOfs SHR 8;          { смещение в странице DMA, ст. байт }
  port[$81]:=DMAPage AND $FF;       { страница DMA }
  port[$05]:=(BlockSize-1) AND $FF; { размер блока, мл. байт }
  port[$05]:=(BlockSize-1) SHR 8;   { размер блока, ст. байт }
  port[$0A]:=$02;                   { размаскировать 2 канал }
  asm sti end;
  { Формирование приказа }
  Out_FDC($4D);
  IF Had>0 THEN Out_FDC(Drv OR $04) ELSE Out_FDC(Drv);
  Out_FDC(3);    {SectorSize}
  Out_FDC(9);   {EOT}
  Out_FDC(102);  {GPLF}
  if trck=0 then Out_FDC($00) else Out_FDC($FF);  {FillByte}
{выполняем}
WaitInt;
{читаем результат}
status[0]:=in_fdc;
status[1]:=in_fdc;
status[2]:=in_fdc;
status[3]:=in_fdc;
status[4]:=in_fdc;
status[5]:=in_fdc;
status[6]:=in_fdc;
Out_FDC(4);
Out_FDC(drv);
status[7]:=in_fdc;
{анализируем}
IOError:=0;
if (status[0] and $C0)<>0 then
 begin
  IOError:=eUnknownError;
  if TestBit(status[0],3) then IOError:=eDriveNotReady;
  if TestBit(status[1],7) then IOError:=eEndOfCylinder;
  if TestBit(status[1],5) or TestBit(status[2],5) or TestBit(status[2],0)
     then IOError:=eBadSector;
  if TestBit(status[1],2) or TestBit(status[1],4) then IOError:=eSectorNotFound;
  if TestBit(status[1],4) then IOError:=eDMAError;
 end;
if (TestBit(status[7],1)) then IOError:=eDriveNotReady;
end;


{----------------------------------------------------------------------------}
function iInitFDD(drv:byte; init:boolean):boolean;
var speed:byte;
    SRT,HUT,HLT:byte;
begin
iInitFDD:=true;
port[$3F2]:=8;
iStartDrive(drv);
out_fdc(7); out_fdc(drv); waitint;
out_fdc(7); out_fdc(drv); waitint;
SRT:=$F;
HUT:=$D;
HLT:=$1;
Out_FDC($03);
Out_FDC(SRT OR (HUT SHL 4));
Out_FDC(HLT SHL 1);
{скорость по умолчанию 250 кб/с для A: и 300 кб/с для B:}
if drv=0 then port[$3F7]:=2 else port[$3F7]:=1;
if init then
 BEGIN
  iInitFDD:=false;
  for speed:=0 to 2 do begin
   port[$3F7]:=speed; iReadSector(drv,0,0,9);
   if IOError=eOk then begin iInitFDD:=true; break; end;
  end;
  if IOError<>eOk then exit;
  izxSeek(drv,1); iReadSector(drv,1,0,9);
 END;
IOError:=0;
end;

{%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%}
{%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%}
{%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%}


{****************************************************************************}
procedure Load_ISDOS;
label
      beg,fin;
var
      fname:string;
      bads,lastx,i:integer;
      Out,error:boolean;
      key,What:char;
      Track, Head, Sector,
      TotalTracks,up80err,In1HeadErr:byte;
      FF:file of TFDCBuf;
      tmp: TFDCbuf;
begin
  What:=ChooseDrive(focus,DiskMenuType,LANG,'A');
  if (What<>'A')and(What<>'B') then exit;

beg:
  CancelSB;
  Colour(7,0); sPutWin(25,halfmaxy-4,55,halfmaxy+0);
  cmCentre(7,0,halfmaxy-2,'Wait, detecting media...');
  if not iInitFDD(Ord(UpCase(What))-Ord('A'),CheckMedia) then begin restscr; errormessage('No iS-DOS'); exit; end;
  restscr;
  CurOff;
  window(21,8,60,18);
  scputwin(Blue,White,19,5,61,21);
  cmcentre(Blue,White,5,' Reading iS-DOS disk ');
  izxSeek(Ord(UpCase(What))-Ord('A'),0);
  iReadSector(Ord(UpCase(What))-Ord('A'),0,0,1);
  fname:=''; for i:=1 to 8 do fname:=fname+chr(FDCbuf[i+1]); fname:=hob2pc(fname);
  cmprint(Blue,Yellow,21{+11{},6,fname);
  if nospace(fname)='' then fname:='zxdisk';
  fname:=fname+'.img';
  fname:=CheckEx(pcndOf(Focus),fname);
  { Открытие выходного файла }
  Assign(FF,fname); ReWrite(FF);
  { Чтение дорожек и запись в файл }
  bads:=0; error:=false; up80err:=0; Out:=false;
  if LoadUp80 then TotalTracks:=82 else TotalTracks:=79;
  TotalTracks:=79;
  FOR Track:=0 TO TotalTracks DO BEGIN
    izxSeek(Ord(UpCase(What))-Ord('A'),Track);
    FOR Head:=0 TO 1 DO BEGIN
      error:=false;
      Colour(Blue,White);
      Write('Track:');
      Colour(Blue,LightGray);
      Write(Track:2);
      Colour(Blue,White);
      Write(' Head:');
      Colour(Blue,LightGray);
      Write(Head:1,'  ');
      In1HeadErr:=0;

      FOR Sector:=1 to 5 DO BEGIN
       if Sector=5 then iReadSector(Ord(UpCase(What))-Ord('A'),Track,Head,9)
                   else iReadSector(Ord(UpCase(What))-Ord('A'),Track,Head,Sector);
       if IOError=0 then
        begin
         cmPrint(Blue,LightGreen,36+sector,wherey,'');
         if not error then cmprint(Blue,White,44,wherey,iErrorStr(IOError));
         for i:=0 to 1023 do tmp[1024*(sector-1)+i]:=FDCbuf[i];
        end
       else
        begin
         cmPrint(Blue,LightRed,36+sector,wherey,'');
         cmprint(Blue,LightRed,44,wherey,iErrorStr(IOError));
         for i:=0 to 1023 do tmp[1024*(sector-1)+i]:=ord('B');
         inc(bads);
         error:=true;
        end;
       IF keypressed THEN BEGIN key:=readkey; if key=kb_ESC then goto fin; END;
      END;
     writeln;
     Write(FF,tmp)
    END;
  END;
{  Message('Файл сформирован.');{}
fin:
  cmprint(Blue,White,21,20,strr(bads)+' bad sectors.');
  Close(FF); { Закрытие файла }
  fname:='~`ESC~` Cancel  ~`ENTER~` To load one more disk';
  cStatusBar(pal.bkSBarNT,pal.txtSBarNT,pal.bkSBarST,pal.txtSBarST,0,fname);
  key:=readkey;
  restscr;
  if (key=kb_ENTER){or(key=kb_SPACE){} then goto beg;
end;




{****************************************************************************}
procedure Format_ISDOS;
label fin;
var
  What: char;
  bads: integer;
  bads1t,try,proofs,t_,h_,s_,vs_,Sides,MaxTracks: byte;
  err,Verify,MaximumTracks: boolean;
  DiskLabel: string;

procedure GetFormatParam;
begin
  Verify:=true; proofs:=3;
  DiskLabel:='ZX-DISK'; DiskLabel:=sRExpand(DiskLabel,8);
  Sides:=2;
  MaxTracks:=79;
  MaximumTracks:=true;
  if MaximumTracks then MaxTracks:=82;
  MaxTracks:=79;
end;

begin
  if not cQuestion('Format iS-DOS disk'#255'Are you sure?',eng) then exit;
  What:=ChooseDrive(focus,DiskMenuType,LANG,'A');
  if (What<>'A')and(What<>'B') then exit;
  CancelSB;
  Colour(7,0);
  CurOff;
  GetFormatParam;
  window(21,9,60,18);
  scputwin(Blue,White,19,5,61,22);
  cmcentre(Red,White,5,' Format iS-DOS disk ');
  iInitFDD(Ord(UpCase(What))-Ord('A'),false);
  bads:=0;
  for t_:=0 to MaxTracks do
   begin
    izxSeek(Ord(UpCase(What))-Ord('A'),T_);
    for h_:=0 to Sides-1 do
     begin
      Colour(Blue,White);      Write('Track:');
      Colour(Blue,LightGray);  Write(T_:2);
      Colour(Blue,White);      Write(' Head:');
      Colour(Blue,LightGray);  Write(H_:1,'  ');
      cmCentre(Blue,White,7,' Formating ');
      iFormatTrack(Ord(UpCase(What))-Ord('A'),t_,h_);{}
      FOR S_:=1 to 5 DO cmPrint(Blue,White,36+s_,wherey,'');
      cmPrint(Blue,White,44,wherey,iErrorStr(IOError));
      if Verify then
       Begin
        try:=proofs;
        repeat
         err:=false;
         if proofs-try>0 then cmCentre(Blue,White,7,'Checking '+strr(proofs-try+1))
                         else cmCentre(Blue,White,7,' Checking  ');
         bads1t:=0;
         for vs_:=1 to 5 do
          begin
           if vs_=5 then iReadSector(Ord(UpCase(What))-Ord('A'),t_,h_,9)
                    else iReadSector(Ord(UpCase(What))-Ord('A'),t_,h_,vs_);
            if IOError=eOk then
             begin
              cmPrint(Blue,LightGreen,36+vs_,wherey,'');
             end
            else
             begin
              cmPrint(Blue,LightRed,36+vs_,wherey,'');
              cmprint(Blue,LightRed,44,wherey,iErrorStr(IOError));
              err:=true;
              inc(bads1t);
             end;
           if keypressed then if readkey=#27 then begin cmCentre(Blue,White,7,' Canceled  '); goto fin; end;
          end;
         dec(try);
         if err and (try>0) then
          begin
           cmCentre(Blue,White,7,' Formating ');
           iFormatTrack(Ord(UpCase(What))-Ord('A'),t_,h_);
           FOR S_:=1 to 5 DO cmPrint(Blue,White,36+s_,wherey,'');
           cmprint(Blue,White,44,wherey,iErrorStr(IOError));
          end else break;
        until try=0;
       End;
      inc(bads,bads1t);
      if keypressed then if readkey=#27 then begin cmCentre(Blue,White,7,' Canceled  '); goto fin; end;
      writeln;
     end;
   end;
  Colour(Blue,White);
  WriteLn; Write(bads,' bad sectors.');
  cmCentre(Blue,White,7,'   Ready   ');
  cmprint(Blue,White,21,20,'Disk was formatted.');

fin:
  readkey;
  restscr;
end;



end.