Function New-HotKey {
  <#
    .SYNOPSIS
        Creates custom hot-key combinations for launching applications or scripts.

    .DESCRIPTION
        Creates Windows shortcuts (.lnk files) with optional keyboard hotkey combinations.
        These shortcuts can launch applications or PowerShell scripts with customizable parameters.

    .PARAMETER LinkPath
        Path where the shortcut (.lnk) file will be created.
        Defaults to value from Get-MyParam.

    .PARAMETER IconLocation
        Path to the icon file for the shortcut.
        Defaults to value from Get-MyParam.

    .PARAMETER ScriptFile
        Path to the PowerShell script file to be executed.
        Defaults to value from Get-MyParam.

    .PARAMETER HotKey
        Keyboard combination to trigger the shortcut (e.g., 'Ctrl+Alt+C').
        Defaults to value from Get-MyParam.

    .PARAMETER Description
        Description text for the shortcut.
        Defaults to value from Get-MyParam.

    .PARAMETER TargetPath
        Path to the application executable that will be launched.
        Defaults to value from Get-MyParam.

    .PARAMETER Argument
        Command-line arguments to pass to the target application.
        Defaults to value from Get-MyParam.

    .PARAMETER WorkingDirectory
        Working directory for the launched application.
        Defaults to value from Get-MyParam.

    .PARAMETER WindowStyle
        Controls how the window appears when launched:
        1 - Normal window (restored position)
        3 - Maximized window
        7 - Minimized window
        Defaults to value from Get-MyParam.

    .EXAMPLE
        New-HotKey -LinkPath "$($env:OneDrive)\Desktop\Demo1.lnk" -TargetPath "calc.exe" -IconLocation "C:\Windows\System32\calc.exe" -HotKey 'Ctrl+Alt+C'

        # Creates a desktop shortcut to launch Calculator that can be triggered by pressing Ctrl+Alt+C

    .EXAMPLE
        $params = @{
            LinkPath = "$($env:OneDrive)\Desktop\Demo2.lnk"
            ScriptFile = "$($env:OneDrive)\scripts\HelloWorld.ps1"
            Description = "Display Hello World"
        }
        New-HotKey @params

        # Creates a desktop shortcut that launches the HelloWorld.ps1 script (no hotkey defined)

    .EXAMPLE
        $params = @{
            Argument = "-noprofile -nologo -ExecutionPolicy Bypass -WindowStyle hidden -File C:\mygithub\messkit\private\CyberArkHK.ps1"
            HotKey = "Ctrl+Shift+Alt+P"
            IconLocation = "C:\Program Files\PowerShell\7\pwsh.exe"
            LinkPath = "$($env:OneDrive)\Desktop\pwsh_cv.lnk"
            TargetPath = "pwsh.exe"
            Description = "Get MySecret"
        }
        New-HotKey @params

        # Creates a shortcut that runs a PowerShell script with specific parameters when Ctrl+Shift+Alt+P is pressed
    #>
  [CmdletBinding()]
  Param (
    [string]$LinkPath = (Get-MyParam).'New-HotKey'.LinkPath,

    [string]$IconLocation = (Get-MyParam).'New-HotKey'.IconLocation,

    [string]$ScriptFile = (Get-MyParam).'New-HotKey'.ScriptFile,

    [string]$HotKey = (Get-MyParam).'New-HotKey'.HotKey,

    [string]$Description = (Get-MyParam).'New-HotKey'.Description,

    [string]$TargetPath = (Get-MyParam).'New-HotKey'.TargetPath,

    [string]$Argument = (Get-MyParam).'New-HotKey'.Argument,

    [string]$WorkingDirectory = (Get-MyParam).'New-HotKey'.WorkingDirectory,

    [ValidateSet(1, 3, 7)]
    [int]$WindowStyle = (Get-MyParam).'New-HotKey'.WindowStyle
  )

  Begin {
    Write-Debug "ScriptFile: $ScriptFile"
    Write-Debug "LinkPath: $LinkPath"
    Write-Debug "Argument: $Argument"
  }

  Process {
    # Create Windows PowerShell COM Object
    $wshell = New-Object -ComObject WScript.Shell

    #region List available methods
    <#
        $wshell | Get-Member -MemberType methods

        Name                     MemberType Definition
        ----                     ---------- ----------
        AppActivate              Method     bool AppActivate (Variant App, Variant Wait)
        CreateShortcut           Method     IDispatch CreateShortcut (string PathLink)
        Exec                     Method     IWshExec Exec (string Command)
        ExpandEnvironmentStrings Method     string ExpandEnvironmentStrings (string Src)
        LogEvent                 Method     bool LogEvent (Variant Type, string Message, string Target)
        Popup                    Method     int Popup (string Text, Variant SecondsToWait, Variant Title, Variant Type)
        RegDelete                Method     void RegDelete (string Name)
        RegRead                  Method     Variant RegRead (string Name)
        RegWrite                 Method     void RegWrite (string Name, Variant Value, Variant Type)
        Run                      Method     int Run (string Command, Variant WindowStyle, Variant WaitOnReturn)
        SendKeys                 Method     void SendKeys (string Keys, Variant Wait)
        #>
    #endregion List available methods

    $lnk = $wshell.CreateShortcut("$($LinkPath)")

    #region Member property info
    <#
        $lnk | Get-Member -MemberType Properties

        Name             MemberType Definition
        ----             ---------- ----------
        Arguments        Property   string Arguments () {get} {set}
        Description      Property   string Description () {get} {set}
        FullName         Property   string FullName () {get}
        Hotkey           Property   string Hotkey () {get} {set}
        IconLocation     Property   string IconLocation () {get} {set}
        RelativePath     Property   string RelativePath () {set}
        TargetPath       Property   string TargetPath () {get} {set}
        WindowStyle      Property   int WindowStyle () {get} {set}
            1 - Activates and displays a window. If the window is minimized or maximized, the system restores it to its original size and position.
            3 - Activates the window and displays it as a maximized window.
            7 - Minimizes the window and activates the next top-level window.
        WorkingDirectory Property   string WorkingDirectory () {get} {set}
        #>
    #endregion Member property info

    $lnk.TargetPath = $TargetPath
    $lnk.WorkingDirectory = $WorkingDirectory
    $lnk.WindowStyle = $WindowStyle
    if ( ($null -ne $Argument) -and ('' -ne $Argument) ) { $lnk.Arguments = $Argument }
    if ( ($null -ne $HotKey) -and ('' -ne $HotKey) ) { $lnk.Hotkey = $HotKey }
    if ( ($null -ne $IconLocation) -and ('' -ne $IconLocation) ) { $lnk.IconLocation = $IconLocation }
    if ( ($null -ne $Description) -and ('' -ne $Description) ) { $lnk.Description = $Description }
    $lnk.Save()
  }
}