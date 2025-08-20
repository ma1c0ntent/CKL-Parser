# CKL-Parser

A comprehensive PowerShell script for parsing and analyzing STIG Checklist (CKL) and STIG Checklist Bundle (CKLB) files. This tool extracts vulnerability information from security compliance checklists and generates detailed reports for security analysis and compliance tracking.

## 🎯 Purpose

The CKL-Parser is designed to help security professionals, system administrators, and compliance teams:
- Parse multiple CKL and CKLB files simultaneously
- Extract and consolidate vulnerability findings
- Generate comprehensive reports in multiple formats
- Track compliance status across multiple systems
- Analyze vulnerability patterns and trends

## ✨ Features

- **Multi-format Support**: Handles both CKL (XML) and CKLB (JSON) file formats
- **Advanced Namespace Handling**: Robust XML parsing with multiple namespace fallback strategies
- **Variance Filtering**: Automatically filters out variance items based on configurable criteria
- **Batch Processing**: Processes multiple checklist files in a single run
- **Flexible Output**: Exports results in CSV and JSON formats
- **Comprehensive Logging**: Built-in logging system with configurable levels and rotation
- **Performance Metrics**: Tracks processing speed and provides execution statistics
- **Configurable**: Easy-to-modify configuration file for customization
- **Error Handling**: Robust error handling with detailed logging
- **Excluded Items Reporting**: Separate reports for filtered variance items
- **Smart Directory Handling**: Consistent path resolution for imports, exports, and logs

## 📁 Project Structure

```
CKL-Parser-main/
├── CKL-Parser.ps1          # Main PowerShell script
├── data/
│   ├── config/
│   │   └── config.json     # Configuration file
│   ├── imports/            # Directory for CKL/CKLB files
│   │   └── sample.ckl      # Sample checklist file
│   ├── logs/               # Log files directory
│   └── reports/            # Output reports directory
├── README.md               # This file
├── VERSIONING.md           # Versioning guidelines and strategy
└── CHANGELOG.md            # Detailed change history
```

## 🚀 Getting Started

### Prerequisites

- Windows PowerShell 5.1 or PowerShell Core 6.0+
- Access to CKL or CKLB files for processing

### Installation

1. Clone or download this repository
2. Place your CKL/CKLB files in the `data/imports/` directory
3. Review and modify `data/config/config.json` if needed
4. Run the script from PowerShell

### Basic Usage

```powershell
# Run with default configuration
.\CKL-Parser.ps1

# Run with custom configuration file
.\CKL-Parser.ps1 -ConfigPath "path\to\custom\config.json"

# Run without logging
.\CKL-Parser.ps1 -NoLog

# Run with specific output format
.\CKL-Parser.ps1 -OutputFormat "CSV"

# Run with JSON compression enabled
.\CKL-Parser.ps1 -CompressJson
```

### Command-Line Parameters

| Parameter | Description | Example |
|-----------|-------------|---------|
| `-ConfigPath` | Path to custom configuration file | `-ConfigPath "custom\config.json"` |
| `-OutputFormat` | Override output format from config | `-OutputFormat "CSV"` |
| `-NoLog` | Disable logging to file | `-NoLog` |
| `-CompressJson` | Enable JSON compression | `-CompressJson` |

## ⚙️ Configuration

The `config.json` file controls various aspects of the parser:

### File Paths
```json
"filePaths": {
    "checklistDirectory": "data\\imports",    # Input directory for CKL/CKLB files
    "outputDirectory": "data\\reports",       # Output directory for reports
    "logDirectory": "data\\logs"              # Log files directory
}
```

**Smart Path Resolution**: All directory paths support both absolute and relative paths:
- **Absolute Paths**: Use full system paths (e.g., `C:\Reports\Output`)
- **Relative Paths**: Use paths relative to script location (e.g., `data\reports`)
- **Automatic Fallback**: If relative path fails, automatically falls back to script-relative paths

### Logging Settings
```json
"logging": {
    "logLevel": "INFO",                       # Log level: DEBUG, INFO, WARN, ERROR
    "logToFile": true,                        # Enable file logging
    "logToConsole": true,                     # Enable console logging
    "maxLogFileSizeMB": 10,                   # Maximum log file size
    "maxLogFiles": 5                          # Maximum number of log files to keep
}
```

### Output Settings
```json
"outputSettings": {
    "includeTimestamp": true,                 # Add timestamp to output files
    "outputFormats": ["CSV", "JSON"],         # Output formats: CSV, JSON
    "jsonSettings": {
        "prettyPrint": true,                  # Enable pretty-printed JSON
        "maxDepth": 10,                       # Maximum nesting depth for JSON
        "compress": false                     # Enable/disable JSON compression
    }
}
```

### Variance Filtering
```json
"variance": {
    "comments": ["variance", "false positive", "not applicable"],
    "V-ID": ["V-220837", "V-254240", "V-230301"]
}
```

The variance filtering allows you to automatically exclude specific items:
- **Comment-based filtering**: Excludes rules with comments containing specified keywords
- **V-ID filtering**: Excludes specific vulnerability IDs regardless of content

## 📊 Output Files

The parser generates four types of reports:

### 1. Detailed Results (`parsedResultsYYYY-MM-dd hhmmss.csv`)
Contains all parsed vulnerability entries with fields:
- STIG Reference
- Vulnerability ID
- Rule Title
- Severity
- Status
- Finding Details
- Comments
- Host Information
- And more...

