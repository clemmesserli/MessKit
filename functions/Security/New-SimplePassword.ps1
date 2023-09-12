Function New-SimplePassword {
    <#
    .SYNOPSIS
        Random Password Generator
    .DESCRIPTION
        Random Password Generator
    .EXAMPLE
        New-SimplePassword
    .EXAMPLE
        New-SimplePassword -length "12"
    #>
    [CmdletBinding()]
    Param (
        [Parameter(ValueFromPipelineByPropertyName)]
        [ValidateRange(6, 48)]
        $Length = "18"
    )

    Begin {}

    Process {
        -join ('abcdefghkmnrstuvwxyzABCDEFGHKLMNPRSTUVWXYZ23456789'.ToCharArray() | Get-Random -Count $Length)
    }

    End {}
}