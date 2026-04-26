Unit snViewer;
{$mode objfpc}{$H+}
Interface

Function IntView(fname:string):byte;

Implementation

uses RV, palette, main, Main_Ovr, UnicodeVideo;

function MaxAvail: longint;
begin MaxAvail := High(longint); end;

Var
  ScrWidth:word;
  ScrHeight:word;

{============================================================================}
Procedure WriteStr(X, Y: Word; Str: String; Attr: Byte);
Begin
  CMPrint(Attr shr 4, Attr and $0F, X+1, Y+1, Str);
End;
{============================================================================}

{============================================================================}
Function Long2Str(B: LongInt): String;
Var
  S: String;
Begin
  Str(B, S);
  Long2Str := S;
End;
{============================================================================}

Type
  PString = ^ShortString;

Type
  PStrings = ^TStrings;
  TStrings = Record
    Next, Prev: PStrings;
    Str: PString;
  End;

Type
  PText = ^TText;
  TText = Object
    Text: PStrings;
    Count: Longint;
    Constructor Init;
    Destructor Done; Virtual;
    Procedure Add(Str: String); Virtual;
    Procedure Clear; Virtual;
  End;

{============================================================================}
Constructor TText.Init;
Begin
  Text := Nil;
  Count := 0;
End;

{============================================================================}
Destructor TText.Done;
Begin
  Clear;
End;

{============================================================================}
Procedure TText.Add(Str: String);
Var
  L: PStrings;
Begin
  If MaxAvail < SizeOf(TStrings) + SizeOf(String) Then Exit;
  If Text = Nil Then
  Begin
    GetMem(Text, SizeOf(TStrings));
    GetMem(Text^.Str, Length(Str) + 1);
    Text^.Str^ := Str;
    Text^.Next := Text;
    Text^.Prev := Text^.Next;
  End
  Else
  Begin
    L := Text;
    While L^.Next <> Text Do
      L := L^.Next;
    GetMem(L^.Next, SizeOf(TStrings));
    L^.Next^.Prev := L;
    L := L^.Next;
    GetMem(L^.Str, Length(Str) + 1);
    L^.Str^ := Str;
    L^.Next := Text;
    Text^.Prev := L;
  End;
  Inc(Count);
End;

{============================================================================}
Procedure TText.Clear;
Var
  L: PStrings;
Begin
  If Text = Nil Then Exit;
  L := Text;
  L^.Prev^.Next := Nil;
  While L <> Nil Do
  Begin
    Text := L^.Next;
    FreeMem(L^.Str, Length(L^.Str^) + 1);
    FreeMem(L, SizeOf(TStrings));
    L := Text;
  End;
  Count := 0;
End;

{----------------------------------------------------------------------------}
Procedure GetTextFromFile(Var F: System.Text; T: PText);
{----------------------------------------------------------------------------}
Procedure MakeTabs(Var Str: ShortString);
{----------------------------------------------------------------------------}
Function NumTabs(Pos: SizeInt): SizeInt;
Begin
  NumTabs := 8 - ((Pos - 1) Mod 8);
End;
{----------------------------------------------------------------------------}

Var
  B: Byte;
  D: SizeInt;
