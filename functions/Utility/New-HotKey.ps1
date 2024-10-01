Function New-HotKey {
	<#
	.SYNOPSIS
		Script can be used to create your own 'Hot-Key' combinations

	.DESCRIPTION
		Script can be used to create your own 'Hot-Key' combinations to then launch a given script file

	.EXAMPLE
		New-HotKey -LinkPath "$($env:OneDrive)\Desktop\Demo1.lnk" -TargetPath "calc.exe" -IconLocation "C:\Windows\System32\calc.exe" -HotKey 'Ctrl+Alt+C'
		Creates a desktop shortcut on desktop that can be launched by double-clicking or by use of hot-key combo

		%ProgramFiles%\CyberArk\Endpoint Privilege Manager\Agent\vf_agent.exe

	.EXAMPLE
		$params = @{
			LinkPath = "$($env:OneDrive)\Desktop\Demo2.lnk"
			ScriptFile = "$($env:OneDrive)\scripts\HelloWorld.ps1"
			Description = "Display Hello World"
		}
		New-HotKey @params
		Creates a desktop shortcut that may only be double-clicked (no hot-key defined) to auto-launch 'HellowWorld.ps1' script file

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

	End {}
}