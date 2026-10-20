; The Windows installer, built with Inno Setup 6 by CI:
;
;   iscc /DAppVersion=0.2.0 /DSourceDir=<app folder> /DOutputDir=<dir> BanglaVoiceClock.iss
;
; It installs for the current user only (no administrator prompt), into
; %LOCALAPPDATA%\Programs\Bangla Voice Clock, adds a Start menu entry, and by
; default starts the clock at sign-in through the same registry value the
; app's own "open at login" switch uses.

#ifndef AppVersion
  #define AppVersion "0.0.0"
#endif
#ifndef SourceDir
  #define SourceDir "..\..\build\windows\x64\runner\Release"
#endif
#ifndef OutputDir
  #define OutputDir "."
#endif

#define AppName "Bangla Voice Clock"
#define AppExe "BanglaVoiceClock.exe"
#define RunKey "Software\Microsoft\Windows\CurrentVersion\Run"

[Setup]
AppId={{6F1B0C52-8E0A-4C1B-9D7E-2B4A5C3D9E10}
AppName={#AppName}
AppVersion={#AppVersion}
AppVerName={#AppName} {#AppVersion}
AppPublisher=Saiful Islam
AppPublisherURL=https://github.com/saifulmd0/bangla-voice-clock
AppSupportURL=https://github.com/saifulmd0/bangla-voice-clock/issues
AppCopyright=Copyright (C) 2026 Saiful Islam
VersionInfoVersion={#AppVersion}
PrivilegesRequired=lowest
DefaultDirName={autopf}\{#AppName}
DisableProgramGroupPage=yes
DisableDirPage=yes
DisableReadyPage=yes
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
MinVersion=10.0
WizardStyle=modern
SetupIconFile=..\runner\resources\app_icon.ico
UninstallDisplayIcon={app}\{#AppExe}
UninstallDisplayName={#AppName}
OutputDir={#OutputDir}
OutputBaseFilename=BanglaVoiceClock-windows-setup
Compression=lzma2/max
SolidCompression=yes
; The [Code] section closes a running clock itself.
CloseApplications=no

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[CustomMessages]
StartAtSignIn=Start Bangla Voice Clock when I sign in to Windows
DesktopShortcut=Put a shortcut on the desktop
LaunchNow=Start Bangla Voice Clock now

[Tasks]
Name: "startup"; Description: "{cm:StartAtSignIn}"
Name: "desktopicon"; Description: "{cm:DesktopShortcut}"; Flags: unchecked

[Files]
Source: "{#SourceDir}\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{autoprograms}\{#AppName}"; Filename: "{app}\{#AppExe}"
Name: "{autodesktop}\{#AppName}"; Filename: "{app}\{#AppExe}"; Tasks: desktopicon

[Registry]
; Start at sign-in, or stop doing so when the box is cleared on an update.
Root: HKCU; Subkey: "{#RunKey}"; ValueType: string; ValueName: "{#AppName}"; ValueData: """{app}\{#AppExe}"""; Tasks: startup
Root: HKCU; Subkey: "{#RunKey}"; ValueType: none; ValueName: "{#AppName}"; Flags: deletevalue; Tasks: not startup
; Removed on uninstall, even when the app's own switch set it.
Root: HKCU; Subkey: "{#RunKey}"; ValueType: none; ValueName: "{#AppName}"; Flags: uninsdeletevalue

[Run]
Filename: "{app}\{#AppExe}"; Description: "{cm:LaunchNow}"; Flags: nowait postinstall skipifsilent

[Code]
const
  // The app's quit message; see kQuitMessage in windows/runner/native_bridge.cpp.
  QuitMessage = $8000 + 2;

// FindWindowW with no window name (a nil pointer), matching by class only.
function FindWindowByClass(ClassName: String; WindowName: Integer): HWND;
  external 'FindWindowW@user32.dll stdcall';

// Asks a running clock to quit, as its tray menu's Quit does, so its files
// can be replaced or removed; ends it if it doesn't within a few seconds.
procedure CloseRunningClock();
var
  Window: HWND;
  Waited, ResultCode: Integer;
begin
  Window := FindWindowByClass('BANGLA_VOICE_CLOCK_WINDOW', 0);
  if Window = 0 then
    Exit;
  PostMessage(Window, QuitMessage, 0, 0);
  Waited := 0;
  while (FindWindowByClass('BANGLA_VOICE_CLOCK_WINDOW', 0) <> 0) and (Waited < 5000) do
  begin
    Sleep(100);
    Waited := Waited + 100;
  end;
  if FindWindowByClass('BANGLA_VOICE_CLOCK_WINDOW', 0) <> 0 then
    Exec(ExpandConstant('{sys}\taskkill.exe'), '/f /im {#AppExe}', '',
      SW_HIDE, ewWaitUntilTerminated, ResultCode);
  // Give Windows a moment to release the files.
  Sleep(500);
end;

function PrepareToInstall(var NeedsRestart: Boolean): String;
begin
  CloseRunningClock();
  Result := '';
end;

function InitializeUninstall(): Boolean;
begin
  CloseRunningClock();
  Result := True;
end;
