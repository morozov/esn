{$O+,F+}
unit trdos;
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
    TFDCBuf=array[0..4095*2] of byte;
Var
    FDCbuf              :TFDCBuf;
    status              :array[0..7] of byte;
    IOError             :Byte;
    DMAPage, DMAOfs     :word;
    HobetaBug           :boolean;
    HobetaDetected      :boolean;

function ErrorStr(err:byte):string;
procedure StartDrive(drv:byte);
procedure zxSeek(drv,trck:byte);
procedure ReadSector(drv,trck,hd,sctr,qnt:byte);
procedure WriteSector(drv,trck,hd,sctr,qnt:byte);
Procedure FormatTrackTRDOS(Drv,Trck,Had:Byte; HB:boolean; interlv:byte);
procedure ReadFullTrack(drv,trck,hd:byte);
function Read1stSector(drv,trck,hd:byte):boolean;
procedure dump(sc:byte);
function initFDD(drv:byte; init:boolean):boolean;

procedure Load_TRDOS;
procedure Save_TRDOS;
procedure Format_TRDOS;

implementation
uses Dos, Crt, rv, pc, main, main_ovr, vars, palette, TRD, FDD, FDI, sn_obj;


{----------------------------------------------------------------------------}
function ErrorStr(err:byte):string;
begin
 Case err of
  0: ErrorStr:='Ok              ';
  1: ErrorStr:='Bad Controller  ';
  2: ErrorStr:='Time Out        ';
  3: ErrorStr:='Seek Error      ';
  4: ErrorStr:='Drive Not Ready ';
  5: ErrorStr:='End Of Cylinder ';
  6: ErrorStr:='Bad Sector      ';
  7: ErrorStr:='DMA Error       ';
  8: ErrorStr:='Sector Not Found';
  9: ErrorStr:='Write Protect   ';
  10:ErrorStr:='Unknown Error   ';
  27:ErrorStr:='User Break      ';
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
procedure StartDrive(drv:byte);
begin
{
asm STI end;
port[$3F2]:=0;
port[$3F2]:=(drv+1)*16+$C+drv;
{}

if drv=0 then port[$3F2]:=28 else port[$3F2]:=45;{}
delay(25);{}
end;


{----------------------------------------------------------------------------}
procedure zxSeek(drv,trck:byte);
begin
StartDrive(drv);{}
out_fdc(15);
out_fdc(drv);
out_fdc(trck);
waitint;
{delay(250);{}
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
procedure ReadSector(drv,trck,hd,sctr,qnt:byte);
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
  BlockSize:=qnt*256;
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
if HobetaBUG then Out_FDC(0) else Out_FDC(Hd);
Out_FDC(Sctr);
Out_FDC(1);
Out_FDC(16);
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
if SNDEBUG then begin
cmprint(0,green,2,09,'ST0:'+hex2bin(dec2hex(strr(status[0]))));
cmprint(0,green,2,10,'ST1:'+hex2bin(dec2hex(strr(status[1]))));
cmprint(0,green,2,11,'ST2:'+hex2bin(dec2hex(strr(status[2]))));
cmprint(0,green,2,12,'  C:'+hex2bin(dec2hex(strr(status[3]))));
cmprint(0,green,2,13,'  H:'+hex2bin(dec2hex(strr(status[4]))));
cmprint(0,green,2,14,'  R:'+hex2bin(dec2hex(strr(status[5]))));
cmprint(0,green,2,15,'  N:'+hex2bin(dec2hex(strr(status[6]))));
cmprint(0,green,2,16,'ST3:'+hex2bin(dec2hex(strr(status[7]))));{}
end;
{}

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
if (TestBit(status[7],1)) then IOError:=eDriveNotReady;{}
end;


{----------------------------------------------------------------------------}
procedure WriteSector(drv,trck,hd,sctr,qnt:byte);
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
  BlockSize:=qnt*256;
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
if HobetaBUG then Out_FDC(0) else Out_FDC(Hd);
Out_FDC(Sctr);
Out_FDC(1);
Out_FDC(16);
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
if SNDEBUG then begin
cmprint(0,red,2,09,'ST0:'+hex2bin(dec2hex(strr(status[0]))));
cmprint(0,red,2,10,'ST1:'+hex2bin(dec2hex(strr(status[1]))));
cmprint(0,red,2,11,'ST2:'+hex2bin(dec2hex(strr(status[2]))));
cmprint(0,red,2,12,'  C:'+hex2bin(dec2hex(strr(status[3]))));
cmprint(0,red,2,13,'  H:'+hex2bin(dec2hex(strr(status[4]))));
cmprint(0,red,2,14,'  R:'+hex2bin(dec2hex(strr(status[5]))));
cmprint(0,red,2,15,'  N:'+hex2bin(dec2hex(strr(status[6]))));
cmprint(0,red,2,16,'ST3:'+hex2bin(dec2hex(strr(status[7]))));{}
end;
{}
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
if (TestBit(status[7],1)) then IOError:=eDriveNotReady;{}
end;


{----------------------------------------------------------------------------}
Procedure FormatTrackTRDOS(Drv,Trck,Had:Byte; HB:boolean; interlv:byte);
var
    BlockSize: Word;
    hd:byte;
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
if HB then hd:=0 else hd:=had;
FDCbuf[00]:=Trck;  FDCbuf[01]:=hd;  FDCbuf[02]:=01;  FDCbuf[03]:=1;  {01}
FDCbuf[04]:=Trck;  FDCbuf[05]:=hd;  FDCbuf[06]:=09;  FDCbuf[07]:=1;  {02}
FDCbuf[08]:=Trck;  FDCbuf[09]:=hd;  FDCbuf[10]:=02;  FDCbuf[11]:=1;  {03}
FDCbuf[12]:=Trck;  FDCbuf[13]:=hd;  FDCbuf[14]:=10;  FDCbuf[15]:=1;  {04}
FDCbuf[16]:=Trck;  FDCbuf[17]:=hd;  FDCbuf[18]:=03;  FDCbuf[19]:=1;  {05}
FDCbuf[20]:=Trck;  FDCbuf[21]:=hd;  FDCbuf[22]:=11;  FDCbuf[23]:=1;  {06}
FDCbuf[24]:=Trck;  FDCbuf[25]:=hd;  FDCbuf[26]:=04;  FDCbuf[27]:=1;  {07}
FDCbuf[28]:=Trck;  FDCbuf[29]:=hd;  FDCbuf[30]:=12;  FDCbuf[31]:=1;  {08}
FDCbuf[32]:=Trck;  FDCbuf[33]:=hd;  FDCbuf[34]:=05;  FDCbuf[35]:=1;  {09}
FDCbuf[36]:=Trck;  FDCbuf[37]:=hd;  FDCbuf[38]:=13;  FDCbuf[39]:=1;  {10}
FDCbuf[40]:=Trck;  FDCbuf[41]:=hd;  FDCbuf[42]:=06;  FDCbuf[43]:=1;  {11}
FDCbuf[44]:=Trck;  FDCbuf[45]:=hd;  FDCbuf[46]:=14;  FDCbuf[47]:=1;  {12}
FDCbuf[48]:=Trck;  FDCbuf[49]:=hd;  FDCbuf[50]:=07;  FDCbuf[51]:=1;  {13}
FDCbuf[52]:=Trck;  FDCbuf[53]:=hd;  FDCbuf[54]:=15;  FDCbuf[55]:=1;  {14}
FDCbuf[56]:=Trck;  FDCbuf[57]:=hd;  FDCbuf[58]:=08;  FDCbuf[59]:=1;  {15}
FDCbuf[60]:=Trck;  FDCbuf[61]:=hd;  FDCbuf[62]:=16;  FDCbuf[63]:=1;  {16}
if interlv=1 then
 begin
  FDCBuf[02]:=1;
  FDCBuf[06]:=2;
  FDCBuf[10]:=3;
  FDCBuf[14]:=4;
  FDCBuf[18]:=5;
  FDCBuf[22]:=6;
  FDCBuf[26]:=7;
  FDCBuf[30]:=8;
  FDCBuf[34]:=9;
  FDCBuf[38]:=10;
  FDCBuf[42]:=11;
  FDCBuf[46]:=12;
  FDCBuf[50]:=13;
  FDCBuf[54]:=14;
  FDCBuf[58]:=15;
  FDCBuf[62]:=16;
 end;

{Программирование DMA}
  ConvPtr(@FDCbuf,DMAPage,DMAOfs);{}
  BlockSize:=64;
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
  Out_FDC(1);    {SectorSize}
  Out_FDC(16);   {EOT}
  Out_FDC($32);  {GPLF}
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
if SNDEBUG then begin
cmprint(0,7,2,09,'ST0:'+hex2bin(dec2hex(strr(status[0]))));
cmprint(0,7,2,10,'ST1:'+hex2bin(dec2hex(strr(status[1]))));
cmprint(0,7,2,11,'ST2:'+hex2bin(dec2hex(strr(status[2]))));
cmprint(0,7,2,12,'  C:'+hex2bin(dec2hex(strr(status[3]))));
cmprint(0,7,2,13,'  H:'+hex2bin(dec2hex(strr(status[4]))));
cmprint(0,7,2,14,'  R:'+hex2bin(dec2hex(strr(status[5]))));
cmprint(0,7,2,15,'  N:'+hex2bin(dec2hex(strr(status[6]))));
cmprint(0,7,2,16,'ST3:'+hex2bin(dec2hex(strr(status[7]))));{}
end;
{}
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
if (TestBit(status[7],1)) then IOError:=eDriveNotReady;{}
end;


{----------------------------------------------------------------------------}
procedure ReadFullTrack(drv,trck,hd:byte);
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
  BlockSize:=32*256;
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
Out_FDC($42);
IF hd>0 THEN Out_FDC(drv OR $04) ELSE Out_FDC(drv);
Out_FDC(Trck);
if HobetaBUG then Out_FDC(0) else Out_FDC(Hd);{}
Out_FDC(1);
Out_FDC(6);
Out_FDC(32);
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
if (TestBit(status[7],1)) then IOError:=eDriveNotReady;{}
end;


{----------------------------------------------------------------------------}
function Read1stSector(drv,trck,hd:byte):boolean;
var ofs,w,n:word;
    ind,maxtry,try,ofstry,shl_:WORD;
    WASBEEP,idzFind, find:boolean;
FOB:FILE;
label loop, IDs;
begin
{beep(3000,50);{}
SaveCur;
Colour(7,0);
sPutWin(25,halfmaxy-4,55,halfmaxy+0);
cmCentre(7,0,halfmaxy-2,'Searching 1st sector...');
gotoxy(28,halfmaxy-2);

Read1stSector:=false;
maxtry:=32; ind:=1; idzFind:=false;

loop:
zxSeek(drv,trck); ReadFullTrack(drv,trck,hd);

if idzFind then goto IDs;

{ищем последовательность A1 A1 A1 FE - ID заголовка}
{ofs:=$182D-127; {cмещения для диcкет фоpматиpованных на PC}
{ofs:=$16D8-127; {на ZX}

ofs:=$0;
WASBEEP:=FALSE;

{shl 1}
 FOR shl_:=0 to 8 do BEGIN
  if shl_>0 then FDCbuf[ofs+1]:=FDCbuf[ofs+1] shl 1;
  for n:=2 to 32*256 do begin
   w:=(FDCbuf[ofs+n] shl shl_);
   FDCbuf[ofs+n-1]:=FDCbuf[ofs+n-1] or hi(w);
   FDCbuf[ofs+n]:=lo(w);
  end;
{ищем последовательность A1 A1 A1 FE - ID заголовка 1 сектора}
  idzfind:=false;
  for try:=0 to 32*256-10 do begin
{
   if (FDCbuf[ofs+0+try]=$A1)and(FDCbuf[ofs+1+try]=$A1)and
      (FDCbuf[ofs+2+try]=$A1)and(FDCbuf[ofs+3+try]=$FE) then
    begin
     if (FDCbuf[ofs+4+try]=trck)and(FDCbuf[ofs+5+try]=hd)and
        (FDCbuf[ofs+6+try]=$01)and(FDCbuf[ofs+7+try]=$01)
     then begin idzfind:=true; break; end;
    end;
{}
     if
        (FDCbuf[ofs+0+try]=$A1)and(FDCbuf[ofs+1+try]=$A1)and
        (FDCbuf[ofs+2+try]=$A1)and(FDCbuf[ofs+3+try]=$FE)and
        (FDCbuf[ofs+4+try]=trck)and(FDCbuf[ofs+5+try]=hd)and
        (FDCbuf[ofs+6+try]=$01)and(FDCbuf[ofs+7+try]=$01)
     then begin idzfind:=true; break; end;


  end;
  if idzfind then break;
 END;

if shl_=8 then
 begin
  inc(ind); if ind>4 then ind:=1;
  case ind of 1: write('/'); 2: write('-'); 3: write('\'); 4: write('|'); end; gotoxy(wherex-1,wherey);
  dec(maxtry);
  if maxtry>1 then goto loop;
 end;

if idzFind then begin ofs:=ofs+try; maxtry:=16; end;
if maxtry=1 then begin idzFind:=true; maxtry:=16; ofs:=$16D8-12;{на ZX} BEEP(2000,200); WASBEEP:=TRUE; end;




IDs:
{ищем последовательность A1 A1 A1 FB - ID сектора}
{shl 1}
 FOR shl_:=0 to 8 do BEGIN
  if shl_>0 then FDCbuf[ofs+1]:=FDCbuf[ofs+1] shl 1;
  for n:=2 to 512 do begin
   w:=(FDCbuf[ofs+n] shl shl_);
   FDCbuf[ofs+n-1]:=FDCbuf[ofs+n-1] or hi(w);
   FDCbuf[ofs+n]:=lo(w);
  end;
{ищем последовательность A1 A1 A1 FB - ID сектора}
  find:=false;
  for try:=0 to 255 do begin
   if (FDCbuf[ofs+0+try]=$A1)and(FDCbuf[ofs+1+try]=$A1)and
      (FDCbuf[ofs+2+try]=$A1)and(FDCbuf[ofs+3+try]=$FB) then begin find:=true; break; end;
  end;
  if find then break;
 END;
if shl_=8 then
 begin
  inc(ind); if ind>4 then ind:=1;
  case ind of 1: write('/'); 2: write('-'); 3: write('\'); 4: write('|'); end; gotoxy(wherex-1,wherey);
  dec(maxtry);
  if maxtry>1 then goto loop;
 end;
if find then
 begin
  ofs:=ofs+try+4-1;
  for n:=1 to 256 do FDCbuf[n-1]:=FDCbuf[ofs+n];

{
IF WASBEEP THEN ASSIGN(FOB,'!T'+STRR(TRCK)+'_H'+STRR(HD)+'.256') ELSE ASSIGN(FOB,'T'+STRR(TRCK)+'_H'+STRR(HD)+'.256');
REWRITE(FOB,1); BLOCKWRITE(FOB,FDCBUF,256); CLOSE(FOB);
{}
  Read1stSector:=true;
 end;
restCur;
restscr;
end;


{----------------------------------------------------------------------------}
procedure Dump(sc:byte);
var ofs,i,n:integer; mm:byte;
begin
{ распечатаем }
{$I-}
CancelSB;
CurOff;
Colour(0,7);
window(5,5,75,22);
scputwin(0,7,3,3,76,22);
cmcentre(0,7,3,' Sector dump: ');
gotoxy(3,5);
ofs:=256*(sc-1);
for i:=0 to 16 do begin
 for n:=0 to 16 do
  begin
   gotoxy((n+2)*3,i+5);
   mm:=FDCbuf[ofs+i*16+n];
   mwrite(dec2hex(strr(mm)));
   gotoxy(55+(n+2),i+5);
   if FDCbuf[ofs+i*16+n]>31 then mwrite(chr(FDCbuf[ofs+i*16+n])) else write('.');
  end;
 writeln;
end;
readkey;
restscr;
{$I+}
mm:=ioresult;
end;

{%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%}
{%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%}
{%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%}
{----------------------------------------------------------------------------}
function initFDD(drv:byte; init:boolean):boolean;
var speed:byte;
    SRT,HUT,HLT:byte; zspeed:array[0..2]of byte;
begin
InitFDD:=true;
if not HobetaDetected then HobetaBUG:=false;
port[$3F2]:=8;
StartDrive(drv);
out_fdc(7); out_fdc(drv); waitint;
out_fdc(7); out_fdc(drv); waitint;{}
SRT:=$F;
HUT:=$D;
HLT:=$1;
Out_FDC($03);
Out_FDC(SRT OR (HUT SHL 4));
Out_FDC(HLT SHL 1);
{скорость по умолчанию 250 кб/с для A: и 300 кб/с для B:}
if drv=0 then port[$3F7]:=2 else port[$3F7]:=1;{}
if init then
 BEGIN
  InitFDD:=false;
  if drv=0 then begin zspeed[0]:=2; zspeed[1]:=1; zspeed[2]:=0; end;
  if drv=1 then begin zspeed[0]:=1; zspeed[1]:=2; zspeed[2]:=0; end;
  for speed:=0 to 2 do begin

   port[$3F2]:=8;
   StartDrive(drv);
   out_fdc(7); out_fdc(drv); waitint;
   out_fdc(7); out_fdc(drv); waitint;{}
   port[$3F7]:=zspeed[speed];
   {zxSeek(drv,0);{}
   ReadSector(drv,0,0,9,1);
   if IOError=eOk then begin InitFDD:=true; break; end;
  end;
  if IOError<>eOk then exit;

  ReadSector(drv,0,1,9,1);
  if IOError<>eOk then HobetaBUG:=true;
{
  if not HobetaDetected then
   Begin
    ReadSector(drv,0,1,9,1);
    if IOError<>eOk then HobetaBUG:=true;
    HobetaDetected:=true;
   End;
{}
{  zxSeek(drv,1); ReadSector(drv,1,0,9,1);{}
 END;
IOError:=0;
end;

{%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%}
{%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%}
{%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%}

{____________________________________________________________________________}
Procedure ReadTrack(drv,trck,hd: byte);
Var Tries: Integer;
BEGIN
  Tries:=5;
  zxSeek(drv,trck);
  REPEAT
    ReadSector(drv,trck,hd,1,16);
    Dec(Tries);
  UNTIL (Tries=0) OR (IOError=eOk);
END;
{____________________________________________________________________________}
Procedure ReadTrackSector(What: char; Trck: byte; Hd: Byte; Sctr: Byte);
Var i,sec,Tries: Integer; {var tmp:array[0..4095]of byte;{} wasHobetaBug:boolean;
    k:char;
    erstr:string;
    FOB:file;
BEGIN
{for i:=0 to 4095 do tmp[i]:=0;{}
wasHobetaBug:=HobetaBug;

{errormessage('Sector: '+strr(Sctr));{}

Tries:=5;
REPEAT
 Case Tries of
  1: Colour(Blue,Blue);
  2: Colour(Blue,Black);
  3: Colour(Blue,LightRed);
  4: Colour(Blue,LightMagenta);
  5: Colour(Blue,LightGreen);
 End;
 ReadSector(Ord(UpCase(What))-Ord('A'),Trck,Hd,Sctr,1);
 if IOError<>eOk then
  begin
   HobetaBUG:=not HobetaBUG;
   ReadSector(Ord(UpCase(What))-Ord('A'),Trck,Hd,Sctr,1);
   HobetaBUG:=not HobetaBUG;
  end;
 if Tries<5 then gotoxy(wherex-1,wherey); Write('');
 Dec(Tries);
 if KeyPressed then
  Begin
   k:=ReadKey;
   if k=#27 then begin IOError:=27; exit; end;
  End;
UNTIL (Tries=0) OR (IOError=eOk);

{for i:=0 to 255 do tmp[i+256*(Sctr-1)]:=FDCbuf[i];{}
{ASSIGN(FOB,'T'+STRR(TRCK)+'_H'+STRR(HD)+'_S'+STRR(SCTR)+'.TMP'); REWRITE(FOB,1); BLOCKWRITE(FOB,TMP,4096); CLOSE(FOB);{}
{ASSIGN(FOB,'T'+STRR(TRCK)+'_H'+STRR(HD)+'_S'+STRR(SCTR)+'.FDC'); REWRITE(FOB,1); BLOCKWRITE(FOB,FDCBUF,256); CLOSE(FOB);{}

if IOError<>eOk then
 begin
  if Sctr=1 then
   BEGIN
   if Read1stSector(Ord(UpCase(What))-Ord('A'),Trck,Hd) then
    begin
{     for i:=0 to 255 do tmp[i]:=FDCbuf[i];{}
     Colour(Blue,LightGreen); gotoxy(wherex-1,wherey); Write('');
     IOError:=0;
    end
   else
    begin
     for i:=0 to 255 do FDCBuf[i]:=$42;
     erstr:='[C:'+strr(trck)+' H:'+strr(hd)+' S:'+strr(sctr)+' - Cant get sector]';
     for i:=1 to length(erstr) do FDCBuf[i-1+16]:=ord(erstr[i]);
    end;
   END
  else
   begin
    for i:=0 to 255 do FDCBuf[i]:=$42;
    erstr:='[C:'+strr(trck)+' H:'+strr(hd)+' S:'+strr(sctr)+' - '+ErrorStr(IOError)+']';
    for i:=1 to length(erstr) do FDCBuf[i-1+16]:=ord(erstr[i]);
   end;
 end;
{}
HobetaBug:=wasHobetaBug;
{for i:=0 to 4095 do FDCbuf[i]:=tmp[i];{}
{ASSIGN(FOB,'T'+STRR(TRCK)+'_H'+STRR(HD)+'.TRK'); REWRITE(FOB,1); BLOCKWRITE(FOB,tmp,4096); CLOSE(FOB);{}

{dump(1);{}

END;
{____________________________________________________________________________}
Procedure WriteTrackSector(What:char; Track: byte; Head: Byte; Sector: Byte);
Var i,sec,Tries: Integer; var bufw:array[1..256]of byte; wasHobetaBug:boolean;
    k:char;
BEGIN
wasHobetaBug:=HobetaBug;
Tries:=5;
REPEAT
 Case Tries of
  1: Colour(Blue,Blue);
  2: Colour(Blue,Black);
  3: Colour(Blue,LightRed);
  4: Colour(Blue,LightMagenta);
  5: Colour(Blue,LightGreen);
 End;
 for i:=1 to 256 do bufw[i]:=FDCbuf[i-1+256*(Sector-1)];
 WriteSector(Ord(UpCase(What))-Ord('A'),Track,Head,Sector,1);
 if IOError<>eOk then
  Begin
   HobetaBug:=not HobetaBug;
   WriteSector(Ord(UpCase(What))-Ord('A'),Track,Head,Sector,1);
   HobetaBug:=not HobetaBug;
  End;
 if KeyPressed then
  Begin
   k:=ReadKey;
   if k=#27 then begin IOError:=27; exit; end;
  End;
 if Tries<5 then gotoxy(wherex-1,wherey); Write('');
 Dec(Tries);
UNTIL (Tries=0) OR (IOError=eOk);
HobetaBug:=wasHobetaBug;
END;
{****************************************************************************}
procedure Load_TRDOS;
label
      beg,fin;
type
      TFDCbuf4095=array[0..4095] of byte;
var
      fname:string;
      bads,lastx,i:integer;
      Out,error:boolean;
      key,What:char;
      Track, Head, Sector,
      TotalTracks,up80err,In1HeadErr:byte;
      FF:file of TFDCBuf4095;
      FDCBuf4095: TFDCBuf4095;
begin
  What:=ChooseDrive(focus,DiskMenuType,LANG,'A');
  if (What<>'A')and(What<>'B') then exit;

beg:
  CancelSB;
  Colour(7,0); sPutWin(25,halfmaxy-4,55,halfmaxy+0);
  cmCentre(7,0,halfmaxy-2,'Wait, detecting media...');
  if not InitFDD(Ord(UpCase(What))-Ord('A'),CheckMedia) then begin restscr; errormessage('No TR-DOS'); exit; end;
  restscr;
  CurOff;
  window(15,8,66,18);
  scputwin(Blue,White,13,5,67,21);
  cmcentre(Blue,White,5,' Reading TR-DOS disk ');
  zxSeek(Ord(UpCase(What))-Ord('A'),0);
  ReadSector(Ord(UpCase(What))-Ord('A'),0,0,9,1);
  fname:=''; for i:=1 to 8 do fname:=fname+chr(FDCbuf[$f5+i-1]); fname:=hob2pc(fname);

  cmprint(Blue,White,15{+11{},6,'Drive '+What+':');
  cmprint(Blue,Yellow,15+9{},6,fname);
  if nospace(fname)='' then fname:='zxdisk';
  fname:=fname+'.trd';
  fname:=CheckEx(pcndOf(Focus),fname);
  { Открытие выходного файла }
  Assign(FF,fname); ReWrite(FF);
  { Чтение дорожек и запись в файл }
  bads:=0; error:=false; up80err:=0; Out:=false;
  if LoadUp80 then TotalTracks:=82 else TotalTracks:=79;
  TotalTracks:=79;{}
  FOR Track:=0 TO TotalTracks DO BEGIN
    zxSeek(Ord(UpCase(What))-Ord('A'),Track);
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
      ReadSector(Ord(UpCase(What))-Ord('A'),Track,Head,1,16);
      if IOError=0 then
       Begin
        Colour(Blue,LightGreen);
        gotoxy(wherex-1,wherey);
        FOR Sector:=1 to 16 DO BEGIN Write(''); END;
        for i:=0 to 4095 do FDCbuf4095[i]:=FDCbuf[i];
       End
      else
       Begin
        gotoxy(wherex-1,wherey);
        FOR Sector:=1 to 16 DO BEGIN
          ReadTrackSector(What,Track,Head,Sector);
          for i:=0 to 255 do FDCbuf4095[i+256*(Sector-1)]:=FDCbuf[i];
          if IOError=27 then goto fin;
          IF IOError<>eOk THEN
           BEGIN
            cmprint(Blue,LightRed,50,wherey,ErrorStr(IOError));
            inc(bads);
            inc(In1HeadErr);
            if (track>79)and(IOError=eUnknownError) then inc(up80err);
            error:=true;
            if up80err>3 then begin Out:=true; break; end;
            if In1HeadErr>15 then begin Out:=true; break; end;
           END;
          IF keypressed THEN BEGIN key:=readkey; if key=kb_ESC then goto fin; END;
        END;
       End;
     WriteLn;
     if (up80err<=3){and(In1HeadErr<=15){} then Write(FF,FDCBuf4095){};{}
     for i:=0 to 4095 do FDCbuf4095[i]:=0;
     for i:=0 to 4095 do FDCbuf[i]:=0;
     if (IOError=eOk)and(not error) then
      Begin
       cmprint(Blue,White,50,wherey-1,ErrorStr(IOError));
       error:=false;
      End;
     IF keypressed THEN BEGIN key:=readkey; if key=kb_ESC then goto fin; END;
     if Out then break;
    END;
   if Out then break;
  END;
{  Message('Файл сформирован.');{}
fin:
  cmprint(Blue,White,15,20,strr(bads)+' bad sectors.');
  Close(FF); { Закрытие файла }
  fname:='~`ESC~` Cancel  ~`ENTER~` To load one more disk';
  cStatusBar(pal.bkSBarNT,pal.txtSBarNT,pal.bkSBarST,pal.txtSBarST,0,fname);
  key:=readkey;
  restscr;
  if (key=kb_ENTER){or(key=kb_SPACE){} then goto beg;
end;


{****************************************************************************}
procedure Save_TRDOS;
label
      beg,fin;
type
      TFDCbuf4095=array[0..4095] of byte;
var
      fname:string;
      bads,lastx,i:integer;
      Out,error:boolean;
      key,What:char;
      track,head,sector,
      TotalTracks,up80err,In1HeadErr:byte;
      fr:file;
      typeOfImage:byte;
      offData:longint;
      p:TPanel;
      FF: file of TFDCBuf4095;
      FDCBuf4095: TFDCBuf4095;
begin
  What:=ChooseDrive(focus,DiskMenuType,LANG,'A');
  if (What<>'A')and(What<>'B') then exit;

beg:
  CancelSB;
  Colour(7,0); sPutWin(25,halfmaxy-4,55,halfmaxy+0);
  cmCentre(7,0,halfmaxy-2,'Wait, detecting media...');
  if not InitFDD(Ord(UpCase(What))-Ord('A'),CheckMedia) then begin restscr; errormessage('No TR-DOS'); exit; end;
  restscr;
  CurOff;
  window(15,8,66,18);
  scputwin(Blue,White,13,5,67,21);
  cmcentre(Blue,White,5,' Writing TR-DOS disk ');{}
{  cmcentre(Red,White,5,' Writing TR-DOS disk ');{}
  fname:=pcndOf(focus)+TrueNameOf(focus,IndexOf(focus));
  cmprint(Blue,Yellow,15,6,TrueNameOf(focus,IndexOf(focus)));
  TypeOfImage:=fdiPanel;
  if isTRD(fname) then TypeOfImage:=trdPanel;
  if isFDD(fname) then TypeOfImage:=fddPanel;
{$I-}
  { Открытие файла }
  Case TypeOfImage of
   trdPanel: begin Assign(FF,fname); Reset(FF); end;
   fdiPanel:
    begin
     Assign(FR,fname); Reset(FR,1);
     Case focus of left: p:=lp; right: p:=rp; End;
     p.fdiMDFs(fname);
    end;
  End;
{ Writeln('Запись дискеты...');{}
  bads:=0; error:=false; up80err:=0; Out:=false;
  if LoadUp80 then TotalTracks:=82 else TotalTracks:=79;
  FOR Track:=0 TO TotalTracks DO BEGIN
    zxSeek(Ord(UpCase(What))-Ord('A'),Track);
    FOR Head:=0 TO 1 DO BEGIN
      Colour(Blue,White);
      Write('Track:');
      Colour(Blue,LightGray);
      Write(Track:2);
      Colour(Blue,White);
      Write(' Head:');
      Colour(Blue,LightGray);
      Write(Head:1,'  ');
      In1HeadErr:=0;
      for i:=0 to 4095 do FDCBuf4095[i]:=0;
      {Чтение дорожки}
      Case TypeOfImage of
       trdPanel: Read(FF,FDCBuf4095);
       fdiPanel:
        begin
         seek(FR,p.fdiRec.offData+Track*4096*2+Head*(256*16));
         blockread(FR,FDCBuf4095,256*16);
        end;
       fddPanel:
        begin
         for Sector:=1 to 16 do
          begin
           fddReadSector(fname,Track*2+Head,Sector);
           for i:=0 to 255 do FDCBuf4095[i+(Sector-1)*256]:=fddSectorBuf[i];
          end;
        end;
      End;

      for i:=0 to 4095 do FDCBuf[i]:=FDCBuf4095[i];
      WriteSector(Ord(UpCase(What))-Ord('A'),Track,Head,1,16);
      if IOError=0 then
       Begin
        Colour(Blue,LightGreen);
        gotoxy(wherex-1,wherey);
        FOR Sector:=1 to 16 DO BEGIN Write(''); END;
       End
      else
       Begin
        gotoxy(wherex-1,wherey);
        FOR Sector:=1 to 16 DO BEGIN
          WriteTrackSector(What,Track,Head,Sector);
          if IOError=27 then goto fin;
          IF IOError<>eOk THEN
           BEGIN
            cmprint(Blue,LightRed,50,wherey,ErrorStr(IOError));
            inc(bads);
            inc(In1HeadErr);
            if (track>79)and(IOError=eUnknownError) then inc(up80err);
            error:=true;
            if up80err>3 then begin Out:=true; break; end;
            if In1HeadErr>3 then begin Out:=true; break; end;
           END;
          IF keypressed THEN BEGIN key:=readkey; if key=kb_ESC then goto fin; END;
        END;
       End;

{     up80err:=0;{}
     WriteLn;
     if (IOError=eOk)and(not error) then
      Begin
       cmprint(Blue,White,50,wherey-1,ErrorStr(IOError));
       error:=false;
      End;
     Case TypeOfImage of
      trdPanel: if EOF(FF) then Out:=true;
      fdiPanel: if EOF(FR) then Out:=true;
     End;
     IF keypressed THEN BEGIN key:=readkey; if key=kb_ESC then goto fin; END;
     if Out then break;
    END;
   if Out then break;
  END;

fin:
  cmprint(Blue,White,15,20,strr(bads)+' bad sectors.');
{ Закрытие файла }
  Case TypeOfImage of
   trdPanel: Close(FF);
   fdiPanel: Close(FR);
  End;
{$I+}
if IOResult<>0 then;
fname:='~`ESC~` Cancel  ~`ENTER~` To save one more disk';
cStatusBar(pal.bkSBarNT,pal.txtSBarNT,pal.bkSBarST,pal.txtSBarST,0,fname);
key:=readkey;
restscr;
if (key=kb_ENTER){or(key=kb_SPACE){} then goto beg;
end;

{****************************************************************************}
procedure Format_TRDOS;
label fin;
var
  What: char;
  bads: integer;
  bads1t,try,proofs,t_,h_,s_,vs_,Sides,MaxTracks,interlive: byte;
  err,Verify,Tracks40,MaximumTracks,FastDisk,TRDOSFormat: boolean;
  DiskLabel: string;

procedure GetFormatParam;
begin
  Verify:=true; proofs:=3;
  Interlive:=8;
  FastDisk:=false;
  if FastDisk then Interlive:=1;
  TRDOSFormat:=true;
  DiskLabel:='ZX-DISK'; DiskLabel:=sRExpand(DiskLabel,8);
  Sides:=2;
  MaxTracks:=79;
  Tracks40:=false;
  MaximumTracks:=true;
  if Tracks40 then MaxTracks:=39;
  if MaximumTracks then MaxTracks:=82;
{  MaxTracks:=82;{}
end;

begin
  if not cQuestion('Format TR-DOS disk'#255'Are you sure?',eng) then exit;
  What:=ChooseDrive(focus,DiskMenuType,LANG,'A');
  if (What<>'A')and(What<>'B') then exit;
  CancelSB;
  Colour(7,0);
  CurOff;
  GetFormatParam;
  window(15,9,66,18);
  scputwin(Blue,White,13,5,67,22);
  cmprint(Blue,White,15,6,'Drive '+What+':');
  cmcentre(Red,White,5,' Format TR-DOS disk ');
  InitFDD(Ord(UpCase(What))-Ord('A'),false);
  bads:=0;
  for t_:=0 to MaxTracks do
   begin
    zxSeek(Ord(UpCase(What))-Ord('A'),T_);
    for h_:=0 to Sides-1 do
     begin
      Colour(Blue,White);      Write('Track:');
      Colour(Blue,LightGray);  Write(T_:2);
      Colour(Blue,White);      Write(' Head:');
      Colour(Blue,LightGray);  Write(H_:1,'  ');
      cmCentre(Blue,White,7,' Formating ');
      FormatTrackTRDOS(Ord(UpCase(What))-Ord('A'),t_,h_,TRDOSFormat,Interlive);{}
      FOR S_:=1 to 16 DO cmPrint(Blue,White,30+s_,wherey,'');
      cmPrint(Blue,White,50,wherey,ErrorStr(IOError));
      if Verify then
       Begin
        try:=proofs;
        repeat
         err:=false;
         if proofs-try>0 then cmCentre(Blue,White,7,'Checking '+strr(proofs-try+1))
                         else cmCentre(Blue,White,7,' Checking  ');
         bads1t:=0;
         for vs_:=1 to 16 do
          begin
           HobetaBug:=TRDOSFormat;
           ReadSector(Ord(UpCase(What))-Ord('A'),t_,h_,vs_,1);
            if IOError=eOk then
             begin
              cmPrint(Blue,LightGreen,30+vs_,wherey,'');
             end
            else
             begin
              cmPrint(Blue,LightRed,30+vs_,wherey,'');
              cmprint(Blue,LightRed,50,wherey,ErrorStr(IOError));
              err:=true;
              inc(bads1t);
           {  READKEY;{}
             end;
           if keypressed then if readkey=#27 then begin cmCentre(RED,White,7,' Canceled '); goto fin; end;
          end;
         dec(try);
         if err and (try>0) then
          begin
           cmCentre(Blue,White,7,' Formating ');
           FormatTrackTRDOS(Ord(UpCase(What))-Ord('A'),t_,h_,TRDOSFormat,Interlive);{}
           FOR S_:=1 to 16 DO cmPrint(Blue,White,30+s_,wherey,'');
           cmprint(Blue,White,50,wherey,ErrorStr(IOError));
          end else break;
        until try=0;
       End;
      inc(bads,bads1t);
      if keypressed then if readkey=#27 then begin cmCentre(RED,White,7,' Canceled '); goto fin; end;
      writeln;
     end;
   end;
fin:
{ записываем 9 сектор }
  cmCentre(Blue,White,7,'Saving info');
  for i:=0 to 255 do FDCBuf[i]:=0;
  FDCbuf[$E2]:=1;
  if (Sides=2)and(not Tracks40) then FDCbuf[$E3]:=$16;
  if (Sides=2)and(    Tracks40) then FDCbuf[$E3]:=$17;
  if (Sides=1)and(not Tracks40) then FDCbuf[$E3]:=$18;
  if (Sides=1)and(    Tracks40) then FDCbuf[$E3]:=$19;
  FDCbuf[$E5]:=lo(((MaxTracks+1)*Sides-1)*16);
  FDCbuf[$E6]:=hi(((MaxTracks+1)*Sides-1)*16);
  FDCbuf[$E7]:=$10;
  for i:=1 to 8 do FDCbuf[$F5+i-1]:=ord(DiskLabel[i]);
  DiskLabel:='Formatted by ZX Spectrum Navigator '+ver+' at '+CurDate+' '+CurTime;
  for i:=1 to length(DiskLabel) do FDCbuf[i]:=ord(DiskLabel[i]);
  Colour(Blue,White);
  Writeln; Write('Save disk information... ');
  zxSeek(Ord(UpCase(What))-Ord('A'),0);
  WriteSector(Ord(UpCase(What))-Ord('A'),0,0,9,1);
  writeln(ErrorStr(IOError));
  Write(bads,' bad sectors.');
  cmCentre(Blue,White,7,'   Ready   ');
  cmprint(Blue,White,15,20,'Disk was formatted.');

  readkey;
  restscr;
end;

begin
HobetaDetected:=false;
end.