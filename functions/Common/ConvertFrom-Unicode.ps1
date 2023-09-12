Function ConvertFrom-Unicode {
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [string] $string
    )

    Begin {}

    Process {
        $string | ForEach-Object {
            [System.Text.RegularExpressions.Regex]::Unescape($_)
        }
    }

    End {}
}