Begin
  While System.Pos(#9, Str) <> 0 Do
  Begin
    D := System.Pos(#9, Str);
    Delete(Str, D, 1);
    For B := 1 To NumTabs(D) Do
      Insert(' ', Str, D);
  End;
End;
{----------------------------------------------------------------------------}

Var
  S: ShortString;
Begin
  While (Not EOF(F)) And (MaxAvail > $00000200) Do
  Begin
    ReadLn(F, S);
    MakeTabs(S);
    T^.Add(S);
  End;
End;
{----------------------------------------------------------------------------}

{============================================================================}
Procedure ViewText(T: PText; Source: String);
Var
  CurPos: Longint;
  CurStrOfs: Byte;
  CurLine: PStrings;

  ViewerX:word;
  ViewerY:word;
  ViewerHeight:word;
{----------------------------------------------------------------------------}
Procedure DrawScr;
Var
  L,J: Word;
  C: PStrings;

var s:string;

Begin
  ViewerX:= 0;
  ViewerY:= 1;
  ViewerHeight:= ScrHeight - 2;
  C := CurLine;

  cmprint(0,15,3,gMaxY-1,
    '['+strr(CurPos)+':'+strr(CurStrOfs)+']'+fill(10,#205));
  For L := 0 To ViewerHeight - 2 Do
   Begin
    If (L+CurPos)>T^.Count Then
     Begin
      For J:=L+1 to ViewerHeight-1 Do
        cmprint(0,7,2,ViewerY+J,space(ScrWidth-2));
      Exit;
     End;
    s:=Copy(C^.Str^, CurStrOfs, ScrWidth-2);
    WriteStr(ViewerX+1, ViewerY + L,
      s+space(ScrWidth-2-length(s)), $07);
    C := C^.Next;
   End;
  UpdateScreen(false);
End;

{----------------------------------------------------------------------------}
Procedure PageUp;
Var
  C: Word;
Begin
  If CurPos <= 1 Then Exit;
  If CurPos <= ViewerHeight Then
  Begin
    CurPos := 1;
    CurLine := T^.Text;
  End
  Else
  Begin
    For C := 1 To ViewerHeight - 1 Do
      CurLine := CurLine^.Prev;
    CurPos := CurPos - ViewerHeight + 1;
  End;
End;

{----------------------------------------------------------------------------}
Procedure PageDown;
Var
  C: Word;
Begin
// message(strr(CurPos+ViewerHeight-3)+'  '+strr(T^.Count));

  If (CurPos + (ViewerHeight - 2)) >= T^.Count Then Exit;
  If (CurPos + ViewerHeight * 2 - 2) >= T^.Count Then
  Begin

    CurPos := T^.Count;
    CurLine := T^.Text^.Prev;

    PageUp;
{}
                    Inc(CurPos);
                    CurLine := CurLine^.Next;
  End
  Else
  Begin
    For C := 1 To ViewerHeight - 1 Do
      CurLine := CurLine^.Next;
    CurPos := CurPos + ViewerHeight - 1;
  End;
End;
{----------------------------------------------------------------------------}
Var
  Quit: Boolean;
  Key: Word;
  l:word;
  a:integer;
  C: PStrings;
Begin
  cmprint(0,15,1,1,#201+fill(ScrWidth-2,#205)+#187);
  for l:=2 to gMaxY-2 do begin
    cmPrint(0,15,1,l,#186);
    cmPrint(0,15,ScrWidth,l,#186);
  end;
  cmprint(0,15,1,gMaxY-1,#200+fill(ScrWidth-2,#205)+#188);

  cmprint(0,15,3,1,
    '['+ChangeChar(ExtNum(strr(MaxAvail)),' ',',')+']');
  cmcentre(0,15,1,' '+source+' ');
  for l:=2 to gMaxY-2 do begin
    cmPrint(0,15,2,l,space(ScrWidth-2));
  end;
  CancelSB;
  If T^.Count = 0 Then
  Begin
    errormessage('Empty file');
    Exit;
  End;
  CurPos := 1;
  CurStrOfs := 1;
  CurLine := T^.Text;
  CurOff;
  DrawScr;
  Quit := False;
  Repeat
    Key := rKey;

    Case Key Of
     _ESC:       Quit := True;
     _Left:      If CurStrOfs > 1 Then Dec(CurStrOfs);
     _Right:     If CurStrOfs < ($FF - ScrWidth) Then Inc(CurStrOfs);
     _Down:      If (CurPos + ViewerHeight-1) <= T^.Count Then
                   Begin
                    Inc(CurPos);
                    CurLine := CurLine^.Next;
                   End;
     _Up:         If CurPos > 1 Then
                    Begin
                     Dec(CurPos);
                     CurLine := CurLine^.Prev;
                    End;
     _Home:
                   Begin
                    CurStrOfs:=1;
                   End;
     _End:
                   Begin
                    a:=0;
                    C:=CurLine;
                    for l:=CurPos to CurPos+gMaxY-4 do
                     Begin
                      if length(C^.Str^)>a then
                        a:=length(C^.Str^);
                      C := C^.Next;
                     End;
                    inc(a,3);
                    if a<integer(ScrWidth)+1 then
                      a:=ScrWidth+1;
                    CurStrOfs:=a-ScrWidth;
                   End;
     _PgDn:       PageDown;
     _PgUp:       PageUp;
     _CtrlHome:
                   Begin
                    CurStrOfs:=1;
                    CurPos := 1;
                    CurLine := T^.Text;
                   End;
     _CtrlEnd:
                   Begin
                    CurStrOfs:=1;
                    CurPos := T^.Count;
                    CurLine := T^.Text^.Prev;
                    PageUp;{}
                    Inc(CurPos);
                    CurLine := CurLine^.Next;
                   End;
    End;
    DrawScr;
  Until Quit;
End;

{============================================================================}
{============================================================================}
{============================================================================}
Function IntView(fname:string):byte;
Var
  ViewerFile: TText;
  ViewerFileName: String;
  F: System.Text;
Begin
  IntView:=0;
  ScrWidth:=gMaxX;        ScrHeight:=gMaxY;

  ViewerFile.Init;
  ViewerFileName := fname;
  Assign(F, ViewerFileName);
  filemode := fmReadShared;
  {$I-}
  Reset(F);
  {$I+}
  If IOResult = 0 Then
  Begin
    GetTextFromFile(F, @ViewerFile);
    Close(F);
  End;
  ViewText(@ViewerFile, ViewerFileName);
  ViewerFile.Done;
end;




End.