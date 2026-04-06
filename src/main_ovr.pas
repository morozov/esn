{$O+,F+}
Unit Main_Ovr;
Interface
Uses sn_Obj;

Procedure snDone(sys:boolean);

Procedure About;
Procedure AltF10Pressed;
Procedure CtrlLPressed;
function  CQuestion (quest:string; lan:byte):boolean;
Procedure PutSmallWindow(ts:string; bs:string);

function  GetWildMask(tit,curentmask:string):string;

{Procedure DoExec(CmdStr:string; look:boolean);
{}
Procedure LocalFind;
Procedure GlobalFind;

Implementation
Uses
     crc32c,Crt, Dos, RV, Clock,
     Vars, Main, sn_Mem, Palette,
     PC, TRD;


{============================================================================}
Procedure snDone(sys:boolean);
Var PT:byte;
Begin
if not cQuestion('Exit'#255'Are you sure?',eng) then exit;

ClockExitProc;
if not sys then
 Begin
  TextAttr:=SavedAttr; FreeMemPCDirs;
  Cls;
  Colour(0,7);
  mprint(1,1,'ZX Spectrum Navigator '+ver+'E');
  mprint(1,2,'Shell for ZX Spectrum files');
  mprint(1,3,'RomanRom2, rom@sn.nnov.ru');
  GotoXY(1,4);
  CurOn;
  Halt(0);
 End;
End;



{============================================================================}
procedure About;
var y:byte;
begin
CurOff; Colour(7,15); y:=halfmaxy;
sPutWin(15,y-7,66,y+9);
cmCentre(7,15,y-5,'ZX Spectrum Navigator');

cmCentre(7,0,y-3,'Version '+ver+',');
cmCentre(7,0,y-2,'Compiled Thu, 25 Jun 2003 at 17:17:17');
cmCentre(7,15,y-0,'http://www.sn.nnov.ru');

cmCentre(7,0,y+2,'Copyright (c) 1997-2003 RomanRoms Software Co.');
cmCentre(7,0,y+3,'Russia. Nizhny Novgorod.');

cmCentre(7,0,y+5,'This product is a freeware');

cButton(pal.bkdButtonA,pal.txtdButtonA,pal.bkdButtonShadow,pal.txtdButtonShadow,
        halfmaxx-3,y+7,'   OK   ',true);


rPause;
RestScr;
end;


{============================================================================}
Procedure AltF10Pressed;
begin
if gmaxy=30 then set80x25 else set80x30; curoff; flash(off);
GlobalRedraw;
end;



{============================================================================}
Procedure CtrlLPressed;
Begin
Case focus of
 left:
   BEGIN
    if rp.PanelType<>noPanel then if rp.PanelType<>infPanel then
     Begin
      rp.clLastPanelType:=rp.PanelType;
      rp.PanelType:=infPanel;
      rp.Build('0');
      rp.Info('ci');
      Case lp.PanelType of
       pcPanel:
         BEGIN
          pcInfoPanel(left);
         END;
      End;
     End
    else
     Begin
      rp.PanelType:=rp.clLastPanelType;
      if (rp.Paneltype>=1)and(rp.Paneltype<=10) then rp.Build('012');
      reInfo('cbdnsfi');
      rePDF;
      snKernelExitCode:=21;
     End;
   END;
 right:
   BEGIN
    if lp.PanelType<>noPanel then if lp.PanelType<>infPanel then
     Begin
      lp.clLastPanelType:=lp.PanelType;
      lp.PanelType:=infPanel;
      lp.Build('0');
      lp.Info('ci');

      Case rp.PanelType of
       pcPanel:
         BEGIN
          pcInfoPanel(right);
         END;
      End;
     End
    else
     Begin
      lp.PanelType:=lp.clLastPanelType;
      if (lp.Paneltype>=1)and(lp.Paneltype<=10) then lp.Build('012');
      reInfo('cbdnsfi');
      rePDF;
      snKernelExitCode:=21;
     End;
   END;
End;
End;



{============================================================================}
{== COLOR QESTION ===========================================================}
{============================================================================}
function  CQuestion (quest:string; lan:byte):boolean;
var
   k:char;
   cm,m,a,b:integer;
   x1,x2,dx:byte;
   yes,no,s:string;
label l;
begin
CurOff;
yes:='  Yes   '; no:= '   No   ';
cm:=halfmaxy;
if length(quest)<5 then dx:=5 else dx:=0;
x1:=halfmaxx-20;
x2:=halfmaxx+21;
Colour(pal.bkdRama,pal.txtdRama); sPutWin(x1,cm-4,x2,cm+3);
cmcentre(pal.bkdRama,pal.txtdRama,cm-4,' Confirmation ');

if length(quest)<>length(without(quest,#255)) then
 begin
  CStatusLineColor(pal.bkdStatic,pal.txtdStatic,pal.txtdStatic,cm-2,copy(quest,1,pos(#255,quest)));
  CStatusLineColor(pal.bkdStatic,pal.txtdStatic,pal.txtdStatic,cm-1,copy(quest,pos(#255,quest)+1,255));
 end
else
 CStatusLineColor(pal.bkdStatic,pal.txtdStatic,pal.txtdStatic,cm-2,quest);

colour(pal.bkdRama,0);
m:=1;

l:
 if m=1 then
  begin
   cbutton(pal.bkdButtonA,pal.txtdButtonA,pal.bkdButtonShadow,pal.txtdButtonShadow,halfmaxx-9,cm+1,yes,true);
   cbutton(pal.bkdButtonNA,pal.txtdButtonNA,pal.bkdButtonShadow,pal.txtdButtonShadow,halfmaxx+3,cm+1,no,false);
  end
 else
  begin
   cbutton(pal.bkdButtonNA,pal.txtdButtonNA,pal.bkdButtonShadow,pal.txtdButtonShadow,halfmaxx-9,cm+1,yes,false);
   cbutton(pal.bkdButtonA,pal.txtdButtonA,pal.bkdButtonShadow,pal.txtdButtonShadow,halfmaxx+3,cm+1,no,true);
  end;
 k:=ReadKey;
 if k=#27 then begin CQuestion:=false; RestScr; Exit; end;
 if k=#13 then begin if m=0 then CQuestion:=false else CQuestion:=true; RestScr; Exit; end;
 if k=#0 then
  begin
   k:=ReadKey;
   if k=#77 then m:=0;
   if k=#75 then m:=1;
  end;
goto l;
end;





{============================================================================}
function GetWildMask(tit,curentmask:string):string;
var newmask:string;
begin
 colour(pal.bkdRama,pal.txtdRama);
 scputwin(pal.bkdRama,pal.txtdRama,29,halfmaxy-4,52,halfmaxy+3);
 cmcentre(pal.bkdRama,pal.txtdRama,halfmaxy-4,tit);
 colour(pal.bkdLabelNT,pal.txtdLabelNT);
 cmprint(pal.bkdInputNT,pal.txtdInputNT,32,halfmaxy-1,space(18));

 cmprint(pal.bkdLabelST,pal.txtdLabelST,33,halfmaxy-2,'Mask');
 cbutton(pal.bkdButtonA,pal.txtdButtonA,pal.bkdButtonShadow,pal.txtdButtonShadow,36,halfmaxy+1,'    OK    ',true);

 colour(pal.bkdInputNT,pal.txtdInputNT);
 curon;
 newmask:=scanf(32,halfmaxy-1,curentmask,18,18,pos('.',CurentMask)+1);
 curoff;
 restscr;
 if scanf_esc then GetWildMask:=curentmask else GetWildMask:=newmask;

end;


{============================================================================}
Procedure PutSmallWindow(ts:string; bs:string);
Begin
Colour(pal.bkdRama,pal.txtdRama);
scPutWin(pal.bkdRama,pal.txtdRama,29,halfmaxy-4,52,halfmaxy+3);
cmCentre(pal.bkdRama,pal.txtdRama,halfmaxy-4,ts);
Colour(pal.bkdLabelNT,pal.txtdLabelNT);
cButton(pal.bkdButtonA,pal.txtdButtonA,pal.bkdButtonShadow,pal.txtdButtonShadow,36,halfmaxy+1,bs,true)
End;




{============================================================================}
Procedure LocalFind;
var
    p:TPanel;
    a,kb:word;
    fname,t,s,ff:string[13];

    i:byte;
    fnd:boolean;

Label loop,fin;
Begin
Case focus of left:p:=lp; right:p:=rp; end;
 CancelSB;
 w_shadow:=false;{}
 scPutWin(pal.bkdRama,pal.txtdRama,p.posx+9,gmaxy-3,p.posx+32,gmaxy-1);
 cmprint(pal.bkdLabelST,pal.txtdLabelST,p.posx+11,gmaxy-2,'Find:');
 printself(pal.bkdInputNT,pal.txtdInputNT,p.posx+18,gmaxy-2,13);
 colour(pal.bkdInputNT,pal.txtdInputNT);
 s:='';

loop:
 cmprint(pal.bkdInputNT,pal.txtdInputNT,p.posx+18,gmaxy-2,s+space(13-length(s)));
 gotoXY(p.posx+18+length(nospace(s)),gmaxy-2);
 CurOn;

 kb:=KeyCode;
 if (kb=_ESC)or(kb=_ENTER)or(kb=_Tab) then goto fin;

 if kb=_HOME then
  Case focus of
   left:
    begin
     Case lp.PanelType of
      pcPanel:  begin lp.pcfrom:=1; lp.pcf:=1; end;
      trdPanel: begin lp.trdfrom:=1; lp.trdf:=1; end;
      fdiPanel: begin lp.fdifrom:=1; lp.fdif:=1; end;
      fddPanel: begin lp.fddfrom:=1; lp.fddf:=1; end;
      flpPanel: begin lp.flpfrom:=1; lp.flpf:=1; end;
      sclPanel: begin lp.sclfrom:=1; lp.sclf:=1; end;
      tapPanel: begin lp.tapfrom:=1; lp.tapf:=1; end;
      zxzPanel: begin lp.zxzfrom:=1; lp.zxzf:=1; end;
     End;
     lp.Inside; rePDF; s:='';
    end;
   right:
    begin
     Case rp.PanelType of
      pcPanel:  begin rp.pcfrom:=1; rp.pcf:=1; end;
      trdPanel: begin rp.trdfrom:=1; rp.trdf:=1; end;
      fdiPanel: begin rp.fdifrom:=1; rp.fdif:=1; end;
      fddPanel: begin rp.fddfrom:=1; rp.fddf:=1; end;
      flpPanel: begin rp.flpfrom:=1; rp.flpf:=1; end;
      sclPanel: begin rp.sclfrom:=1; rp.sclf:=1; end;
      tapPanel: begin rp.tapfrom:=1; rp.tapf:=1; end;
      zxzPanel: begin rp.zxzfrom:=1; rp.zxzf:=1; end;
     End;
     rp.Inside; rePDF; s:='';
    end;
  End;

 if chr(lo(kb)) in [#8] then delete(s,length(s),1);

 if (chr(lo(kb)) in [#32..'я'])and
    (hi(kb) in [0..$d,$10..$1b,$1e..$29,$2b..$35,$39]) then
  begin

   s:=s+chr(lo(kb));
   for a:=IndexOf(Focus) to p.tdirs+p.tfiles do
    begin
     if PanelTypeOf(focus)=pcPanel
       then fname:=TrueNameOf(focus,a)
       else fname:=nospaceLR(p.trdDir^[a].name)+'.'+TRDOSe3(p,a);


     t:=fill(length(fname),'?');
     for i:=1 to length(s) do t[i]:=s[i];
     fnd:=false;
     if wild(fname,t,false) then{}
      begin
       Case focus of
        left:  begin
                Case lp.PanelType of
                 pcPanel:
                  begin
                   inc(lp.pcf,abs(a-IndexOf(focus)));
                   if lp.pcf>lp.PanelHi*lp.Columns then
                    begin
                     inc(lp.pcfrom,(lp.pcf-lp.PanelHi*lp.Columns));
                     lp.pcf:=lp.PanelHi*lp.Columns;
                    end;
                  end;
                 trdPanel:
                  begin
                   inc(lp.trdf,abs(a-IndexOf(focus)));
                   if lp.trdf>lp.PanelHi*lp.Columns then
                    begin
                     inc(lp.trdfrom,(lp.trdf-lp.PanelHi*lp.Columns));
                     lp.trdf:=lp.PanelHi*lp.Columns;
                    end;
                  end;
                 fdiPanel:
                  begin
                   inc(lp.fdif,abs(a-IndexOf(focus)));
                   if lp.fdif>lp.PanelHi*lp.Columns then
                    begin
                     inc(lp.fdifrom,(lp.fdif-lp.PanelHi*lp.Columns));
                     lp.fdif:=lp.PanelHi*lp.Columns;
                    end;
                  end;
                 fddPanel:
                  begin
                   inc(lp.fddf,abs(a-IndexOf(focus)));
                   if lp.fddf>lp.PanelHi*lp.Columns then
                    begin
                     inc(lp.fddfrom,(lp.fddf-lp.PanelHi*lp.Columns));
                     lp.fddf:=lp.PanelHi*lp.Columns;
                    end;
                  end;
                 flpPanel:
                  begin
                   inc(lp.flpf,abs(a-IndexOf(focus)));
                   if lp.flpf>lp.PanelHi*lp.Columns then
                    begin
                     inc(lp.flpfrom,(lp.flpf-lp.PanelHi*lp.Columns));
                     lp.flpf:=lp.PanelHi*lp.Columns;
                    end;
                  end;
                 sclPanel:
                  begin
                   inc(lp.sclf,abs(a-IndexOf(focus)));
                   if lp.sclf>lp.PanelHi*lp.Columns then
                    begin
                     inc(lp.sclfrom,(lp.sclf-lp.PanelHi*lp.Columns));
                     lp.sclf:=lp.PanelHi*lp.Columns;
                    end;
                  end;
                 tapPanel:
                  begin
                   inc(lp.tapf,abs(a-IndexOf(focus)));
                   if lp.tapf>lp.PanelHi*lp.Columns then
                    begin
                     inc(lp.tapfrom,(lp.tapf-lp.PanelHi*lp.Columns));
                     lp.tapf:=lp.PanelHi*lp.Columns;
                    end;
                  end;
                 zxzPanel:
                  begin
                   inc(lp.zxzf,abs(a-IndexOf(focus)));
                   if lp.zxzf>lp.PanelHi*lp.Columns then
                    begin
                     inc(lp.zxzfrom,(lp.zxzf-lp.PanelHi*lp.Columns));
                     lp.zxzf:=lp.PanelHi*lp.Columns;
                    end;
                  end;
                End;
                lp.Inside;
               end;
        right: begin
                Case rp.PanelType of
                 pcPanel:
                  begin
                   inc(rp.pcf,abs(a-IndexOf(focus)));
                   if rp.pcf>rp.PanelHi*rp.Columns then
                    begin
                     inc(rp.pcfrom,(rp.pcf-rp.PanelHi*rp.Columns));
                     rp.pcf:=rp.PanelHi*rp.Columns;
                    end;
                  end;
                 trdPanel:
                  begin
                   inc(rp.trdf,abs(a-IndexOf(focus)));
                   if rp.trdf>rp.PanelHi*rp.Columns then
                    begin
                     inc(rp.trdfrom,(rp.trdf-rp.PanelHi*rp.Columns));
                     rp.trdf:=rp.PanelHi*rp.Columns;
                    end;
                  end;
                 fdiPanel:
                  begin
                   inc(rp.fdif,abs(a-IndexOf(focus)));
                   if rp.fdif>rp.PanelHi*rp.Columns then
                    begin
                     inc(rp.fdifrom,(rp.fdif-rp.PanelHi*rp.Columns));
                     rp.fdif:=rp.PanelHi*rp.Columns;
                    end;
                  end;
                 fddPanel:
                  begin
                   inc(rp.fddf,abs(a-IndexOf(focus)));
                   if rp.fddf>rp.PanelHi*rp.Columns then
                    begin
                     inc(rp.fddfrom,(rp.fddf-rp.PanelHi*rp.Columns));
                     rp.fddf:=rp.PanelHi*rp.Columns;
                    end;
                  end;
                 flpPanel:
                  begin
                   inc(rp.flpf,abs(a-IndexOf(focus)));
                   if rp.flpf>rp.PanelHi*rp.Columns then
                    begin
                     inc(rp.flpfrom,(rp.flpf-rp.PanelHi*rp.Columns));
                     rp.flpf:=rp.PanelHi*rp.Columns;
                    end;
                  end;
                 sclPanel:
                  begin
                   inc(rp.sclf,abs(a-IndexOf(focus)));
                   if rp.sclf>rp.PanelHi*rp.Columns then
                    begin
                     inc(rp.sclfrom,(rp.sclf-rp.PanelHi*rp.Columns));
                     rp.sclf:=rp.PanelHi*rp.Columns;
                    end;
                  end;
                 tapPanel:
                  begin
                   inc(rp.tapf,abs(a-IndexOf(focus)));
                   if rp.tapf>rp.PanelHi*rp.Columns then
                    begin
                     inc(rp.tapfrom,(rp.tapf-rp.PanelHi*rp.Columns));
                     rp.tapf:=rp.PanelHi*rp.Columns;
                    end;
                  end;
                 zxzPanel:
                  begin
                   inc(rp.zxzf,abs(a-IndexOf(focus)));
                   if rp.zxzf>rp.PanelHi*rp.Columns then
                    begin
                     inc(rp.zxzfrom,(rp.zxzf-rp.PanelHi*rp.Columns));
                     rp.zxzf:=rp.PanelHi*rp.Columns;
                    end;
                  end;
                End;
                rp.Inside;
               end;
       End;
       rePDF;
       fnd:=true;
       break;
      end;
    end;
   if not fnd then delete(s,length(s),1);
  end;
goto loop;

fin:
 w_shadow:=true;
 CurOff;
 RestScr;
End;


{============================================================================}
Procedure GlobalFind;
Begin
End;


Begin
sBar[eng,noPanel]:='~`Alt+X~` Exit';
sBar[eng,infPanel]:='~`Alt+X~` Exit';
End.