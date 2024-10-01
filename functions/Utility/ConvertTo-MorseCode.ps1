function ConvertTo-MorseCode {
  <#
  .SYNOPSIS
  Converts input string to Morse Code and optionally plays it as audio.

  .DESCRIPTION
  This script/function converts input strings to Morse Code and optionally plays it as audio.
  It utilizes a dictionary mapping characters to Morse Code symbols for encoding.

  .EXAMPLE
  ConvertTo-MorseCode -String 'SOS'

  .EXAMPLE
  ConvertTo-MorseCode -String 'Call (123) 456-7689 - I Have Fallen and Cannot Get Up.' -audio

  .EXAMPLE
  ConvertTo-MorseCode -String 'abc123@p0wersh3ll.r0cks!' | Set-Clipboard

  .EXAMPLE
  ConvertTo-MorseCode -String (Get-Content ./private/MorsePlain.txt) | Out-File ./private/MorseCode.txt

  .EXAMPLE
  'abc123@p0wersh3ll.r0cks!' | ConvertTo-MorseCode -audio
  #>
  [CmdletBinding()]
  param(
    [Parameter(Mandatory, ValueFromPipeline)]
    [AllowEmptyString()]
    [string[]]$String,

    [Parameter()]
    [switch]$audio
  )

  process {
    $letterToMorse = @{
      # Upper-Case Letters
      "A" = ".-"; "B" = "-..."; "C" = "-.-."; "D" = "-.."; "E" = "."
      "F" = "..-."; "G" = "--."; "H" = "...."; "I" = ".."; "J" = ".---"
      "K" = "-.-"; "L" = ".-.."; "M" = "--"; "N" = "-."; "O" = "---"
      "P" = ".--."; "Q" = "--.-"; "R" = ".-."; "S" = "..."; "T" = "-"
      "U" = "..-"; "V" = "...-"; "W" = ".--"; "X" = "-..-"; "Y" = "-.--"
      "Z" = "--.."

      # Numbers
      "0" = "-----"; "1" = ".----"; "2" = "..---"; "3" = "...--"; "4" = "....-"
      "5" = "....."; "6" = "-...."; "7" = "--..."; "8" = "---.."; "9" = "----."

      # Symbols
      "!" = "-.-.--"; "@" = ".--.-."; "&" = ".-..."; "=" = "-...-"
      "+" = ".-.-."; "-" = "-....-"; "/" = "-..-."; "." = ".-.-.-"
      "," = "--..--"; ":" = "---..."; "(" = "-.--."; ")" = "-.--.-"
      "`'" = ".----."; "`"" = ".-..-."; "?" = "..--.."; " " = "/"
    }

    $data = @()
    $line = @()
    $String = $String.ToUpper()
    foreach ($char in $String.ToCharArray()) {
      $morseCode = $letterToMorse[[string]$char]
      $line += $morseCode
    }
    $data += $line -join (' ')

    if ($audio.IsPresent) {
      Write-Output ($data -join (' / '))
      # Initial beep
      [Console]::Beep(37, 1000)

      foreach ($d in $data.ToCharArray()) {
        switch ($d) {
          '.' { [Console]::Beep(800, 100) }
          '-' { [Console]::Beep(800, 300) }
          '/' { [Console]::Beep(37, 600) }
          ' ' { Start-Sleep -Milliseconds 600 }
          default {
            Write-Warning "Unknown char: $_"
            [Console]::Beep(2000, 1000)
          }
        }
      }
    } else {
      return $data -join (' / ')
    }
  }
}