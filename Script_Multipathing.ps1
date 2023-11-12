# Specify the file path
$logFilePath = "TRiiAGE_Analysis.txt"
$outputFolder = "Analysis"

# Check if the output folder exists, if not, create it
if (-not (Test-Path $outputFolder)) {
    New-Item -ItemType Directory -Path $outputFolder | Out-Null
}

# Read the content of the file
$logContent = Get-Content $logFilePath

# Define the regular expression
$pattern = "[0-9]\*\*"

# Search for the regular expression in each line of the log content
$matches = $logContent | Where-Object { $_ -match $pattern }

# Check if any matches were found
if ($matches.Count -eq 0) {
    # Output the healthy message to Analysis\Analysis.txt
    "The array is healthy and no multipathing issues found" | Out-File -FilePath "$outputFolder\analysis.txt"
    Write-Host "No multipathing issues found. Output saved to $outputFolder\analysis.txt"
} else {
    # Output the matching lines to Analysis\Evidence.txt
    $matches | Out-File -FilePath "$outputFolder\Evidence.txt"
    Write-Host "Matching lines saved to $outputFolder\Evidence.txt"

    # Create and write to Analysis\Summary-Action_Plan.txt
    $summaryContent = @"
Summary : 
We have analyzed the logs and found that Multipathing is not enabled for below Hosts :

$matches

Action plan :
-- To address multipathing issues, First need to verify the cabling connection for above hosts.
-- If the cabling is connected and still issue persists, Ask customer to go onsite to the data center to reseat/replace cable between SP and Switch/hosts.
-- If there is no cable present between the host and another SP, We need to engage the Professional Services team to do the configuration.
"@

    $summaryContent | Out-File -FilePath "$outputFolder\Summary-Action_Plan.txt"
    Write-Host "Summary saved to $outputFolder\Summary-Action_Plan.txt"
}
