param(
    [string]$ConfigPath = "$PSScriptRoot\data\config\config.json",
    [string]$OutputFormat = "",
    [switch]$NoLog,
    [switch]$CompressJson
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
    # Handle log directory path similar to import/export directory logic
    $logDir = $config.filePaths.logDirectory
    
    # First try the path as-is
    if (Test-Path -Path $config.filePaths.logDirectory -ErrorAction SilentlyContinue) {
        $logDir = $config.filePaths.logDirectory
    }
    # Then try joining with PSScriptRoot if the first attempt fails
    ElseIf (Test-Path -Path $(Join-Path $PSScriptRoot -ChildPath $config.filePaths.logDirectory) -ErrorAction SilentlyContinue) {
        $logDir = Join-Path $PSScriptRoot -ChildPath $config.filePaths.logDirectory
    }
    # If neither exists, create the directory using PSScriptRoot as base
    Else {
        $logDir = Join-Path $PSScriptRoot -ChildPath $config.filePaths.logDirectory
        if ($logToFile -and -not (Test-Path $logDir)) {
            New-Item -Path $logDir -ItemType Directory -Force | Out-Null
        }
    }
    
    $maxLogFileSizeMB = $LogConfig.maxLogFileSizeMB
    $maxLogFiles = $LogConfig.maxLogFiles

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

Function Test-VarianceFilter {
    param(
        [PSCustomObject]$Rule,
        [PSCustomObject]$VarianceConfig
    )
    
    # If no variance configuration, include all rules
    if (-not $VarianceConfig -or (-not $VarianceConfig.comments -and -not $VarianceConfig.'V-ID')) {
        return @{ Excluded = $true; Reason = "No Variance Config" }
    }
    
    # Check if rule should be excluded based on variance.comments
    if ($VarianceConfig.comments -and $VarianceConfig.comments.Count -gt 0) {
        Write-Log -Level "DEBUG" -Component "Variance-Filter" -Message "Checking comment filtering for rule $($Rule.VulnID) - Comments: '$($Rule.Comments)' against terms: $($VarianceConfig.comments -join ', ')"
        foreach ($commentTerm in $VarianceConfig.comments) {
            if ($commentTerm -and $commentTerm.Trim() -ne "" -and $Rule.Comments -match $commentTerm) {
                Write-Log -Level "DEBUG" -Component "Variance-Filter" -Message "Excluding rule $($Rule.VulnID) due to matching comment term: '$commentTerm'"
                return @{ Excluded = $false; Reason = "Comment Match: '$commentTerm'" }
            }
        }
    }
    

    
    # Check if rule should be excluded based on variance.V-ID
    if ($VarianceConfig.'V-ID' -and $VarianceConfig.'V-ID'.Count -gt 0) {
        Write-Log -Level "DEBUG" -Component "Variance-Filter" -Message "Checking V-ID filtering for rule $($Rule.VulnID) against V-IDs: $($VarianceConfig.'V-ID' -join ', ')"
        foreach ($vulnID in $VarianceConfig.'V-ID') {
            if ($vulnID -and $vulnID.Trim() -ne "" -and $Rule.VulnID -eq $vulnID) {
                Write-Log -Level "DEBUG" -Component "Variance-Filter" -Message "Excluding rule $($Rule.VulnID) due to matching V-ID: '$vulnID'"
                return @{ Excluded = $false; Reason = "V-ID Match: '$vulnID'" }
            }
        }
    }
    
    return @{ Excluded = $true; Reason = "Not Excluded" }
}

Function Export-Results {
    param(
        [array]$Data,
        [string]$OutputDirectory,
        [array]$Formats,
        [bool]$IncludeTimestamp,
        [PSCustomObject]$JsonSettings = $null
    )

    $timestamp = if ($IncludeTimestamp) { "$(Get-Date -Format 'yyyy-MM-dd HHmmss')" } else { "" }
    if (-not($baseFileName)) {
        $baseFileName = "parsedResults$timestamp"
    }
    else {
        $baseFileName = $baseFileName + $timestamp
    }
    
    # Handle output directory path similar to import directory logic
    $FinalOutputDirectory = $OutputDirectory
    
    # First try the path as-is
    if (Test-Path -Path $OutputDirectory -ErrorAction SilentlyContinue) {
        $FinalOutputDirectory = $OutputDirectory
    }
    # Then try joining with PSScriptRoot if the first attempt fails
    ElseIf (Test-Path -Path $(Join-Path $PSScriptRoot -ChildPath $OutputDirectory) -ErrorAction SilentlyContinue) {
        $FinalOutputDirectory = Join-Path $PSScriptRoot -ChildPath $OutputDirectory
    }
    # If neither exists, create the directory using PSScriptRoot as base
    Else {
        $FinalOutputDirectory = Join-Path $PSScriptRoot -ChildPath $OutputDirectory
        if (-not (Test-Path $FinalOutputDirectory)) {
            New-Item -Path $FinalOutputDirectory -ItemType Directory -Force | Out-Null
            Write-Log -Level "INFO" -Component "Export-Results" -Message "Created output directory: $FinalOutputDirectory"
        }
    }

    ForEach ($Format in $Formats) {
        try {
            switch ($format.ToUpper()) {
                "CSV" {
                    $csvPath = Join-Path $FinalOutputDirectory "$($baseFileName).csv"
                    $Data | Export-Csv -Path $csvPath -NoTypeInformation -Encoding UTF8
                    Write-Log -Level "INFO" -Component "Export-Results" -Message "Exported results to CSV: $csvPath"
                }
                "JSON" {
                    $jsonPath = Join-Path $FinalOutputDirectory "$($baseFileName).json"
                    try {
                        # Enhanced JSON export with configurable formatting
                        $depth = if ($JsonSettings -and $JsonSettings.maxDepth) { $JsonSettings.maxDepth } else { 10 }
                        $compress = if ($JsonSettings -and $JsonSettings.compress -ne $null) { $JsonSettings.compress } else { $false }
                        
                        $jsonContent = $Data | ConvertTo-Json -Depth $depth -Compress:$compress
                        
                        # Apply pretty printing if configured
                        if ($JsonSettings -and $JsonSettings.prettyPrint -eq $true) {
                            $jsonContent = $jsonContent | ConvertFrom-Json | ConvertTo-Json -Depth $depth -Compress:$false
                        }
                        
                        $jsonContent | Out-File -FilePath $jsonPath -Encoding UTF8 -ErrorAction Stop
                        Write-Log -Level "INFO" -Component "Export-Results" -Message "Exported results to JSON: $jsonPath (Depth: $depth, Compressed: $compress)"
                    }
                    catch {
                        Write-Log -Level "ERROR" -Component "Export-Results" -Message "Failed to export JSON: $($_.Exception.Message)"
                        # Fallback to basic JSON export
                        try {
                            $Data | ConvertTo-Json | Out-File -FilePath $jsonPath -Encoding UTF8 -ErrorAction Stop
                            Write-Log -Level "INFO" -Component "Export-Results" -Message "Exported results to JSON (fallback): $jsonPath"
                        }
                        catch {
                            Write-Log -Level "ERROR" -Component "Export-Results" -Message "JSON export completely failed: $($_.Exception.Message)"
                        }
                    }
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
    
    # Override JSON compression if specified via command line
    if ($CompressJson -and $config.outputSettings.jsonSettings) {
        $config.outputSettings.jsonSettings.compress = $true
        Write-Log -Level "INFO" -Component "Main" -Message "JSON compression enabled via command line parameter"
    }
    
    # Log variance configuration if present
    if ($config.variance) {
        if ($config.variance.comments -and $config.variance.comments.Count -gt 0) {
            Write-Log -Level "INFO" -Component "Main" -Message "Variance filtering enabled for comments: $($config.variance.comments -join ', ')"
        }
        if ($config.variance.'V-ID' -and $config.variance.'V-ID'.Count -gt 0) {
            Write-Log -Level "INFO" -Component "Main" -Message "Variance filtering enabled for V-IDs: $($config.variance.'V-ID' -join ', ')"
        }
        if (-not $config.variance.comments -and -not $config.variance.'V-ID') {
            Write-Log -Level "INFO" -Component "Main" -Message "Variance filtering configured but no filter terms specified"
        }
    } else {
        Write-Log -Level "INFO" -Component "Main" -Message "No variance filtering configured"
    }

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
    $excludedItems = @()

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
                    IS = if($null -ne $config.systemInfo.informationSystem) { $config.systemInfo.informationSystem } else { "" }
                    "CKL/CKLB" = "CKLB"
                }
            }

            # Separate included and excluded rules
            $includedRules = @()
            $excludedRules = @()
            
            foreach ($rule in $rules) {
                if ($rule.Status -match "Open") {
                    $varianceResult = Test-VarianceFilter -Rule $rule -VarianceConfig $config.variance
                    if ($varianceResult.Excluded) {
                        $includedRules += $rule
                    } else {
                        # Add exclusion reason to the rule
                        $rule | Add-Member -NotePropertyName "ExclusionReason" -NotePropertyValue $varianceResult.Reason -Force
                        $excludedRules += $rule
                    }
                }
            }
            
            $summary += $includedRules | Select-Object STIG, STIGID, RuleID, VulnID, Title, Discussion, Check, FixText, Severity, Status, FindingDetails, Comments, IS, HostName, IP, "CKL/CKLB"
            $excludedItems += $excludedRules | Select-Object STIG, STIGID, RuleID, VulnID, Title, Discussion, Check, FixText, Severity, Status, FindingDetails, Comments, IS, HostName, IP, "CKL/CKLB", ExclusionReason

            Write-Log -Level "INFO" -Component "JSON Parse" -Message "Parsed $($file | Split-Path -Leaf)"

            Continue
        }
        ElseIf ( $File.EndsWith(".ckl") ) {
            $xml = [xml](Get-Content $File)
            
            # Handle multiple namespace scenarios
            $nsm = New-Object System.Xml.XmlNamespaceManager($xml.NameTable)
            $items = $null
            
            # Get the document element to determine the namespace structure
            $rootNamespace = $xml.DocumentElement.NamespaceURI
            
            if ($rootNamespace) {
                $nsm.AddNamespace('ns', $rootNamespace)
                $nsm.AddNamespace('xccdf', 'http://checklists.nist.gov/xccdf/1.1')
                $nsm.AddNamespace('cci', 'http://iase.disa.mil/cci')
                
                # Try different namespace approaches in order of preference
                Write-Log -Level "DEBUG" -Component "XML Parse" -Message "Attempting to parse VULN elements with multiple namespace approaches"
                
                # 1. Try iSTIG namespace (most common)
                $items = $xml.SelectNodes("//cci:VULN", $nsm)
                if ($items -and $items.Count -gt 0) {
                    Write-Log -Level "DEBUG" -Component "XML Parse" -Message "Found VULN elements using cci namespace"
                } else {
                    # 2. Try root namespace 
                    $items = $xml.SelectNodes("//ns:VULN", $nsm)
                    if ($items -and $items.Count -gt 0) {
                        Write-Log -Level "DEBUG" -Component "XML Parse" -Message "Found VULN elements using root namespace (ns)"
                    } else {
                        # 3. Try xccdf namespace explicitly
                        $items = $xml.SelectNodes("//xccdf:VULN", $nsm)
                        if ($items -and $items.Count -gt 0) {
                            Write-Log -Level "DEBUG" -Component "XML Parse" -Message "Found VULN elements using xccdf namespace"
                        }
                    }
                }
            }
            
            # Final fallback: no namespace
            if (-not $items -or $items.Count -eq 0) {
                Write-Log -Level "DEBUG" -Component "XML Parse" -Message "No VULN elements found with any namespace, trying no-namespace approach"
                $items = $xml.SelectNodes("//VULN")
                if ($items -and $items.Count -gt 0) {
                    Write-Log -Level "DEBUG" -Component "XML Parse" -Message "Found VULN elements using no-namespace approach"
                }
            }

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
                    IS = if($null -ne $config.systemInfo.informationSystem) { $config.systemInfo.informationSystem } else { "" }
                    "CKL/CKLB" = "CKL"
                }
                
                $rules += $rule
            }
            


            # Separate included and excluded rules
            $includedRules = @()
            $excludedRules = @()
            
            foreach ($rule in $rules) {
                if ($rule.Status -match "Open") {
                    $varianceResult = Test-VarianceFilter -Rule $rule -VarianceConfig $config.variance
                    if ($varianceResult.Excluded) {
                        $includedRules += $rule
                    } else {
                        # Add exclusion reason to the rule
                        $rule | Add-Member -NotePropertyName "ExclusionReason" -NotePropertyValue $varianceResult.Reason -Force
                        $excludedRules += $rule
                    }
                }
            }
            
            $summary += $includedRules | Select-Object STIG, STIGID, RuleID, VulnID, Title, Discussion, Check, FixText, Severity, Status, FindingDetails, Comments, IS, HostName, IP, "CKL/CKLB"
            $excludedItems += $excludedRules | Select-Object STIG, STIGID, RuleID, VulnID, Title, Discussion, Check, FixText, Severity, Status, FindingDetails, Comments, IS, HostName, IP, "CKL/CKLB", ExclusionReason
            Write-Log -Level "INFO" -Component "XML Parse" -Message "Parsed $($file | Split-Path -Leaf)"

            Continue
        }
    }

                    Export-Results -Data $summary -OutputDirectory $config.filePaths.outputDirectory -Formats $config.outputSettings.outputFormats -IncludeTimestamp $config.outputSettings.includeTimestamp -JsonSettings $config.outputSettings.jsonSettings

    # Export excluded items (variance filtered out)
    if ($excludedItems.Count -gt 0) {
        $Script:baseFileName = "excludedResults"
                            Export-Results -Data $excludedItems -OutputDirectory $config.filePaths.outputDirectory -Formats $config.outputSettings.outputFormats -IncludeTimestamp $config.outputSettings.includeTimestamp -JsonSettings $config.outputSettings.jsonSettings
        
        # Create summary of excluded items
        $excludedVulSum = $excludedItems | Group-Object "VulnID" | ForEach-Object {
            [PSCustomObject]@{
                "V-ID" = $_.Name
                "Count" = $_.Count
                "Severity" = $_.Group[0].Severity
                "RuleTitle" = $_.Group[0].Title
                "ExclusionReason" = $_.Group[0].ExclusionReason
            }
        }
        
        $Script:baseFileName = "excludedSummary"
                            Export-Results -Data $excludedVulSum -OutputDirectory $config.filePaths.outputDirectory -Formats $config.outputSettings.outputFormats -IncludeTimestamp $config.outputSettings.includeTimestamp -JsonSettings $config.outputSettings.jsonSettings
        
        Write-Log -Level "INFO" -Component "Main" -Message "Exported $($excludedItems.Count) excluded items and $($excludedVulSum.Count) unique excluded vulnerability IDs"
    } else {
        Write-Log -Level "INFO" -Component "Main" -Message "No items were excluded by variance filtering"
    }

    $vulSum = $summary | Group-Object "VulnID" | ForEach-Object {
        [PSCustomObject]@{
            "V-ID" = $_.Name
            "Count" = $_.Count
            "Severity" = $_.Group[0].Severity
            "RuleTitle" = $_.Group[0].Title
        }
    }

    $Script:baseFileName = "summaryResults"

                    Export-Results -Data $vulSum -OutputDirectory $config.filePaths.outputDirectory -Formats $config.outputSettings.outputFormats -IncludeTimestamp $config.outputSettings.includeTimestamp -JsonSettings $config.outputSettings.jsonSettings

    $scriptEndTime = Get-Date
    $scriptDuration = $scriptEndTime - $scriptStartTime
    $recordsPerSecond = [math]::Round($Summary.Count / $scriptDuration.TotalSeconds, 2)

    Write-Log -Level "INFO" -Component "Main" -Message "==== PERFORMANCE METRICS ===="
    Write-Log -Level "INFO" -Component "Main" -Message "Start Time: $($scriptStartTime)"
    Write-Log -Level "INFO" -Component "Main" -Message "End Time: $($scriptEndTime)"
    Write-Log -Level "INFO" -Component "Main" -Message "Script Duration: $($scriptDuration.TotalSeconds) seconds"
    Write-Log -Level "INFO" -Component "Main" -Message "Records Per Second: $($recordsPerSecond)"

    Write-Log -Level "INFO" -Component "Main" -Message "==== DATA SUMMARY ===="
    Write-Log -Level "INFO" -Component "Main" -Message "Total Checklists: $($Files.Count)"
    Write-Log -Level "INFO" -Component "Main" -Message "Total Open Entries: $($summary.Count)"
    Write-Log -Level "INFO" -Component "Main" -Message "Total Unique Vulnerability IDs: $($vulSum.Count)"
    Write-Log -Level "INFO" -Component "Main" -Message "Total Excluded Items: $($excludedItems.Count)"
    Write-Log -Level "INFO" -Component "Main" -Message "Total Unique Excluded Vulnerability IDs: $($excludedItems | Group-Object 'VulnID' | Measure-Object | Select-Object -ExpandProperty Count)"

    Write-Log -Level "INFO" -Component "Main" -Message "==== END SCRIPT ===="

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
