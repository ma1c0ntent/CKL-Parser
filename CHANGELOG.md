# Changelog

All notable changes to the CKL-Parser project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Planned
- Additional output format support
- Performance optimizations
- Enhanced error handling

## [1.2.0] - 2025-08-19

### Added
- **JSON Export Functionality**: Full JSON export support for all report types
- **JSON Configuration Options**: Configurable pretty printing, depth control, and compression
- **Command-Line JSON Compression**: `-CompressJson` parameter for one-time compression
- **Smart Directory Path Handling**: Consistent path resolution for imports, exports, and logs
- **Absolute Path Support**: Configuration now supports both absolute and relative paths
- **Automatic Path Fallbacks**: Intelligent fallback mechanisms for different path types

### Enhanced
- **Export-Results Function**: Enhanced with JSON settings and better error handling
- **Initialize-Logger Function**: Improved path resolution for log directories
- **Path Resolution Logic**: All three directory types now use consistent resolution strategy
- **Portability**: Script now works better from different working directories

### Changed
- **Configuration Structure**: Added `jsonSettings` section to `outputSettings`
- **Default Output Formats**: Now includes both CSV and JSON by default
- **Path Handling**: More flexible and robust directory path management

### Technical Details
- **JSON Export**: Uses `ConvertTo-Json` with configurable depth and compression
- **Path Resolution**: Three-step fallback: absolute → relative → script-relative
- **Error Handling**: Enhanced fallback mechanisms for JSON export failures
- **Performance**: Maintains existing performance while adding new functionality

## [1.1.0] - 2025-08-19

### Added
- **Variance Filtering System**: Automatically filter out variance items based on configurable criteria
- **Excluded Items Reporting**: Separate reports for filtered variance items
- **Enhanced XML Namespace Handling**: Robust parsing with multiple namespace fallback strategies
- **Advanced Logging**: Detailed debug information for namespace parsing and variance filtering

### Enhanced
- **XML Parsing**: Multiple namespace approaches (cci, root, xccdf, fallback)
- **Error Handling**: Better fallback mechanisms for different CKL file formats
- **Logging System**: Enhanced debug logging for troubleshooting

### Changed
- **Configuration Structure**: Added `variance` section for filtering configuration
- **Output Reports**: Now generates four report types instead of two
- **Filtering Logic**: Rules are now categorized as included or excluded

### Technical Details
- **Variance Filtering**: Comment-based and V-ID-based exclusion
- **Namespace Handling**: Automatic fallback from cci → root → xccdf → no-namespace
- **Report Generation**: Separate processing for included and excluded items
- **Performance**: Maintains existing performance while adding filtering

## [1.0.0] - 2025-08-19

### Added
- **Basic CKL/CKLB Parsing**: Support for STIG Checklist and Checklist Bundle files
- **CSV Export**: Detailed and summary reports in CSV format
- **Logging System**: Configurable logging with file rotation
- **Performance Metrics**: Execution time and processing statistics
- **Configuration File**: JSON-based configuration system

### Features
- **Multi-format Support**: Handles both CKL (XML) and CKLB (JSON) files
- **Batch Processing**: Processes multiple checklist files simultaneously
- **Flexible Configuration**: Easy-to-modify configuration file
- **Error Handling**: Basic error handling and logging

### Technical Details
- **PowerShell 5.1+ Compatibility**: Works on Windows 10/11 and Server 2016+
- **File Processing**: Recursive file discovery with extension filtering
- **Data Extraction**: Parses vulnerability information from multiple sources
- **Report Generation**: Creates timestamped output files

---

## Version Compatibility Matrix

| CKL-Parser Version | PowerShell Version | CKL Support | CKLB Support | JSON Export | Variance Filtering | Smart Paths |
|-------------------|-------------------|-------------|--------------|-------------|-------------------|-------------|
| 1.2.0             | 5.1+              | ✅          | ✅           | ✅          | ✅                 | ✅          |
| 1.1.0             | 5.1+              | ✅          | ✅           | ❌          | ✅                 | ❌          |
| 1.0.0             | 5.1+              | ✅          | ✅           | ❌          | ❌                 | ❌          |

## Migration Notes

### Upgrading from 1.1.0 to 1.2.0
- **No Breaking Changes**: All existing configurations will continue to work
- **New Features**: JSON export and enhanced path handling are optional
- **Configuration**: Add `jsonSettings` section if you want to customize JSON output
- **Paths**: Existing relative paths will continue to work as before

### Upgrading from 1.0.0 to 1.2.0
- **No Breaking Changes**: All existing functionality preserved
- **New Features**: Variance filtering, JSON export, and enhanced path handling
- **Configuration**: Add `variance` and `jsonSettings` sections as needed
- **Reports**: Now generates additional excluded items reports

## Release Strategy

- **MAJOR Releases** (X.0.0): Breaking changes requiring user action
- **MINOR Releases** (1.X.0): New features maintaining backward compatibility
- **PATCH Releases** (1.1.X): Bug fixes and minor improvements

For detailed versioning information, see [VERSIONING.md](VERSIONING.md).

---

**Note**: This changelog follows the [Keep a Changelog](https://keepachangelog.com/) format and [Semantic Versioning](https://semver.org/) principles.
