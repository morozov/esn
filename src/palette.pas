{$mode objfpc}{$H+}
Unit Palette;
Interface

Type
   TPal=record

   bkSBarNT, txtSBarNT,
   bkSBarST, txtSBarST,

   BkSelectedNT, TxtSelectedNT,
   BkSelectedST, TxtSelectedST,

   BkCurNT, TxtCurNT,
   BkCurST, TxtCurST,

   BkNDActive, TxtNDActive,
   BkNDPassive, TxtNDPassive,

   BkNameLine, TxtNameLine,

   BkNT, TxtNT,
   BkST, TxtST,

   BkRama, TxtRama,

   BkCurLine, TxtCurLine,

   BkBP, TxtBP,

   BkFreeLineNT, TxtFreeLineNT,
   BkFreeLineST, TxtFreeLineST,

   bkDiskLineNT, txtDiskLineNT,
   bkDiskLineST, txtDiskLineST,
   bkDiskLineR, txtDiskLineR,


   BkDir, txtDir,
   bkArc, txtArc,
   bkExe, txtExe,

   bkG1, txtG1,
   bkG2, txtG2,
   bkG3, txtG3,
   bkG4, txtG4,
   bkG5, txtG5,

   bkdRama,txtdRama,
   bkdInputNT, txtdInputNT,
   bkdInputST, txtdInputST,
   bkdLabelNT, txtdLabelNT,
   bkdLabelST, txtdLabelST,
   bkdStatic,  txtdStatic,
   bkdButtonNA,txtdButtonNA,
   bkdButtonA, txtdButtonA,
   bkdButtonShadow,txtdButtonShadow,

   bkdPoleNT,  txtdPoleNT,
   bkdPoleST,  txtdPoleST,

   bkDiskInfoNT, txtDiskInfoNT,
   bkDiskInfoST, txtDiskInfoST,

   bkMenuNT,      txtMenuNT,
   bkMenuST,      txtMenuST,
   bkMenuMarkNT,  txtMenuMarkNT,
   bkMenuMarkST,  txtMenuMarkST


   :byte;
   End;

Var

   Pal: TPal;


Procedure Col(ex:string; size:longint; var paper,ink:byte);
//Procedure GetPalFile;

Implementation

uses SysUtils,rv,Vars;

procedure Col(ex:string; size:longint; var paper,ink:byte);
begin
ex:=';'+ex+';';
    if pos(ex,group1)<>0 then begin paper:=pal.bkg1; ink:=pal.txtg1; end;
    if pos(ex,group2)<>0 then begin paper:=pal.bkg2; ink:=pal.txtg2; end;
    if pos(ex,group3)<>0 then begin paper:=pal.bkg3; ink:=pal.txtg3; end;
    if pos(ex,group4)<>0 then begin paper:=pal.bkg4; ink:=pal.txtg4; end;
    if pos(ex,group5)<>0 then begin paper:=pal.bkg5; ink:=pal.txtg5; end;
    if pos(ex,gexe)<>0 then begin paper:=pal.bkexe; ink:=pal.txtexe; end;

    if ex=';>P<;' then begin paper:=pal.bkexe; ink:=pal.txtexe; end;
    if (size=6912) then begin paper:=pal.bkg5; ink:=pal.txtg5; end;
    if (ex=';>B<;')and(size=6912) then begin paper:=pal.bkg5; ink:=pal.txtg5; end;

    if pos(ex,garc)<>0 then begin paper:=pal.bkarc; ink:=pal.txtarc; end;
    if LowerCase(ex)=';trd;' then begin paper:=pal.bkdir; ink:=pal.txtdir; end;
    if LowerCase(ex)=';tap;' then begin paper:=pal.bkdir; ink:=pal.txtdir; end;
    if LowerCase(ex)=';scl;' then begin paper:=pal.bkdir; ink:=pal.txtdir; end;{}
    if LowerCase(ex)=';fdi;' then begin paper:=pal.bkdir; ink:=pal.txtdir; end;
    if LowerCase(ex)=';fdd;' then begin paper:=pal.bkdir; ink:=pal.txtdir; end;
    if (LowerCase(ex)=';scr;')and(size=6912) then begin paper:=pal.bkg5; ink:=pal.txtg5; end;
    if (LowerCase(ex)=';xpc;')and(size=18432) then begin paper:=pal.bkg5; ink:=pal.txtg5; end;
    if (ex=';<C>;')and(size=6912) then begin paper:=pal.bkg5; ink:=pal.txtg5; end;
    if (ex=';<C>;')and(size=18432) then begin paper:=pal.bkg5; ink:=pal.txtg5; end;
    if (LowerCase(ex)=';$c;')and(size=6929) then begin paper:=pal.bkg5; ink:=pal.txtg5; end;
    if (LowerCase(ex)=';$c;')and(size=18449) then begin paper:=pal.bkg5; ink:=pal.txtg5; end;
end;




