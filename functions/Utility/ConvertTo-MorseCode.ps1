function ConvertTo-MorseCode {
  <#
  .SYNOPSIS
  Converts input string to Morse Code and optionally plays it as audio.

  .DESCRIPTION
  This function converts input strings to Morse Code and optionally plays it as audio.
  It utilizes a dictionary mapping characters to Morse Code symbols for encoding.

  The function supports letters, numbers, and common punctuation. Characters not found in the
  Morse code dictionary will be ignored in the output. Empty strings are allowed but will result
  in empty output.

  .PARAMETER String
  Specifies the text string(s) to convert to Morse code. This parameter accepts an array of strings
  and can receive input from the pipeline. Empty strings are allowed but will result in empty output.
  All text is converted to uppercase before processing.

  .PARAMETER audio
  When specified, plays the Morse code as audio through the console speaker
  using different beep lengths for dots, dashes, and pauses.

  .EXAMPLE
  ConvertTo-MorseCode -String 'SOS'

  Output: ... --- ...

  .EXAMPLE
  ConvertTo-MorseCode -String 'Call (123) 456-7689 - I Have Fallen and Cannot Get Up.' -audio

  Converts text to Morse code and plays it as audio through the console speaker.

  .EXAMPLE
  ConvertTo-MorseCode -String 'abc123@p0wersh3ll.r0cks!' | Set-Clipboard

  Output: .- -... -.-. .---- ..--- ...-- .--.-. .--. ----- .-- . .-. ... .... ...-- .-.. .-.. .-.-.- .-. ----- -.-. -.- ... -.-.--

  Converts the text to Morse code and places it in the clipboard.

  .EXAMPLE
  ConvertTo-MorseCode -String (Get-Content ./private/MorsePlain.txt) | Out-File ./private/MorseCode.txt

  Reads text from a file, converts it to Morse code, and saves the output to another file.

  .EXAMPLE
  'abc123@p0wersh3ll.r0cks!' | ConvertTo-MorseCode -audio

  Demonstrates pipeline input and plays the Morse code as audio.

  .OUTPUTS
  System.String
  Returns the Morse code representation with spaces between characters
  and forward slashes between words when not using the -audio parameter.

  .NOTES
  Author: MessKit Project
  Supported characters: A-Z, 0-9, and common punctuation
  In the output, each character is separated by a space, and words are separated by forward slashes (/)
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
      'A' = '.-'; 'B' = '-...'; 'C' = '-.-.'; 'D' = '-..'; 'E' = '.'
      'F' = '..-.'; 'G' = '--.'; 'H' = '....'; 'I' = '..'; 'J' = '.---'
      'K' = '-.-'; 'L' = '.-..'; 'M' = '--'; 'N' = '-.'; 'O' = '---'
      'P' = '.--.'; 'Q' = '--.-'; 'R' = '.-.'; 'S' = '...'; 'T' = '-'
      'U' = '..-'; 'V' = '...-'; 'W' = '.--'; 'X' = '-..-'; 'Y' = '-.--'
      'Z' = '--..'

      # Numbers
      '0' = '-----'; '1' = '.----'; '2' = '..---'; '3' = '...--'; '4' = '....-'
      '5' = '.....'; '6' = '-....'; '7' = '--...'; '8' = '---..'; '9' = '----.'

      # Symbols
      '!' = '-.-.--'; '@' = '.--.-.'; '&' = '.-...'; '=' = '-...-'
      '+' = '.-.-.'; '-' = '-....-'; '/' = '-..-.'; '.' = '.-.-.-'
      ',' = '--..--'; ':' = '---...'; '(' = '-.--.'; ')' = '-.--.-'
      "`'" = '.----.'; "`"" = '.-..-.'; '?' = '..--..'; ' ' = '/'
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