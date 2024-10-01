function Get-MyParam {
  <#
  .SYNOPSIS
  Retrieves parameter data from a JSON file within the module's private directory.

  .DESCRIPTION
  The Get-MyParam function loads and parses a JSON file named "myparam.json" located in the "private"
  subdirectory of the current module. It returns the parsed JSON data as a PSCustomObject. This function
  is designed to be used within a PowerShell module to retrieve configuration or parameter data.

  .OUTPUTS
  [PSCustomObject]
  Returns a PSCustomObject representing the parsed JSON data from the myparam.json file.

  .EXAMPLE
  $params = Get-MyParam
  $params.'New-HotKey'

  This example calls Get-MyParam and then accesses a property of the returned object.
  #>
  [CmdletBinding()]
  [OutputType([PSCustomObject])]
  param ()

  begin {
    # $moduleBase = $MyInvocation.MyCommand.Module.ModuleBase
    # $filePath = Join-Path -Path $moduleBase -ChildPath "private\myparam.json"

    $moduleBase = $MyInvocation.MyCommand.Module.ModuleBase
    $filePath = Join-Path -Path $ModuleBase -ChildPath "private/myparam.json"

  }

  process {
    try {
      $data = Get-Content -Path $filePath -Raw -ErrorAction Stop | ConvertFrom-Json
      Write-Verbose "Successfully loaded data from $filePath"
      $data
    } catch {
      $errorMessage = "Failed to load or parse data from $filePath. Error: $($_.Exception.Message)"
      throw $errorMessage
    }
  }
}