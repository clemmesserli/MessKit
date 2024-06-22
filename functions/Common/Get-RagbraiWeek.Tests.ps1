# Test suite for Get-RagbraiWeek function
Describe "Get-RagbraiWeek Function Tests" {

  It "test_get_ragbrai_week_current_year" {
    # Get the current year
    $currentYear = (Get-Date).Year

    # Calculate the expected Ragbrai week for the current year
    $MonthNumber = '07'
    $lastDay = [datetime]::new($currentYear, $MonthNumber, [DateTime]::DaysInMonth($currentYear, $MonthNumber))
    switch ([int] $lastDay.DayOfWeek) {
      0 { [DateTime]$ragbrai = $lastDay.AddDays(-8) }
      1 { [DateTime]$ragbrai = $lastDay.AddDays(-9) }
      2 { [DateTime]$ragbrai = $lastDay.AddDays(-10) }
      3 { [DateTime]$ragbrai = $lastDay.AddDays(-11) }
      4 { [DateTime]$ragbrai = $lastDay.AddDays(-12) }
      5 { [DateTime]$ragbrai = $lastDay.AddDays(-6) }
      6 { [DateTime]$ragbrai = $lastDay.AddDays(-7) }
    }
    $expectedOutput = "$((Get-Culture).DateTimeFormat.GetMonthName((Get-Date $ragbrai).Month)) $($ragbrai.ToString("dd"))-$($ragbrai.AddDays(6).ToString("dd")), $($ragbrai.ToString("yyyy"))"

    # Run the function and check the output
    $result = Get-RagbraiWeek
    $result | Should -BeExactly $expectedOutput
  }

  It "test_get_ragbrai_week_specific_year" {
    # Define a specific year for testing
    $testYear = 2024

    # Calculate the expected Ragbrai week for the specific year
    $MonthNumber = '07'
    $lastDay = [datetime]::new($testYear, $MonthNumber, [DateTime]::DaysInMonth($testYear, $MonthNumber))
    switch ([int] $lastDay.DayOfWeek) {
      0 { [DateTime]$ragbrai = $lastDay.AddDays(-8) }
      1 { [DateTime]$ragbrai = $lastDay.AddDays(-9) }
      2 { [DateTime]$ragbrai = $lastDay.AddDays(-10) }
      3 { [DateTime]$ragbrai = $lastDay.AddDays(-11) }
      4 { [DateTime]$ragbrai = $lastDay.AddDays(-12) }
      5 { [DateTime]$ragbrai = $lastDay.AddDays(-6) }
      6 { [DateTime]$ragbrai = $lastDay.AddDays(-7) }
    }
    $expectedOutput = "$((Get-Culture).DateTimeFormat.GetMonthName((Get-Date $ragbrai).Month)) $($ragbrai.ToString("dd"))-$($ragbrai.AddDays(6).ToString("dd")), $($ragbrai.ToString("yyyy"))"

    # Run the function with the specific year and check the output
    $result = Get-RagbraiWeek -Year $testYear
    $result | Should -BeExactly $expectedOutput
  }
}