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
- **Batch Processing**: Processes multiple checklist files in a single run
- **Flexible Output**: Exports results in CSV and JSON formats
- **Comprehensive Logging**: Built-in logging system with configurable levels and rotation
- **Performance Metrics**: Tracks processing speed and provides execution statistics
- **Configurable**: Easy-to-modify configuration file for customization
- **Error Handling**: Robust error handling with detailed logging

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
└── README.md               # This file
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
```

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
    "outputFormats": ["CSV"]                  # Output formats: CSV, JSON
}
```

## 📊 Output Files

The parser generates two main types of reports:

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

## 🔍 Supported File Formats

### CKL Files (XML)
- Traditional STIG Checklist format
- XML-based structure
- Contains detailed vulnerability information
- Extracts host name, IP address, and rule details

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

**Version**: 1.0.0  
**Compatibility**: PowerShell 5.1+, Windows 10/11, Windows Server 2016+
