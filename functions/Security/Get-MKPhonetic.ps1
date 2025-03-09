function Get-MKPhonetic {
  <#
  .SYNOPSIS
  Return the phonetic spelling from a list of one or more strings.

  .DESCRIPTION
  This function expands the NATO spelling alphabet to also include non-alphanumeric characters on most computer keyboards.
  It can output the phonetic spelling in multiple formats (list, JSON, raw object) or even speak it using text-to-speech.

  .PARAMETER Strings
  One or more strings to convert to phonetic spelling. Accepts pipeline input.

  .PARAMETER Output
  The output format for the phonetic spelling:
  - List: Text output showing each character and its phonetic equivalent (default)
  - Audio: Speaks the phonetic spelling using text-to-speech
  - Json: Returns a JSON representation of the phonetic spelling
  - Raw: Returns the raw PSObject

  .PARAMETER VoiceRate
  Speech rate when using Audio output. Range: -10 (very slow) to 10 (very fast). Default: 0 (normal speed).

  .PARAMETER VoiceName
  Voice to use for Audio output. Options: David (male) or Zira (female). Default: David.

  .PARAMETER VoiceVolume
  Volume level for Audio output. Range: 0 (silent) to 100 (maximum). Default: 50.

  .INPUTS
  System.String[]
  You can pipe strings to Get-MKPhonetic.

  .OUTPUTS
  System.String, System.Management.Automation.PSObject, or System.String (JSON)
  Output type depends on the -Output parameter setting.

  .NOTES
  Legal Disclaimer:
  THIS SAMPLE CODE AND ANY RELATED INFORMATION ARE PROVIDED "AS IS" WITHOUT WARRANTY OF ANY KIND,
  EITHER EXPRESSED OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE IMPLIED WARRANTIES OF MERCHANTABILITY AND/OR FITNESS FOR A PARTICULAR PURPOSE.

  .EXAMPLE
  Get-MKPhonetic -Strings "B85SZ0Oli!"

  Description: Returns the phonetic spelling of "B85SZ0Oli!" in list format.

  .EXAMPLE
  Get-MKPhonetic -Strings "B85SZ0Oli!" -Output Audio -VoiceName David -VoiceRate 2 -VoiceVolume 25

  Description: Speaks the phonetic spelling of "B85SZ0Oli!" using David's voice at a faster rate and lower volume.

  .EXAMPLE
  Get-MKPhonetic -Strings "P@ssw0rd!" -Output Json

  Description: Returns the string, length, and phonetic representation as a JSON object.

  .EXAMPLE
  $FormatEnumerationLimit = -1
  Get-MKPhonetic -Strings "P0w3rSh3!! ROcks1", "1l!|LoO0n B@$S&()" -Output Raw | Out-GridView

  Description: Processes multiple strings and displays the raw PSObject output in a grid view window.

  .EXAMPLE
  New-MKPassword -PwdLength 18 | Get-MKPhonetic

  Description: Generates a random password and returns its phonetic spelling, demonstrating pipeline input.

  .EXAMPLE
  New-GUID | Get-MKPhonetic -Output Audio

  Description: Generates a GUID and reads its phonetic spelling aloud using text-to-speech.
  #>
  [CmdletBinding()]
  param (
    [Parameter(Mandatory, ValueFromPipeline)]
    [string[]]$Strings,

    [Parameter()]
    [ValidateSet('Audio', 'List', 'Json', 'Raw')]
    [string]$Output = 'List',

    [Parameter()]
    [ValidateRange(-10, 10)]
    [int]$VoiceRate = 0,

    [Parameter()]
    [ValidateSet('David', 'Zira')]
    [string]$VoiceName = 'David',

    [Parameter()]
    [ValidateRange(0, 100)]
    [int]$VoiceVolume = 50
  )

  process {
    # Define a hashtable to store NATO mappings
    $natoMap = @{
      LowerCaseLetters = @{
        'a' = 'lower case a as in alpha'
        'b' = 'lower case b as in bravo'
        'c' = 'lower case c as in charlie'
        'd' = 'lower case d as in delta'
        'e' = 'lower case e as in echo'
        'f' = 'lower case f as in foxtrot'
        'g' = 'lower case g as in golf'
        'h' = 'lower case h as in hotel'
        'i' = 'lower case i as in india'
        'j' = 'lower case j as in juliett'
        'k' = 'lower case k as in kilo'
        'l' = 'lower case l as in lima'
        'm' = 'lower case m as in mike'
        'n' = 'lower case n as in november'
        'o' = 'lower case o as in oscar'
        'p' = 'lower case p as in papa'
        'q' = 'lower case q as in quebec'
        'r' = 'lower case r as in romeo'
        's' = 'lower case s as in sierra'
        't' = 'lower case t as in tango'
        'u' = 'lower case u as in uniform'
        'v' = 'lower case v as in victor'
        'w' = 'lower case w as in whiskey'
        'x' = 'lower case x as in x-ray'
        'y' = 'lower case y as in yankee'
        'z' = 'lower case z as in zulu'
      }
      UpperCaseLetters = @{
        'A' = 'upper case A as in Alpha'
        'B' = 'upper case B as in Bravo'
        'C' = 'upper case C as in Charlie'
        'D' = 'upper case D as in Delta'
        'E' = 'upper case E as in Echo'
        'F' = 'upper case F as in Foxtrot'
        'G' = 'upper case G as in Golf'
        'H' = 'upper case H as in Hotel'
        'I' = 'upper case I as in India'
        'J' = 'upper case J as in Juliett'
        'K' = 'upper case K as in Kilo'
        'L' = 'upper case L as in Lima'
        'M' = 'upper case M as in Mike'
        'N' = 'upper case N as in November'
        'O' = 'upper case O as in Oscar'
        'P' = 'upper case P as in Papa'
        'Q' = 'upper case Q as in Quebec'
        'R' = 'upper case R as in Romeo'
        'S' = 'upper case S as in Sierra'
        'T' = 'upper case T as in Tango'
        'U' = 'upper case U as in Uniform'
        'V' = 'upper case V as in Victor'
        'W' = 'upper case W as in Whiskey'
        'X' = 'upper case X as in X-ray'
        'Y' = 'upper case Y as in Yankee'
        'Z' = 'upper case Z as in Zulu'
      }
      Numbers          = @{
        '0' = 'number Zero'
        '1' = 'number One'
        '2' = 'number Two'
        '3' = 'number Three'
        '4' = 'number Four'
        '5' = 'number Five'
        '6' = 'number Six'
        '7' = 'number Seven'
        '8' = 'number Eight'
        '9' = 'number Nine'
      }
      Symbols          = @{
        '``'  = 'backtick'
        '~'   = 'tilde'
        '!'   = 'exclamation'
        '@'   = 'at sign'
        '#'   = 'pound'
        '`$'  = 'dollar'
        '%'   = 'percent'
        '^'   = 'carat'
        '&'   = 'ampersand'
        '<'   = 'less than'
        '>'   = 'greater than'
        '='   = 'equal'
        '+'   = 'plus'
        '-'   = 'minus'
        '*'   = 'asterisk'
        '/'   = 'forward slash'
        '\'   = 'back slash'
        '.'   = 'period'
        ','   = 'comma'
        ';'   = 'semicolon'
        ':'   = 'colon'
        '_'   = 'underscore'
        '('   = 'left parenthesis'
        ')'   = 'right parenthesis'
        '{'   = 'left curly brace'
        '}'   = 'right curly brace'
        '['   = 'left bracket'
        ']'   = 'right bracket'
        '|'   = 'pipe'
        '`''' = 'single quote'
        '`"'  = 'double quote'
        '?'   = 'question mark'
        ' '   = 'space'
      }
    }

    $phoneticList = New-Object System.Collections.Generic.List[System.Object]
    foreach ($string in $Strings) {
      #$string = 'P0w3rSh3!l'
      $natoList = New-Object System.Collections.Generic.List[System.Object]
      foreach ($char in $string.ToCharArray()) {
        switch ($char) {
          { $natoMap.LowerCaseLetters.Keys -ccontains $_ } {
            $natoList.add("$char = $($natoMap.LowerCaseLetters["$char"])")
          }
          { $natoMap.UpperCaseLetters.Keys -ccontains $_ } {
            $natoList.add("$char = $($natoMap.UpperCaseLetters["$char"])")
          }
          { $natoMap.Numbers.Keys -ccontains $_ } {
            $natoList.add("$char = $($natoMap.Numbers["$char"])")
          }
          { $natoMap.Symbols.Keys -ccontains $_ } {
            $natoList.add("$char = $($natoMap.Symbols["$char"])")
          }
          default {
            $natoList.add("$char = No mapping found")
          }
        }
        $natoHash = [PSCustomObject]@{
          String   = $string
          Length   = $string.Length
          Phonetic = $natoList
        }
      }
      $phoneticList.Add($natoHash)
    }

    switch ($Output) {
      'Audio' {
        Write-Debug "Original Input: $Strings"

        # Use the built-in "Add-Type" cmdlet to load the System.Speech assembly
        Add-Type -AssemblyName System.Speech

        # Create a SpeechSynthesizer object
        $synthesizer = New-Object System.Speech.Synthesis.SpeechSynthesizer

        # You can list available voices using: $synthesizer.GetInstalledVoices().VoiceInfo
        switch ($VoiceName) {
          'David' { $synthesizer.SelectVoice('Microsoft David Desktop') }
          'Zira' { $synthesizer.SelectVoice('Microsoft Zira Desktop') }
        }

        # The default rate is 0 (normal speed); positive values speed up, negative values slow down
        $synthesizer.Rate = $VoiceRate

        # The volume you wish to set for the speaker output.
        $synthesizer.Volume = $VoiceVolume

        # Speak the phrase after trimming off the leading '$char ='
        $synthesizer.Speak('Preparing Text to Speech')
        Start-Sleep -Milliseconds 30
        $phoneticList.phonetic | ForEach-Object {
          $synthesizer.Speak($_.Substring(3))
        }

        $synthesizer.Dispose()
      }
      'Json' {
        $phoneticList | ConvertTo-Json -Depth 1
      }
      'List' {
                ($phoneticList).phonetic
      }
      'Raw' {
        $phoneticList
      }
    }
  }
}
