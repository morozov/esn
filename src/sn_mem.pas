Unit sn_Mem;
{$mode objfpc}{$H+}
Interface

procedure GetMemPCDirs;
procedure FreeMemPCDirs;


Implementation
Uses
     RV,
     Vars, sn_Obj;


{===========================================================================}
procedure GetMemPCDirs;
begin
 getmem(lp.pcdir,MaxFiles*sizeof(pcDirRec));
 getmem(rp.pcdir,MaxFiles*sizeof(pcDirRec));

 getmem(lp.pcins,MaxFiles*sizeof(pcInsedRec));
 getmem(rp.pcins,MaxFiles*sizeof(pcInsedRec));


 getmem(lp.trddir,257*sizeof(zxDirRec));
 getmem(rp.trddir,257*sizeof(zxDirRec));

 getmem(lp.trdins,257*sizeof(zxInsedRec));
 getmem(rp.trdins,257*sizeof(zxInsedRec));

 getmem(lp.fdiSecOff,sizeof(TFdiSecOffMap));
 getmem(rp.fdiSecOff,sizeof(TFdiSecOffMap));

end;



{===========================================================================}
procedure FreeMemPCDirs;
begin
 freemem(lp.pcdir,MaxFiles*sizeof(pcDirRec));
 freemem(rp.pcdir,MaxFiles*sizeof(pcDirRec));

 freemem(lp.pcins,MaxFiles*sizeof(pcInsedRec));
 freemem(rp.pcins,MaxFiles*sizeof(pcInsedRec));


 freemem(lp.trddir,257*sizeof(zxDirRec));
 freemem(rp.trddir,257*sizeof(zxDirRec));

 freemem(lp.trdins,257*sizeof(zxInsedRec));
 freemem(rp.trdins,257*sizeof(zxInsedRec));

 freemem(lp.fdiSecOff,sizeof(TFdiSecOffMap));
 freemem(rp.fdiSecOff,sizeof(TFdiSecOffMap));

end;

end.