### 2. Summary Report (`summaryResultsYYYY-MM-DD hhmmss.csv`)
Provides a consolidated view of vulnerabilities:
- Vulnerability ID
- Count of occurrences
- Severity level
- Rule Title

### 3. Excluded Items Report (`excludedResultsYYYY-MM-dd hhmmss.csv`)
Contains all items filtered out by variance filtering:
- Same fields as detailed results
- Additional "ExclusionReason" field showing why item was excluded

### 4. Excluded Summary (`excludedSummaryYYYY-MM-dd hhmmss.csv`)
Summary of excluded items by vulnerability ID:
- Vulnerability ID
- Count of excluded instances
- Severity level
- Rule Title
- Exclusion Reason (Comment Match or V-ID Match)

### JSON Export Features
All reports are also available in JSON format with configurable options:
- **Pretty Printing**: Human-readable formatting with proper indentation
- **Configurable Depth**: Control maximum nesting levels (default: 10)
- **Compression Options**: Choose between compact or readable JSON
- **Error Handling**: Robust fallback mechanisms for export failures
- **UTF-8 Encoding**: Proper character encoding for international content

## 🔍 Supported File Formats

### CKL Files (XML)
- Traditional STIG Checklist format
- XML-based structure
- Contains detailed vulnerability information
- Extracts host name, IP address, and rule details
- **Advanced Namespace Support**: Automatically handles multiple XML namespace scenarios:
  - iSTIG namespace (`//cci:VULN`)
  - Root namespace (`//ns:VULN`)
  - XCCDF namespace (`//xccdf:VULN`)
  - No namespace fallback (`//VULN`)

### CKLB Files (JSON)
- STIG Checklist Bundle format
- JSON-based structure
- Modern format for multiple STIGs
- Includes target data and rule information

## 📝 Logging

The parser includes a comprehensive logging system:

- **Log Levels**: DEBUG, INFO, WARN, ERROR
- **Log Rotation**: Automatic log file rotation based on size
- **Multiple Outputs**: Console and file logging
- **Performance Tracking**: Execution time and processing metrics

## 🛠️ Customization

### Variance Filtering Configuration
The variance filtering system allows you to customize what gets excluded:

```json
"variance": {
    "comments": ["variance", "false positive", "not applicable", "custom term"],
    "V-ID": ["V-123456", "V-789012", "V-345678"]
}
```

**Comment Keywords**: Add or modify keywords to match against rule comments
**V-ID List**: Add specific vulnerability IDs to exclude regardless of content

### JSON Export Configuration
Customize JSON output formatting:

```json
"jsonSettings": {
    "prettyPrint": true,      # Enable pretty-printed JSON (recommended)
    "maxDepth": 10,           # Maximum nesting depth (1-100)
    "compress": false         # Enable compact JSON (true/false)
}
```

**Pretty Print**: When enabled, JSON is formatted with proper indentation for readability
**Max Depth**: Controls how deep nested objects are serialized (prevents circular reference issues)
**Compression**: When true, removes all whitespace for minimal file size

### JSON Export Best Practices

- **Development/Testing**: Use `prettyPrint: true` and `compress: false` for readable output
- **Production/Storage**: Use `compress: true` for minimal file size
- **Integration**: Use `maxDepth: 10` for most use cases, increase if needed for complex data
- **Command Line**: Use `-CompressJson` flag to override configuration for one-time exports

### Directory Path Best Practices

- **Portable Deployments**: Use relative paths (e.g., `data\reports`) for easy script relocation
- **Production Systems**: Use absolute paths (e.g., `C:\Production\Reports`) for fixed locations
- **Mixed Environments**: Script automatically handles both path types with intelligent fallbacks
- **Path Consistency**: All three directory types (imports, exports, logs) use the same resolution logic

### Adding New Output Formats
To add new output formats, modify the `Export-Results` function in the script and update the configuration file.

### Modifying Parsed Fields
The script extracts specific fields from CKL/CKLB files. You can modify the field mapping in the parsing sections to include additional data.

### Performance Optimization
For large numbers of files, consider:
- Adjusting log levels
- Using the `-NoLog` parameter for production runs
- Monitoring memory usage with large datasets

## 🐛 Troubleshooting

### Common Issues

1. **No files found**: Ensure CKL/CKLB files are in the `data/imports/` directory
2. **Permission errors**: Run PowerShell as Administrator if needed
3. **Configuration errors**: Verify `config.json` syntax and file paths
4. **Memory issues**: Process files in smaller batches for very large datasets
5. **Namespace parsing issues**: Check XML structure if VULN elements aren't found
6. **Variance filtering not working**: Verify variance configuration in `config.json`

### Debug Mode
Enable debug logging by setting `"logLevel": "DEBUG"` in the configuration file.

## 📈 Performance

The parser includes built-in performance metrics:
- Processing time per file
- Records processed per second
- Total execution duration
- Memory usage tracking

## 🤝 Contributing

To contribute to this project:
1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## 📄 License

This project is provided as-is for educational and operational use. Please ensure compliance with your organization's security policies when using this tool.

## ⚠️ Disclaimer

This tool is designed for security compliance analysis and should be used in accordance with your organization's security policies. Always validate results and ensure proper authorization before running security tools in production environments.

## 📞 Support

For issues, questions, or feature requests:
- Review the logging output for detailed error information
- Check the configuration file for syntax errors
- Ensure all required directories exist and are accessible


---

📖 **For detailed versioning information, see [VERSIONING.md](VERSIONING.md)**  
📋 **For complete change history, see [CHANGELOG.md](CHANGELOG.md)**
