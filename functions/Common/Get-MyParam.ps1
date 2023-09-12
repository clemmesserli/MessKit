Function Get-MyParam {
	[CmdletBinding()]
	Param ()

	Begin {}

	Process {
		#$ParentPath = 'C:\mygithub\MessKit'
		$ModuleBase = $MyInvocation.MyCommand.Module.ModuleBase
		$FilePath = Join-Path -Path $ModuleBase -ChildPath "private/myparam.json"

		$data = Get-Content "$FilePath" -Raw | ConvertFrom-Json
		$data
	}

	End {}
}