param(
    [string]$ConfigPath = "$PSScriptRoot\data\config\config.json",
    [string]$OutputFormat = "",
    [switch]$NoLog
)

$scriptStartTime = Get-Date

$config = $null
$logger = $null

Function Initialize-Logger {
    param(
        [PSCustomObject]$LogConfig
    )

    $logLevel = $LogConfig.logLevel
    $logToFile = $LogConfig.logToFile
    $logToConsole = $LogConfig.logToConsole
    $logDir = Join-Path $PSScriptRoot -ChildPath $config.filePaths.logDirectory
    $maxLogFileSizeMB = $LogConfig.maxLogFileSizeMB
    $maxLogFiles = $LogConfig.maxLogFiles

    if ($logToFile -and -not (Test-Path $logDir)) {
        New-Item -Path $logDir -ItemType Directory -Force | Out-Null
    }

    $logger = @{
        LogLevel = $logLevel
        LogToFile = $logToFile
        LogToConsole = $logToConsole
        LogDirectory = $logDir
        LogFile = if ($logToFile) { Join-Path $logDir "Checklist_Parser_$(Get-Date -Format 'yyyyMMdd').log" } else { $null }
        MaxLogFileSizeMB = $maxLogFileSizeMB
        MaxLogFiles = $maxLogFiles
    }

    return $logger
}

Function Write-Log {
    param(
        [string]$Message,
        [string]$Level = "INFO",
        [string]$Component = "Main"
    )

    if ($NoLog) { return }

    if (-not $logger) {
        Write-Host "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] [$Level] [$Component] $Message" -ForegroundColor White
    }

    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] [$Level] [$Component] $Message"

    $levels = @{ "DEBUG" = 1; "INFO" = 2; "WARN" = 3; "ERROR" = 4 }
    $currentLevel = $levels[$logger.LogLevel]
    $messageLevel = $levels[$Level]

    if ($messageLevel -ge $currentLevel) {
        if ($logger.LogToConsole) {
            $color = switch ($Level) {
                "DEBUG" { "DarkGray" }
                "INFO" { "White" }
                "WARN" { "Yellow" }
                "ERROR" { "Red" }
                default { "White" }
            }

            Write-Host $logEntry -ForegroundColor $color
        }

        if ($logger.LogToFile -and $logger.LogFile) {
            try {
                if ( (Test-Path $logger.LogFile) -and ((Get-Item $logger.LogFile).Length -gt ($logger.MaxLogFileSizeMB * 1MB)) ) {
                    $logFileBase = [System.IO.Path]::GetFileNameWithoutExtension($logger.LogFile)
                    $logFileExt = [System.IO.Path]::GetExtension($logger.LogFile)
                    $logFileDir = [System.IO.Path]::GetDirectoryName($logger.LogFile)

                    $existingLogs = Get-Childitem -Path $logFileDir -Filter "$logFileBase*$logFileExt" | Sort-Object LastWriteTime -Descending

                    if ($existingLogs.Count -ge $logger.MaxLogFiles) {
                        Remove-Item $existingLogs[-1].FullName -Force
                    }

                    $newLogFile = Join-Path $logFileDir "$logFileBase`_$(Get-Date -Format 'yyyyMMdd_HHmmss')$logFileExt"
                    Move-Item $logger.LogFile $newLogFile
                    
                }
                Add-Content -Path $logger.LogFile -Value $logEntry -ErrorAction SilentlyContinue
                
            }
            catch {
                Write-Host "Failed to write log entry to file: $($_.Exception.Message)" -ForegroundColor Yellow
            }
        }
    }
}

Function Read-Configuration {
    param(
        [string]$ConfigPath
    )

    try {
        if (-not(Test-Path $ConfigPath)) {
            throw "Configuration file not found: $ConfigPath"
        }

        $configContent = Get-Content $ConfigPath -Raw -ErrorAction Stop
        $config = $configContent | ConvertFrom-Json -ErrorAction Stop

        return $config
    }
    catch {
        throw "Failed to load configuration: $_.Exception.Message"
    }
}

