function ConvertTo-TitleCase {
  <#
  .SYNOPSIS
  Converts the first letter of each word in a string to uppercase and all other letters to lowercase.

  .DESCRIPTION
  The ConvertTo-TitleCase function takes one or more strings and formats them in title case
  by converting the first letter of each word to uppercase and all other letters to lowercase.
  This function works with single strings, multiple strings, or strings received from the pipeline.

  It leverages the .NET TextInfo.ToTitleCase method which follows proper title casing rules
  for the current culture.

  .PARAMETER String
  Specifies the string(s) to convert to title case. This parameter accepts an array of strings
  and can receive input from the pipeline. Empty strings are allowed but will be returned unchanged.

  .EXAMPLE
  ConvertTo-TitleCase -String "jane doe"

  Output: Jane Doe

  .EXAMPLE
  ConvertTo-TitleCase -String "THE quick Brown FoX", "COW JUMPED OVER THE MOON!"

  Output:
  The Quick Brown Fox
  Cow Jumped Over The Moon!

  .EXAMPLE
  (Get-Content ./private/names.txt) | ConvertTo-TitleCase

  Accepts content from a file and converts each line to title case.

  .EXAMPLE
  "lowercase text" | ConvertTo-TitleCase

  Output: Lowercase Text

  .OUTPUTS
  [System.String[]]
  Returns the input string(s) in title case format.

  .NOTES
  This function properly handles empty strings and will report verbose information
  about the conversion process when -Verbose is used.
  #>
  [CmdletBinding()]
  param (
    [Parameter(Mandatory, ValueFromPipeline)]
    [AllowEmptyString()]
    [string[]]$String
  )

  process {
    $textInfo = (Get-Culture).TextInfo
    try {
      Write-Verbose "Original Text:`t $($textInfo.ToTitleCase($String))"
      $String | ForEach-Object {
        if (-not [string]::IsNullOrWhiteSpace($_)) {
          $textInfo.ToTitleCase($_.ToLower())
        }
      }
    } catch {
      Write-Error "An error occurred during the conversion process: $_"
    }
  }
}