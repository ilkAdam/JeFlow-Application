unit Unit1;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs,
  Vcl.StdCtrls, System.UITypes;

type
  TForm1 = class(TForm)
    Button1: TButton;
    Button2: TButton;
    procedure Button1Click(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form1: TForm1;

implementation

uses
  Utility;

var
  hProcess: THandle;
  processID: Cardinal;
{$R *.dfm}

procedure TForm1.Button1Click(Sender: TObject);
begin
  RunProcess('cmd.exe /k title JeFlow - Server', SW_SHOWNORMAL, False, @processID);
  hProcess := OpenProcess(PROCESS_ALL_ACCESS, False, processID);
  //hProcess := ExecApplication('notepad.exe', '', processID); //i�e yaramad�, process bile �al��m�yor.
end;

procedure TForm1.Button2Click(Sender: TObject);
var
  handle: HWND;
begin
  handle := FindWindow(nil, 'JeFlow - Server');
  //PostMessage(handle, WM_CHAR, Ord('A'), 0);
  //GetWindowThreadProcessId(hProcess,)
  SendKey(handle, vkC, True, False, False);

end;

procedure TForm1.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  TerminateProcessByID(processID);
end;

end.

