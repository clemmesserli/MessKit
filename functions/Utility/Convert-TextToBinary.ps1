function Convert-TextToBinary {
  <#
    .SYNOPSIS
        Converts Base64 encoded text back to binary files.

    .DESCRIPTION
        This function takes a Base64 encoded string and converts it back to a binary file.
        It's the counterpart to Convert-BinaryToText and is useful for recreating binary files
        that were previously encoded to Base64 strings.

    .PARAMETER Text
        The Base64 encoded string to be converted back to binary.

    .PARAMETER OutputPath
        The file path where the binary output will be saved.

    .EXAMPLE
        PS> $jpgBase64 = Convert-BinaryToText -Path "C:\Images\photo.jpg"
        PS> Convert-TextToBinary -Text $jpgBase64 -OutputPath "C:\Images\photo_copy.jpg"
        # This creates an exact copy of the original JPG file

    .EXAMPLE
        PS> # Read previously stored Base64 string
        PS> $exeBase64 = Get-Content -Path "C:\temp\encoded_exe.txt"
        PS> Convert-TextToBinary -Text $exeBase64 -OutputPath "C:\Program Files\MyApp\tool_restored.exe"
        # The executable is restored from its Base64 representation

    .EXAMPLE
        PS> $textBase64 = Convert-BinaryToText -Path "C:\Data\config.txt"
        PS> Convert-TextToBinary -Text $textBase64 -OutputPath "C:\Data\config_restored.txt"
        PS> # The text file is decoded and written to the new location

    .INPUTS
        None. This function does not accept pipeline input.

    .OUTPUTS
        None. This function does not produce output except for the file created at the specified path.

    .NOTES
        Author: MessKit Team
        Version: 1.0
        This function is the counterpart to Convert-BinaryToText.
    #>
  [CmdletBinding()]
  Param (
    [Parameter(Mandatory)]
    [string]
    $Text,

    [Parameter(Mandatory)]
    [string]
    $OutputPath
  )

  Begin {}

  Process {
    #Embed binaries in PowerShell scripts
    $Bytes = [System.Convert]::FromBase64String($Text)
    [System.IO.File]::WriteAllBytes($OutputPath, $Bytes)
  }

  End {}
}