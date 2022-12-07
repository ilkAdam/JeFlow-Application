unit Utility;

interface

uses
  System.Classes, Winapi.Windows, Winapi.ShellAPI, Vcl.Forms, System.SysUtils,
  Winapi.WinInet;

function RunProcess(FileName: string; ShowCmd: DWORD; wait: Boolean; ProcID: PDWORD): Longword;

function GetWindow(Handle: Cardinal; LParam: longint): bool; stdcall;

function ExecApplication(APPName, CmdLine: string; out proc_id: Cardinal): Cardinal;

function GetHandles(ThreadID: Cardinal): Cardinal;

procedure CloseMessage(process_id: Cardinal);

function RunCommandEx(const Cmd, Params: string): Cardinal;

function TerminateProcessByID(ProcessID: Cardinal): Boolean;

function CheckUrl(Url: string): boolean;

procedure SendKey(Wnd, VK: Cardinal; Ctrl, Alt, Shift: Boolean);

var
  WindowList: TList;

implementation

function RunProcess(FileName: string; ShowCmd: DWORD; wait: Boolean; ProcID: PDWORD): Longword;
var
  StartupInfo: TStartupInfo;
  ProcessInfo: TProcessInformation;
begin
  FillChar(StartupInfo, SizeOf(StartupInfo), #0);
  StartupInfo.cb := SizeOf(StartupInfo);
  StartupInfo.dwFlags := STARTF_USESHOWWINDOW or STARTF_FORCEONFEEDBACK;
  StartupInfo.wShowWindow := ShowCmd;
  if not CreateProcess(nil, @FileName[1], nil, nil, False, CREATE_NEW_CONSOLE or NORMAL_PRIORITY_CLASS, nil, nil, StartupInfo, ProcessInfo) then
    Result := WAIT_FAILED
  else
  begin
    if wait = FALSE then
    begin
      if ProcID <> nil then
        ProcID^ := ProcessInfo.dwProcessId;
      result := WAIT_FAILED;
      exit;
    end;
    WaitForSingleObject(ProcessInfo.hProcess, INFINITE);
    GetExitCodeProcess(ProcessInfo.hProcess, Result);
  end;
  if ProcessInfo.hProcess <> 0 then
    CloseHandle(ProcessInfo.hProcess);
  if ProcessInfo.hThread <> 0 then
    CloseHandle(ProcessInfo.hThread);
end;

function GetWindow(Handle: Cardinal; LParam: longint): bool; stdcall;
begin
  Result := true;
  WindowList.Add(Pointer(Handle));
end;

function ExecApplication(APPName, CmdLine: string; out proc_id: Cardinal): Cardinal;
var
  StartInfo: TStartupInfo;
  ProcInfo: TProcessInformation;
  process_id: Cardinal;
begin
  FillChar(StartInfo, SizeOf(StartInfo), 0);
  StartInfo.cb := SizeOf(StartInfo);
  StartInfo.dwFlags := STARTF_USESHOWWINDOW;
  StartInfo.wShowWindow := SW_Show;
  if APPName <> '' then
    CreateProcess(PChar(APPName), PChar(CmdLine), nil, nil, False, 0, nil, nil, StartInfo, ProcInfo);
  //Sleep(500);
  process_id := ProcInfo.dwProcessId;
  proc_id := ProcInfo.hProcess;
  Result := GetHandles(process_id);
    // CloseHandle (ProcInfo.hProcess);
  CloseHandle(ProcInfo.hThread);
end;

function GetHandles(ThreadID: Cardinal): Cardinal;
var
  i: integer;
  hnd: Cardinal;
  cpid: DWord;
begin
  Result := 0;
  WindowList := TList.Create;
  EnumWindows(@GetWindow, 0);
  for i := 0 to WindowList.Count - 1 do
  begin
    hnd := HWND(WindowList[i]);
    GetWindowThreadProcessID(hnd, @cpid);
    if ThreadID = cpid then
    begin
      Result := hnd;
      Exit;
    end;
  end;
  WindowList.Free;
end;

procedure CloseMessage(process_id: Cardinal);
var
  StatusCode: Cardinal;
begin
  if process_id > 0 then
  begin
    if GetExitCodeProcess(process_id, StatusCode) then
    begin
      if StatusCode = STILL_ACTIVE then
        TerminateProcess(process_id, StatusCode);
      CloseHandle(process_id);
    end;
  end;
end;

function RunCommandEx(const Cmd, Params: string): Cardinal;
var
  SEI: TShellExecuteInfo;
begin
  result := 0;

    //Fill record with zero byte values
  FillChar(SEI, SizeOf(SEI), 0);

    // Set mandatory record field
  SEI.cbSize := SizeOf(SEI);

    // Ask for an open process handle
  SEI.fMask := see_Mask_NoCloseProcess;

    // Tell API which window any error dialogs should be modal to
  SEI.Wnd := Application.Handle;

    //Set up command line
  SEI.lpFile := PChar(Cmd);

  if Length(Params) > 0 then
    SEI.lpParameters := PChar(Params);

  SEI.nShow := sw_ShowNormal;

    // Try and launch child process. Raise exception on failure
  if not ShellExecuteEx(@SEI) then
    Abort;

    // Wait until process has started its main message loop
  WaitForInputIdle(SEI.hProcess, Infinite);

  result := SEI.hProcess;
end;

function TerminateProcessByID(ProcessID: Cardinal): Boolean;
var
  hProcess: THandle;
begin
  Result := False;
  hProcess := OpenProcess(PROCESS_TERMINATE, False, ProcessID);
  if hProcess > 0 then
  try
    Result := Win32Check(TerminateProcess(hProcess, 0));
  finally
    CloseHandle(hProcess);
  end;
end;

function CheckUrl(Url: string): boolean;
var
  hSession, hfile, hRequest: hInternet;
  dwindex, dwcodelen: dword;
  dwcode: array[1..20] of char;
  res: pchar;
begin
  if pos('http://', lowercase(Url)) = 0 then
    Url := 'http://' + Url;
  Result := false;
  hSession := InternetOpen('InetURL:/1.0', INTERNET_OPEN_TYPE_PRECONFIG, nil, nil, 0);
  if assigned(hSession) then
  begin
    hfile := InternetOpenUrl(hSession, pchar(Url), nil, 0, INTERNET_FLAG_RELOAD, 0);
    dwindex := 0;
    dwcodelen := 10;
    HttpQueryInfo(hfile, HTTP_QUERY_STATUS_CODE, @dwcode, dwcodelen, dwindex);
    res := pchar(@dwcode);
    result := (res = '200') or (res = '302');
    if assigned(hfile) then
      InternetCloseHandle(hfile);
    InternetCloseHandle(hSession);
  end;

end;

procedure SendKey(Wnd, VK: Cardinal; Ctrl, Alt, Shift: Boolean);
var
  MC, MA, MS: Boolean;
begin
  // Try to bring target window to foreground
  ShowWindow(Wnd, SW_SHOW);
  SetForegroundWindow(Wnd);

  // Get current state of modifier keys
  MC := Hi(GetAsyncKeyState(VK_CONTROL)) > 127;
  MA := Hi(GetAsyncKeyState(VK_MENU)) > 127;
  MS := Hi(GetAsyncKeyState(VK_SHIFT)) > 127;

  // Press modifier keys if necessary (unless already pressed by real user)
  if Ctrl <> MC then
    keybd_event(VK_CONTROL, 0, Byte(MC) * KEYEVENTF_KEYUP, 0);
  if Alt <> MA then
    keybd_event(VK_MENU, 0, Byte(MA) * KEYEVENTF_KEYUP, 0);
  if Shift <> MS then
    keybd_event(VK_SHIFT, 0, Byte(MS) * KEYEVENTF_KEYUP, 0);

  // Press key
  keybd_event(VK, 0, 0, 0);
  keybd_event(VK, 0, KEYEVENTF_KEYUP, 0);

  // Release modifier keys if necessary
  if Ctrl <> MC then
    keybd_event(VK_CONTROL, 0, Byte(Ctrl) * KEYEVENTF_KEYUP, 0);
  if Alt <> MA then
    keybd_event(VK_MENU, 0, Byte(Alt) * KEYEVENTF_KEYUP, 0);
  if Shift <> MS then
    keybd_event(VK_SHIFT, 0, Byte(Shift) * KEYEVENTF_KEYUP, 0);
end;

end.
