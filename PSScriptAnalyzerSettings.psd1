# PSScriptAnalyzerSettings.psd1
# Settings for PSScriptAnalyzer invocation.
@{
	ExcludeRules = @(
		'PSUseOutputTypeCorrectly',
		'PSUseShouldProcessForStateChangingFunctions',
		'PSAvoidUsingWriteHost'
	)
	Rules        = @{
		PSAvoidUsingCmdletAliases = @{
			Whitelist = @(
				'cd',
				'set-clipboard'
			)
		}

		PSPlaceCloseBrace         = @{
			Enable             = $true
			NoEmptyLineBefore  = $true
			IgnoreOneLineBlock = $true
			NewLineAfter       = $false
		}

		PSPlaceOpenBrace          = @{
			Enable             = $true
			OnSameLine         = $true
			NewLineAfter       = $true
			IgnoreOneLineBlock = $true
		}

		PSProvideCommentHelp      = @{
			Enable                  = $true
			ExportedOnly            = $false
			BlockComment            = $true
			VSCodeSnippetCorrection = $false
			Placement               = "begin"
		}

		PSUseCompatibleCommands   = @{
			Enable         = $true
			# You can specify commands to not check like this, which also will ignore its parameters:
			TargetProfiles = @(
				'win-48_x64_10.0.17763.0_5.1.17763.316_x64_4.0.30319.42000_framework', # Windows 10
				'win-8_x64_6.3.9600.0_4.0_x64_4.0.30319.42000_framework', # Windows Server 2012R2
				'win-8_x64_10.0.14393.0_5.1.14393.2791_x64_4.0.30319.42000_framework', # Windows Server 2016
				'win-8_x64_10.0.17763.0_5.1.17763.316_x64_4.0.30319.42000_framework', # Windows Server 2019
				'win-48_x64_10.0.17763.0_6.1.3_x64_4.0.30319.42000_core', # Windows 10
				'win-8_x64_10.0.14393.0_6.1.3_x64_4.0.30319.42000_core', # Windows Server 2016
				'win-8_x64_10.0.17763.0_6.1.3_x64_4.0.30319.42000_core', # Windows Server 2019
				'win-8_x64_10.0.20348.0_6.1.3_x64_4.0.30319.42000_core', # Windows Server 2022
				'win-8_x64_10.0.20348.0_5.1.20348.0_x64_4.0.30319.42000_framework', # Windows Server 2022 Desktop
				'win-48_x64_10.0.22000.0_6.1.3_x64_4.0.30319.42000_core', # Windows 11
				'win-8_x64_6.2.9200.0_4.0_x64_4.0.30319.42000_framework'  # Windows Server 2012
			)
			IgnoreCommands = @(
				'Set-Clipboard',
				'Describe',
				'It',
				'Context',
				'Should'
			)
			TargetVersions = @(
				'7.2',
				'7.1',
				'7.0',
				'5.1'
			)
		}

		PSUseCompatibleCmdlets    = @{
			'compatibility' = @(
				'core-7.0.0-windows', # PowerShell 7
				'core-7.1.0-windows', # PowerShell 7.1
				'core-7.2.0-windows', # PowerShell 7.2
				'desktop-5.1.14393.206-windows'  # Windows PowerShell 5.1
			)
		}

		PSUseCompatibleTypes      = @{
			Enable         = $true
			# Lists the PowerShell platforms we want to check compatibility with
			TargetProfiles = @(
				'win-48_x64_10.0.17763.0_5.1.17763.316_x64_4.0.30319.42000_framework', #Windows 10
				'win-8_x64_6.3.9600.0_4.0_x64_4.0.30319.42000_framework', #Windows Server 2012R2
				'win-8_x64_10.0.14393.0_5.1.14393.2791_x64_4.0.30319.42000_framework', #Windows Server 2016
				'win-8_x64_10.0.17763.0_5.1.17763.316_x64_4.0.30319.42000_framework', #Windows Server 2019
				'win-48_x64_10.0.17763.0_6.1.3_x64_4.0.30319.42000_core', #Windows 10
				'win-8_x64_10.0.14393.0_6.1.3_x64_4.0.30319.42000_core', #Windows Server 2016
				'win-8_x64_10.0.17763.0_6.1.3_x64_4.0.30319.42000_core', #Windows Server 2019
				'win-8_x64_10.0.20348.0_6.1.3_x64_4.0.30319.42000_core'  # Windows Server 2022
			)
			# You can specify commands to not check like this, which also will ignore its parameters:
			IgnoreTypes    = @(
				#'System.IO.Compression.ZipFile'
			)
		}

		PSUseCompatibleSyntax     = @{
			Enable         = $true
			TargetVersions = @(
				'7.0',
				'6.0',
				'5.1'
			)
		}

		PSUseConsistentWhitespace = @{
			Enable          = $true
			CheckInnerBrace = $true
			CheckOpenBrace  = $true
			CheckOpenParen  = $true
			CheckOperator   = $false
			CheckPipe       = $true
			CheckSeparator  = $true
		}

		PSUseCorrectCasing        = @{
			Enable    = $true
			Whitelist = @(
				'New-F5SiteBuildAWS'
			)
		}

		PSUseSingularNouns        = @{
			Enable = $true
		}
	}
}