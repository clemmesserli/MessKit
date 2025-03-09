function Convert-BinaryToText {
  <#
    .SYNOPSIS
        Converts binary files to Base64 encoded text.

    .DESCRIPTION
        This function takes a file path as input and converts the file's binary content to a Base64 encoded string.
        This is useful for embedding binary files in PowerShell scripts or for transmitting binary data as text.

    .PARAMETER Path
        The path to the binary file that needs to be converted to Base64 text.

    .EXAMPLE
        PS> $jpgBase64 = Convert-BinaryToText -Path "C:\Images\photo.jpg"
        PS> $jpgBase64
        /9j/4AAQSkZJRgABAQEAYABgAAD/2wBDAAIBAQIBAQICAgICAgICAwUDAwMDAwYEB...

    .EXAMPLE
        PS> $exeBase64 = Convert-BinaryToText -Path "C:\Program Files\MyApp\tool.exe"
        PS> # Store the Base64 string to embed in a script later
        PS> $exeBase64 | Out-File -FilePath "C:\temp\encoded_exe.txt"

    .EXAMPLE
        PS> $textBase64 = Convert-BinaryToText -Path "C:\Data\config.txt"
        PS> # The text file is also converted to Base64, even though it's already text
        PS> # This can be used for consistent handling of all file types

    .INPUTS
        None. This function does not accept pipeline input.

    .OUTPUTS
        System.String. Returns the Base64 encoded string representation of the binary file.

    .NOTES
        Author: MessKit Team
        Version: 1.0
        The output can be decoded back to binary using [System.Convert]::FromBase64String()
    #>
  [CmdletBinding()]
  Param (
    [Parameter(Mandatory)]
    [string]$Path
  )
  Process {
    #Embed binaries in PowerShell scripts
    $Bytes = [System.IO.File]::ReadAllBytes($Path)
    [System.Convert]::ToBase64String($Bytes)
  }
}