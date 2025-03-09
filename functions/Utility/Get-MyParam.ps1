function Get-MyParam {
  <#
  .SYNOPSIS
  Retrieves parameter data from a JSON file within the module's private directory.

  .DESCRIPTION
  The Get-MyParam function loads and parses a JSON file named "myparam.json" located in the "private"
  subdirectory of the current module. It returns the parsed JSON data as a PSCustomObject.

  This function provides a centralized way to access configuration settings and default parameters
  for other functions within the module, eliminating the need for hardcoded values.

  .PARAMETER None
  This cmdlet doesn't accept any parameters.

  .OUTPUTS
  [PSCustomObject]
  Returns a PSCustomObject representing the parsed JSON data from the myparam.json file.

  .EXAMPLE
  $params = Get-MyParam
  $params.'New-HotKey'

  Retrieves all parameters and accesses the New-HotKey configuration section.

  .EXAMPLE
  $keyBindings = (Get-MyParam).KeyBindings
  foreach ($binding in $keyBindings) {
    # Process each key binding
  }

  Retrieves the KeyBindings section and processes each item.

  .NOTES
  If the myparam.json file is not found or cannot be parsed, the function will throw an error.

  The JSON file should be structured with top-level properties that correspond to function names
  or configuration categories within the module.
  #>
  [CmdletBinding()]
  [OutputType([PSCustomObject])]
  param ()

  begin {
    # $moduleBase = $MyInvocation.MyCommand.Module.ModuleBase
    # $filePath = Join-Path -Path $moduleBase -ChildPath "private\myparam.json"

    $moduleBase = $MyInvocation.MyCommand.Module.ModuleBase
    $filePath = Join-Path -Path $ModuleBase -ChildPath 'private/myparam.json'

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