//procedure GetPalFile;
Begin

pal.bknameline:=1;     pal.txtnameline:=yellow;

pal.bkRama:=1;         pal.txtRama:=11;

pal.bkNT:=1;           pal.txtNT:=lightcyan;
pal.bkST:=1;           pal.txtST:=yellow;

pal.bkCurLine:=1;      pal.txtCurLine:=lightcyan;

pal.bkFreeLineNT:=1;      pal.txtFreeLineNT:=11;
pal.bkFreeLineST:=1;      pal.txtFreeLineST:=11;

pal.bkSBarNT:=3;          pal.txtSBarNT:=0;
pal.bkSBarST:=3;          pal.txtSBarST:=14;

pal.bkSelectedNT:=1;      pal.txtSelectedNT:=11;
pal.bkSelectedST:=1;      pal.txtSelectedST:=14;

pal.BkCurNT:=cyan;        pal.txtCurNT:=0;
pal.BkCurST:=cyan;        pal.txtCurST:=yellow;

pal.bkNDactive:=3;        pal.txtNDactive:=0;
pal.bkNDpassive:=1;       pal.txtNDpassive:=11;

pal.bkDiskLineNT:=1;      pal.txtDiskLineNT:=11;
pal.bkDiskLineST:=1;      pal.txtDiskLineST:=14;
pal.bkDiskLineR:=1;       pal.txtDiskLineR:=11;


pal.bkDir:=1;             pal.txtDir:=White;
pal.bkArc:=1;             pal.txtArc:=LightRed;
pal.bkExe:=1;             pal.txtExe:=LightGreen;

pal.bkG1:=1;              pal.txtG1:=11;
pal.bkG2:=1;              pal.txtG2:=LightGray;
pal.bkG3:=1;              pal.txtG3:=LightMagenta;
pal.bkG4:=1;              pal.txtG4:=11;
pal.bkG5:=1;              pal.txtG5:=Yellow;

pal.bkdRama:=7;           pal.txtdRama:=0;
pal.bkdInputNT:=3;        pal.txtdInputNT:=0;
pal.bkdInputST:=0;        pal.txtdInputST:=3;
pal.bkdLabelNT:=7;        pal.txtdLabelNT:=0;
pal.bkdLabelST:=7;        pal.txtdLabelST:=0;
pal.bkdStatic:=7;         pal.txtdStatic:=0;
pal.bkdButtonNA:=0;       pal.txtdButtonNA:=7;
pal.bkdButtonA:=3;        pal.txtdButtonA:=0;
pal.bkdButtonShadow:=7;   pal.txtdButtonShadow:=8;

pal.bkdPoleNT:=7;         pal.txtdPoleNT:=0;
pal.bkdPoleST:=7;         pal.txtdPoleST:=15;

pal.bkDiskInfoNT:=1;      pal.txtDiskInfoNT:=11;
pal.bkDiskInfoST:=1;      pal.txtDiskInfoST:=14;

pal.bkBP:=1;              pal.txtBP:=11;

pal.bkMenuNT:=3;          pal.txtMenuNT:=0;
pal.bkMenuST:=3;          pal.txtMenuST:=Yellow;
pal.bkMenuMarkNT:=0;      pal.txtMenuMarkNT:=15;
pal.bkMenuMarkST:=0;      pal.txtMenuMarkST:=Yellow;


// ClColour:=$1B;

group1:=';<A>;<H>;<a>;<T>;<X>;pas;asm;inc;c;cpp;sym;a80;db;dw;h;prj;';
group2:=';.;<d>;<W>;bbs;doc;txt;ctl;diz;ini;hlp;nfo;new;rus;me!;me;now;'+
        'frm;app;his;!!!;lst;cfg;rlz;faq;rul;log;$w;$w!;tic;hdr;lyr;!!!;'+
        'bbs;rtf;m3u;alb;sng;dis;htm;eng;en;ru;';
group3:=';<!>;<I>;<S>;<M>;<F>;<m>;mod;xm;voc;wav;s3m;mp1;mp2;mp3;mid;mtm;'+
        'dmf;ult;669;nst;wow;okt;ptm;ams;mdl;m15;cda;smp;iff;it;vqf;au;lqt;lqm;wma;aac;raw;vtx;';
group4:=';tmp;$$$;bak;swp;old;b$$;';
group5:=';<P>;<+>;<G>;<U>;<$>;<Y>;pcx;bmp;pic;gif;rle;ico;jpg;psd;raw;avi;'+
        'fli;flc;scr;tga;tif;lbm;iff;cel;bbm;pcc;pnm;pbm;pgm;ppm;png;mpe;jpe;mpg;xpc;mov;qt;xpv;';

gexe:=';exe;com;bat;<B>;';
garc:=';<Z>;zxz;$z;arj;zip;rar;lha;ha;arc;cab;$z0;$z1;$z2;$z3;$z4;$z5;$z6;$z7;$z8;$z9;';

// End;



End.
