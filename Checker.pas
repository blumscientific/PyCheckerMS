unit Unit1;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, Printers,ComCtrls;

 type
//  record type of results
   TResult = record
     name: string;//name of the chemical
     RI: string; // RI
     width: string;//width at the half peak
     net: string; // match factor
     tail: string;//tailing factor
     sign_to_noise: string;//signal to noise
     FRT: string;//factual RT
     ERT: string;//expected RT
     dRI:string; // difference in RI
     tail_min: string;//tailing factor min
     tail_max: string;//tailing factor max
     dRT:string; // difference in RT
     end;
    
  TForm1 = class(TForm)
    Edit1: TEdit;
    Label1: TLabel;
    Button1: TButton;
    Button2: TButton;
    RichEdit1: TRichEdit;
    OpenDialog1: TOpenDialog;
    Button3: TButton;
    procedure Button1Click(Sender: TObject);
    procedure ProcessFile;
    procedure Button2Click(Sender: TObject);
    procedure Button3Click(Sender: TObject);
    procedure FormShow(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form1: TForm1;
  // global variables
  Compound: array of TResult;// array of identified
  Rules: array of Tresult;  // array of corresponding criteria
   Inp1,Outp: TextFile;
   ifinal,sampletype:integer;

implementation

{$R *.dfm}
function GetDefaultPrinterName : string;
begin
   if (Printer.PrinterIndex > 0)then begin
     Result :=
       Printer.Printers
[Printer.PrinterIndex];
   end else begin
     Result := '';
   end;
end;
procedure TForm1.Button1Click(Sender: TObject);
begin
// select fin file
if opendialog1.Execute then
begin
edit1.Text:=opendialog1.FileName;
RichEdit1.Lines.Clear;
ifinal:=0;//if 0 all fir criteria
If FileExists(Edit1.text) then  ProcessFile;
end;
end;

procedure TForm1.Button2Click(Sender: TObject);
begin
Form1.Close;
end;

procedure TForm1.Button3Click(Sender: TObject);
var
prt2:string;
begin
prt2:= GetDefaultPrinterName;
if prt2 <>'' then  RichEdit1.Print(prt2)
else showmessage(' No printer is available');

end;


procedure TForm1.FormShow(Sender: TObject);
begin
If FileExists('E:\Checker\Result.txt') then DeleteFile('E:\Checker\Result.txt');
if ParamCount=0 then Button1.Visible:=True;
if ParamCount=1 then
begin
// form is not visible
// param is [file name]~[sample type]
Edit1.text:=Copy(ParamStr(1),1,Length(ParamStr(1))-2);
sampletype:= StrToInt(Copy(ParamStr(1),Length(ParamStr(1)),1));
//new report
RichEdit1.Lines.Clear;
ifinal:=0;//if 0 all fit criteria
If FileExists(Edit1.text) then
begin
ProcessFile; //if file exists, not - finished without processing
end
else
begin
AssignFile(Outp,'E:\Checker\Result.txt');
Rewrite(Outp);
Writeln(Outp,'CHECK');
CloseFile (Outp);
end;
Form1.Close;
end;
if ParamCount>1 then
begin
ShowMessage('Wrong call-should be no parameter or one parameter whis is name of file');
Form1.Close;
end;
end;
procedure TForm1.ProcessFile;
var
datype,nlines,nr,pos2,pos1,n,i,ii,icor,nid:integer;
line,adir,nmrule,ln1,solv50,solv100,low,high,stext,restext: string;
bool50,bool100:boolean;
dRT,nlow,nhigh,nsolv50,nsolv100:real;
begin
//what type is data 1-calib 2- target (datype)
// opens fin file for reading
AssignFile(Inp1,edit1.Text);
Reset(Inp1);
// looking for line Identified 16 of 16  Standards
datype:=2;
while not eof(inp1) do
begin
readln(Inp1,line);
if ((Ansipos('Identified',line) > 0) AND ((Ansipos('of 17  Standards',line) > 0) OR (Ansipos('of 16  Standards',line) > 0))) then
datype:=1;
end;
CloseFile(Inp1);
//loading criteria
// directory of application
adir:= ExtractFilePath(Application.ExeName);
// loading rules from file
if Copy(adir,length(adir),1) = '\' then
begin
if datype = 1 then nmrule:=adir+'Rules_calib.txt'
else nmrule:=adir+'Rules_target.txt';
end
else
begin
if datype = 1 then nmrule:=adir+'\Rules_calib.txt'
else nmrule:=adir+'\Rules_target.txt';
end;
// open file with rules
AssignFile(Inp1,nmrule);
Reset(Inp1);
// counting lines
nlines:=0;
while NOT EOF(Inp1) do
begin
readln(Inp1,ln1);
nlines:=Nlines+1;
end;
//reset file
Reset(Inp1);
//Initialisation of array
SetLength(Rules,nlines);
for nr:=1 to nlines do
begin
readln(Inp1,ln1);
pos2:=AnsiPos(#9,ln1)-1;
Rules[nr-1].name:=Trim(Copy(ln1,1,pos2));
ln1:=copy(ln1,pos2+2,length(ln1)-pos2);
pos2:=AnsiPos(#9,ln1)-1;
Rules[nr-1].dRI:=Trim(Copy(ln1,1,pos2));
ln1:=copy(ln1,pos2+2,length(ln1)-pos2);
pos2:=AnsiPos(#9,ln1)-1;
Rules[nr-1].dRT:=Trim(Copy(ln1,1,pos2));
ln1:=copy(ln1,pos2+2,length(ln1)-pos2);
pos2:=AnsiPos(#9,ln1)-1;
Rules[nr-1].net:=Trim(Copy(ln1,1,pos2));
ln1:=copy(ln1,pos2+2,length(ln1)-pos2);
pos2:=AnsiPos(#9,ln1)-1;
Rules[nr-1].width:=Trim(Copy(ln1,1,pos2));
ln1:=copy(ln1,pos2+2,length(ln1)-pos2);
pos2:=AnsiPos(#9,ln1)-1;
Rules[nr-1].tail_min:=Trim(Copy(ln1,1,pos2));
ln1:=copy(ln1,pos2+2,length(ln1)-pos2);
pos2:=AnsiPos(#9,ln1)-1;
Rules[nr-1].tail_max:=Trim(Copy(ln1,1,pos2));
ln1:=copy(ln1,pos2+2,length(ln1)-pos2);
Rules[nr-1].sign_to_noise:=Trim(ln1);
end;
CloseFile(Inp1);
//reading data from fin file and presenting results in RTF
//parameters of richedit
RichEdit1.Paragraph.Alignment:=taLeftJustify;
RichEdit1.Paragraph.LeftIndent:=50;
RichEdit1.Paragraph.TabCount:=7;
RichEdit1.Paragraph.Tab[1]:=220;
for i:= 2 to  7 do
RichEdit1.Paragraph.Tab[i]:=220+45*(i-1);
RichEdit1.SelAttributes.Style:=[fsBold];
RichEdit1.DefAttributes.size:=10;
RichEdit1.SelAttributes.Color:=clblack;
RichEdit1.SelText:=#9+'Processed file  '+Edit1.Text;
RichEdit1.Lines.Add('');
If datype = 1 then RichEdit1.SelText:=#9+'Data type - calibration and performance check'
else
RichEdit1.SelText:=#9+'Data type - target analysis';
RichEdit1.Lines.Add('');
RichEdit1.Lines.Add('');
// initilisation of array
// first record
SetLength(Compound,1);// its number is 0
n:=0;
// open fin file
// opens fin file for reading
AssignFile(Inp1,edit1.Text);
Reset(Inp1);
//only for calibration
if datype = 1 then
begin

solv50:='before run';
solv100:='before run';
bool50:=true;
bool100:=true;
while not eof(inp1) do
begin
readln(Inp1,line);
if Ansipos('Background (',line) =1 then
begin
readln(Inp1,line);
pos1:=Ansipos('low RT S/N',line);
pos2:=Ansipos(',',line);
low:=Copy(line,pos1+11,pos2-pos1-11);
pos1:=Ansipos('high RT S/N',line);
high:=Copy(line,pos1+12,length(line)-pos1-11);
If low ='0' then
begin
RichEdit1.SelAttributes.Color:=cllime;
RichEdit1.SelText:=#9+'Median low RT S/N of background equals zero';
 RichEdit1.Lines.Add('');
end
else
begin
nlow:=StrToFloat(low);
nhigh:=StrToFloat(high);
if nhigh/nlow <= 10 then
begin
RichEdit1.SelAttributes.Color:=cllime;
RichEdit1.SelText:=#9+'Ratio of median S/N at high RT to median S/N at low RT for background =  '+FloatTostrF((nhigh/nlow),ffFixed,2,1);
 RichEdit1.Lines.Add('');
end
else
begin
RichEdit1.SelAttributes.Color:=clred;
ifinal:=ifinal+1;
RichEdit1.SelText:=#9+'Ratio of median S/N at high RT to median S/N at low RT for background =  '+FloatTostrF((nhigh/nlow),ffFixed,2,1);
 RichEdit1.Lines.Add('');
end;
end;
end;

if Ansipos('Column Bleed',line) =1 then
begin
readln(Inp1,line);
pos1:=Ansipos('low RT S/N',line);
pos2:=Ansipos(',',line);
low:=Copy(line,pos1+11,pos2-pos1-11);
pos1:=Ansipos('high RT S/N',line);
high:=Copy(line,pos1+12,length(line)-pos1-11);
If low ='0' then
begin
RichEdit1.SelAttributes.Color:=cllime;
RichEdit1.SelText:=#9+'Median S/N at low RT  equals zero for column bleed (m/z=207)';
 RichEdit1.Lines.Add('');
end
else
begin
nlow:=StrToFloat(low);
nhigh:=StrToFloat(high);
if nhigh/nlow <= 10 then
begin
RichEdit1.SelAttributes.Color:=cllime;
RichEdit1.SelText:=#9+'Ratio of median S/N at high RT to median S/N at low RT for column bleed (m/z=207) =  '+FloatTostrF((nhigh/nlow),ffFixed,2,1);
 RichEdit1.Lines.Add('');
end
else
begin
RichEdit1.SelAttributes.Color:=clred;
ifinal:=ifinal+1;
RichEdit1.SelText:=#9+'Ratio of median S/N at high RT to median S/N at low RT for column bleed (m/z=207) =  '+FloatTostrF((nhigh/nlow),ffFixed,2,1);
 RichEdit1.Lines.Add('');
end;
end;
end;

if Ansipos('  S/N=100',line) =1 then
begin
solv100:=Copy(line,11,length(line)-10);
end;
if Ansipos('  S/N=50',line) =1 then
begin
solv50:=Copy(line,10,length(line)-9);

end;


stext:='S/N=100 '+solv100+',  S/N=50 '+solv50;
if solv100 <> 'before run' then if StrToFloat(copy(solv100,4,4))> 3.5 then bool100:=false;
if solv50 <> 'before run' then if StrToFloat(copy(solv50,4,4))> 6.0 then bool50:=false;
If ((bool50 = true) AND (bool100 = true)) then RichEdit1.SelAttributes.Color:=cllime else
begin
ifinal:=ifinal+1;
RichEdit1.SelAttributes.Color:=clred;
end;

end;
 RichEdit1.SelText:=#9+'Solvent Tailing (m/z=84):   '+stext;
RichEdit1.Lines.Add('');

end;

//reset for identified chemicals search


Reset(Inp1);
// extracting data for identified chemicals
while NOT EOF(Inp1) do
begin
readln(Inp1,line);
if Ansipos('*********************',line) =1 then
begin
//read line with data
readln(Inp1,line);
//increase size of array by one
SetLength(Compound,length(Compound)+1);
n:=n+1;
// factual retention time
pos2:=AnsiPos('|RT',line);
if pos2>0 then
begin
line:=Copy(line,pos2+3,length(line)-pos2-2);
pos1:=AnsiPos('|',line);
// retention time extraction
Compound[n].FRT:= Copy(line,1,pos1-1);
end;
// signal to noise
pos2:=AnsiPos('|SN',line);
if pos2>0 then
begin
line:=Copy(line,pos2+3,length(line)-pos2-2);
pos1:=AnsiPos('|',line);
// signal to noise extraction
Compound[n].sign_to_noise:= Copy(line,1,pos1-1);
end;
// width
pos2:=AnsiPos('|WD',line);
if pos2>0 then
begin
line:=Copy(line,pos2+3,length(line)-pos2-2);
pos1:=AnsiPos('|',line);
// width extraction,removed word scans
Compound[n].width:= Copy(line,1,pos1-7);
end;
// tailing
pos2:=AnsiPos('|TA',line);
if pos2>0 then
begin
line:=Copy(line,pos2+3,length(line)-pos2-2);
pos1:=AnsiPos('|',line);
// tailing extraction
Compound[n].tail:= Copy(line,1,pos1-1);
end;
// RI
pos2:=AnsiPos('|RI',line);
if pos2>0 then
begin
line:=Copy(line,pos2+3,length(line)-pos2-2);
pos1:=AnsiPos('|',line);
// RI extraction
Compound[n].RI:= Copy(line,1,pos1-1);
end;
// diff in RI
if datype = 1 then
begin
pos2:=AnsiPos('|RD',line);
if pos2>0 then
begin
line:=Copy(line,pos2+3,length(line)-pos2-2);
pos1:=AnsiPos('|',line);
// dif in RI extraction
Compound[n].dRI:= Copy(line,1,pos1-1);
end;
end;
//next line with name
readln(Inp1,line);
// name
pos2:=AnsiPos('|NA',line);
if pos2>0 then
begin
line:=Copy(line,pos2+3,length(line)-pos2-2);
// dif in RI extraction
Compound[n].name:= line;
end;
//next line with match factor and expected time
readln(Inp1,line);
// net match factor
pos2:=AnsiPos('|FN',line);
if pos2>0 then
begin
line:=Copy(line,pos2+3,length(line)-pos2-2);
pos1:=AnsiPos('|',line);
// net match factor extraction
Compound[n].net:= Copy(line,1,pos1-1);
end;
// expected time
pos2:=AnsiPos('|ET',line);
if pos2>0 then
begin
line:=Copy(line,pos2+3,length(line)-pos2-2);
pos1:=AnsiPos('|',line);
// expected time extraction
Compound[n].ERT:= Copy(line,1,pos1-1);
end;
if datype = 2 then
begin
pos2:=AnsiPos('|RD',line);
if pos2>0 then
begin
line:=Copy(line,pos2+3,length(line)-pos2-2);
pos1:=AnsiPos('|',line);
// dif in RI extraction
Compound[n].dRI:= Copy(line,1,pos1-1);
end;
end;
end;
end; //end of while

CloseFile(Inp1);
//evaluating against criteria and reporting


RichEdit1.Lines.Add('');



//table labels
RichEdit1.SelAttributes.Color:=clblack;
RichEdit1.SelText:=#9+'Name'+#9+'|RI diff';
If datype =2 then RichEdit1.SelText:=#9+'|RT diff';
RichEdit1.SelText:=#9+'|Net MF'+#9+'|Width'+#9+'|Tailing'+#9+'|S/N';
RichEdit1.Lines.Add('');
RichEdit1.SelText:=#9+'______________________________________________________________________';
RichEdit1.Lines.Add('');
//counting controlled identifications
nid:=0;
For i:=0 to (length(rules)-1) do
  begin

icor:=-1;
RichEdit1.SelAttributes.Color:=clblack;
RichEdit1.SelText:=#9+rules[i].name;
// finding corresponding icor from the compound
for ii:=0 to length(compound)-1 do
if AnsiPos(rules[i].name,compound[ii].name) > 0 then icor:=ii;
// if calibration compound or internal standard is not found then
If icor = -1 then
   begin
RichEdit1.SelAttributes.Color:=clred;
ifinal:=ifinal+1;
RichEdit1.SelText:=#9+' - Not found';
   end;
If icor > -1 then
   begin
   //found
   nid:=nid+1;
// RI check
If Abs(StrTofloat(compound[icor].dRI)) <= StrTofloat(rules[i].dRI) then
RichEdit1.SelAttributes.Color:=cllime
else
begin
ifinal:=ifinal+1;
RichEdit1.SelAttributes.Color:=clred;
end;
RichEdit1.SelText:=#9+'|'+compound[icor].dRI;
// RT check only for target HCB check
if datype = 2  then
begin
If Abs(StrTofloat(compound[icor].FRT)-StrTofloat(compound[icor].ERT)) <= StrTofloat(rules[i].dRT) then
RichEdit1.SelAttributes.Color:=cllime
else
begin
ifinal:=ifinal+1;
RichEdit1.SelAttributes.Color:=clred;
end;
RichEdit1.SelText:=#9+'|'+FloatToStrF((Abs(StrTofloat(compound[icor].FRT)-StrTofloat(compound[icor].ERT))),ffFixed,3,1);
end;
// Net MF check
If Abs(StrTofloat(compound[icor].net)) >= StrTofloat(rules[i].net) then
RichEdit1.SelAttributes.Color:=cllime
else
begin
ifinal:=ifinal+1;
RichEdit1.SelAttributes.Color:=clred;
end;
RichEdit1.SelText:=#9+'|'+compound[icor].net;
//width check
If Ansipos('>',compound[icor].width) > 0 then  compound[icor].width:=Copy(compound[icor].width,2,length(compound[icor].width)-1);
If Abs(StrTofloat(compound[icor].width)) <= StrTofloat(rules[i].width) then
RichEdit1.SelAttributes.Color:=cllime
else
begin
ifinal:=ifinal+1;
RichEdit1.SelAttributes.Color:=clred;
end;
RichEdit1.SelText:=#9+'|'+compound[icor].width;
//tailing check
If Ansipos('>',compound[icor].tail) > 0 then  compound[icor].tail:=Copy(compound[icor].tail,2,length(compound[icor].tail)-1);
If ((Abs(StrTofloat(compound[icor].tail)) <= StrTofloat(rules[i].tail_max)) AND (Abs(StrTofloat(compound[icor].tail)) >= StrTofloat(rules[i].tail_min))) then
RichEdit1.SelAttributes.Color:=cllime
else
begin
ifinal:=ifinal+1;
RichEdit1.SelAttributes.Color:=clred;
end;
RichEdit1.SelText:=#9+'|'+compound[icor].tail;
// S/N check
If Abs(StrTofloat(compound[icor].sign_to_noise)) >= StrTofloat(rules[i].sign_to_noise) then
RichEdit1.SelAttributes.Color:=cllime
else
begin
ifinal:=ifinal+1;
RichEdit1.SelAttributes.Color:=clred;
end;
RichEdit1.SelText:=#9+'|'+compound[icor].sign_to_noise;

   end;//icor>=1
  RichEdit1.Lines.Add('');
  end;//cycle by rules
 RichEdit1.Lines.Add('');
RichEdit1.SelAttributes.Color:=clred;
ifinal:=ifinal+1;
If (datype =1)  then stext:= 'Number of calibration/test compounds identified =  ';
If (datype =2)  then stext:= 'Number of internal standard compounds identified =  ';

If ((datype =1) AND (nid = 16)) then
begin
ifinal:=ifinal-1;
RichEdit1.SelAttributes.Color:=cllime;
end;

If ((datype =2) AND (nid = 1)) then
begin
ifinal:=ifinal-1;
RichEdit1.SelAttributes.Color:=cllime;
end;
// number of controlled compounds
RichEdit1.SelText:=#9+stext+IntTostr(nid);
//total number of identifications
RichEdit1.Lines.Add('');
RichEdit1.Lines.Add('');
RichEdit1.SelAttributes.Color:=clblack;
RichEdit1.SelText:=#9+'Total Number of identifications = '+IntTostr(length(compound)-1);

If ifinal > 0 then
begin
RichEdit1.Lines.Add('');
RichEdit1.SelAttributes.Color:=clblack;
RichEdit1.SelText:=#9+#9+#9+'CHECK';
end
else
begin
RichEdit1.Lines.Add('');
RichEdit1.SelAttributes.Color:=clblack;
RichEdit1.SelText:=#9+#9+#9+'PASS';
end;
// only for sleep mode with param call
if ParamCount=1 then
begin //only sleep mode
// file with the same name as FIN but txt

AssignFile(Outp,'E:\Checker\Result.txt');
Rewrite(Outp);

if datype =1 then
begin
if ifinal = 0 then Writeln(Outp,'PASS')
else Writeln(Outp,'CHECK')
end;

if datype =2 then
begin
restext:= 'CHECK';
if ((ifinal = 0) AND (sampletype = 1)) then restext:='PASS';
if ((ifinal = 0) AND (sampletype = 2) AND (length(compound)=2)) then restext:='PASS';
Writeln(Outp,restext);
end;



CloseFile (Outp);


end; //only sleep mode

end;

end.