Function Export-Results {
    param(
        [array]$Data,
        [string]$OutputDirectory,
        [array]$Formats,
        [bool]$IncludeTimestamp
    )

    $timestamp = if ($IncludeTimestamp) { "$(Get-Date -Format 'yyyy-MM-dd HHmmss')" } else { "" }
    if (-not($baseFileName)) {
        $baseFileName = "parsedResults$timestamp"
    }
    else {
        $baseFileName = $baseFileName + $timestamp
    }
    
    $OutputDirectory = Join-Path $PSScriptRoot -ChildPath $OutputDirectory

    if (-not (Test-Path $OutputDirectory)) {
        New-Item -Path $OutputDirectory -ItemType Directory -Force | Out-Null
        Write-Log -Level "INFO" -Component "Export-Results" -Message "Created output directory: $OutputDirectory"
    }

    ForEach ($Format in $Formats) {
        try {
            switch ($format.ToUpper()) {
                "CSV" {
                    $csvPath = Join-Path $OutputDirectory "$($baseFileName).csv"
                    $Data | Export-Csv -Path $csvPath -NoTypeInformation -Encoding UTF8
                    Write-Log -Level "INFO" -Component "Export-Results" -Message "Exported results to CSV: $csvPath"
                }
                "JSON" {
                    $jsonPath = Join-Path $OutputDirectory "$($baseFileName).json"
                    $Data | ConvertTo-Json | Out-File -FilePath $jsonPath -Encoding UTF8
                    Write-Log -Level "INFO" -Component "Export-Results" -Message "Exported results to JSON: $jsonPath"
                }
                default {
                    Write-Log -Level "ERROR" -Component "Export-Results" -Message "Unsupported output format: $format"
                }
            }
        }
        catch {
            Write-Log -Level "ERROR" -Component "Export-Results" -Message "Failed to export results: $($_.Exception.Message)"
        }
    }
}

try {
    
    # Main Entry Point
    
    $config = Read-Configuration -ConfigPath $ConfigPath
    $logger = Initialize-Logger -LogConfig $config.logging

    Write-Log -Level "INFO" -Component "Main" -Message "Starting Checklist Parser Script Version: $($config.Version)"
    Write-Log -Level "INFO" -Component "Main" -Message "Reading configuration from $ConfigPath"
    Write-Log -Level "INFO" -Component "Main" -Message "Log Directory: $($logger.LogDirectory)"
    Write-Log -Level "INFO" -Component "Main" -Message "Log File: $($logger.LogFile)"

    Write-Log -Level "INFO" -Component "Import" -Message "Reading checklist files from $($config.filePaths.checklistDirectory)"
    

    If (Test-Path -Path $config.filePaths.checklistDirectory -ErrorAction SilentlyContinue) {
        $Files = $(Get-ChildItem -Path $config.filePaths.checklistDirectory -File -Recurse | Where-Object { $_.Extension -match "ckl|cklb" }).FullName
    }
    ElseIf (Test-Path -Path $(Join-Path $PSScriptRoot -Childpath $config.filePaths.checklistDirectory)) {
        $Files = $(Get-ChildItem -Path $(Join-Path $PSScriptRoot -Childpath $config.filePaths.checklistDirectory) -File -Recurse | Where-Object { $_.Extension -match "ckl|cklb" }).FullName
    }


    If ($Files.Count -eq 0) {
        Write-Log -Level "WARN" -Component "Import" -Message "No checklist files found in $($config.filePaths.checklistDirectory)"
        Break
    }

    $summary = @()

    ForEach ($File in $Files) {

        If ($File.EndsWith(".cklb")) {
            
            $json = Get-Content $File | ConvertFrom-Json
            $hostname = $json.Target_Data.Host_Name
            $ip = $json.Target_Data.IP_Address
            
            $rules = @()

            ForEach ( $rule in $json.stigs.rules ) {
                $rules += [PSCustomObject]@{
                    Status = $rule.Status
                    Comments = $rule.comments
                    FindingDetails = $rule.Finding_Details
                    VulnID = $rule.group_id
                    Title = $rule.group_title
                    Discussion = $rule.discussion
                    Check = $rule.check_content
                    FixText = $rule.fix_text
                    STIG = $($json.stig.stig_name + "::" + $json.stig.release_info)
                    Weight = $rule.weight
                    RuleID = $rule.rule_id
                    STIGID = $rule.rule_version
                    Severity = $rule.severity
                    HostName = $hostname
                    IP = $ip
                    IS = "3848"
                    "CKL/CKLB" = "CKLB"
                }
            }

            $summary += $rules | WHere-Object { $_.Status -match "Open"} | Select-Object STIG, STIGID, RuleID, VulnID, Title, Discussion, Check, FixText, Severity, Status, FindingDetails, Comments, IS, HostName, IP, "CKL/CKLB"

            Write-Log -Level "INFO" -Component "JSON Parse" -Message "Parsed $($file | Split-Path -Leaf)"

            Continue
        }
        ElseIf ( $File.EndsWith(".ckl") ) {
            $xml = [xml](Get-Content $File)
            $ns = $xml.DocumentElement.NamespaceURI
            $nsm = New-Object System.Xml.XmlNamespaceManager($xml.NameTable)
            $nsm.AddNamespace('ns', $ns)
            $items = $xml.SelectNodes("//ns:VULN", $nsm)

            $rules = @()
            
            If($null -notmatch $xml.CHECKLIST.ASSET.HOST_NAME) {
                $hostName = $xml.CHECKLIST.ASSET.HOST_NAME
            }
            If ($null -notmatch $xml.CHECKLIST.ASSET.HOST_IP) {
                $hostIP = $xml.CHECKLIST.ASSET.HOST_IP
            }

            ForEach ($item in $items) {

                $hash = @{}
    
                ForEach ($attr in $item.STIG_DATA) {
                    $hash["$($attr.VULN_ATTRIBUTE)"] = "$($attr.ATTRIBUTE_DATA)"
                }
    
                $rule = [PSCustomObject]@{
                    Status = $item.Status
                    Comments = $item.Comments
                    FindingDetails = $item.Finding_Details
                    VulnID = $hash.Vuln_Num
                    Title = $hash.Rule_Title
                    Discussion = $hash.Vuln_Discuss
                    Check = $hash.Check_Content
                    FixText = $hash.Fix_Text
                    STIG = $hash.STIGRef
                    Weight = $hash.Weight
                    RuleID = $hash.Rule_ID
                    STIGID = $hash.Rule_Ver
                    Severity = $hash.Severity
                    HostName = $hostName
                    IP = $hostIP
                    IS = "3848"
                    "CKL/CKLB" = "CKL"
                }
                
                $rules += $rule
            }

            $summary += $rules | Where-Object { $_.Status -match "Open"} | Select-Object STIG, STIGID, RuleID, VulnID, Title, Discussion, Check, FixText, Severity, Status, FindingDetails, Comments, IS, HostName, IP, "CKL/CKLB"
            Write-Log -Level "INFO" -Component "XML Parse" -Message "Parsed $($file | Split-Path -Leaf)"

            Continue
        }
    }

    Export-Results -Data $summary -OutputDirectory $config.filePaths.outputDirectory -Formats $config.outputSettings.outputFormats -IncludeTimestamp $config.outputSettings.includeTimestamp

    $vulSum = $summary | Group-Object "VulnID" | ForEach-Object {
        [PSCustomObject]@{
            "V-ID" = $_.Name
            "Count" = $_.Count
            "Severity" = $_.Group[0].Severity
            "RuleTitle" = $_.Group[0].Title
        }
    }

    $Script:baseFileName = "summaryResults"

    Export-Results -Data $vulSum -OutputDirectory $config.filePaths.outputDirectory -Formats $config.outputSettings.outputFormats -IncludeTimestamp $config.outputSettings.includeTimestamp

    $scriptEndTime = Get-Date
    $scriptDuration = $scriptEndTime - $scriptStartTime
    $recordsPerSecond = [math]::Round($Summary.Count / $scriptDuration.TotalSeconds, 2)

    Write-Log -Level "INFO" -Component "Main" -Message "==== PERFORMANCE METRICS ===="
    Write-Log -Level "INFO" -Component "Main" -Message "Start Time: $($scriptStartTime)"
    Write-Log -Level "INFO" -Component "Main" -Message "End Time: $($scriptEndTime)"
    Write-Log -Level "INFO" -Component "Main" -Message "Script Duration: $($scriptDuration.TotalSeconds) seconds"
    Write-Log -Level "INFO" -Component "Main" -Message "Records Per Second: $($recordsPerSecond)"

    Write-Log -Level "INFO" -Component "Main" -Message "==== DATA SUMMARY ===="
    Write-Log -Level "INFO" -COmponent "Main" -Message "Total Checklists: $($Files.Count)"
    Write-Log -Level "INFO" -Component "Main" -Message "Total Open Entries: $($summary.Count)"
    Write-Log -Level "INFO" -Component "Main" -Message "Total Unique Vulnerability IDs: $($vulSum.Count)"

    Write-Log -Leevel "INFO" -Component "Main" -Message "==== END SCRIPT ===="

}
catch {
    Write-Log -Level "ERROR" -Component "Main" -Message "Script failed with error: $($_.Exception.Message)"
    Write-Log -Level "ERROR" -Component "Main" -Message "Stack Trace: $($_.ScriptStackTrace)"
    throw
}

finally {
    if ($logger -and $logger.LogToFile -and $logger.LogFile ){
        Write-Log -Level "INFO" -Component "Main" -Message "Log file located at: $($logger.LogFile)"
    }
    Remove-Variable -Name baseFileName -ErrorAction SilentlyContinue
}
