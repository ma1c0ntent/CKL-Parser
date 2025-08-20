# CKL-Parser Versioning Guide

This document outlines the versioning strategy for the CKL-Parser project, following [Semantic Versioning 2.0.0](https://semver.org/) principles.

## 📋 Version Format

**MAJOR.MINOR.PATCH** (e.g., `1.2.0`)

- **MAJOR**: Breaking changes that require user action
- **MINOR**: New features that maintain backward compatibility
- **PATCH**: Bug fixes and minor improvements

## 🔄 Version Increment Rules

### 🚨 MAJOR Version (X.0.0)

**Increment when making incompatible API changes or breaking modifications that require user action.**

#### Examples of MAJOR Changes:

- **Breaking Configuration Changes**:
  - Removing configuration options
  - Changing required configuration structure
  - Renaming configuration keys

- **Breaking Script Interface**:
  - Removing command-line parameters
  - Changing parameter behavior
  - Modifying output file formats without fallbacks

- **Breaking Data Structure Changes**:
  - Changing CSV column names
  - Modifying JSON output structure
  - Altering log message formats

- **Breaking File Format Support**:
  - Removing support for CKL or CKLB files
  - Changing XML namespace handling behavior
  - Modifying parsing logic that breaks existing files

#### Example MAJOR Change:
```json
// Before (v1.x.x)
"outputFormats": ["CSV"]

// After (v2.0.0) - BREAKING CHANGE
"outputFormats": ["CSV", "JSON", "XML"]  // New required format
```

### ✨ MINOR Version (1.X.0)

**Increment when adding functionality in a backward-compatible manner.**

#### Examples of MINOR Changes:

- **New Features**:
  - Adding new output formats (CSV → CSV+JSON)
  - New variance filtering options
  - Additional command-line parameters
  - New configuration options

- **Enhanced Functionality**:
  - Improved XML namespace handling
  - Better error handling and fallbacks
  - Performance optimizations
  - Enhanced logging capabilities

- **New Reports**:
  - Adding excluded items reports
  - New summary report types
  - Additional export options

- **Configuration Enhancements**:
  - New JSON export settings
  - Additional logging options
  - Enhanced variance filtering

#### Example MINOR Change:
```json
// Before (v1.1.x)
"outputSettings": {
    "includeTimestamp": true,
    "outputFormats": ["CSV"]
}

// After (v1.2.0) - NEW FEATURE
"outputSettings": {
    "includeTimestamp": true,
    "outputFormats": ["CSV", "JSON"],
    "jsonSettings": {
        "prettyPrint": true,
        "maxDepth": 10
    }
}
```

### 🐛 PATCH Version (1.1.X)

**Increment when making backward-compatible bug fixes.**

#### Examples of PATCH Changes:

- **Bug Fixes**:
  - Fixing XML parsing errors
  - Correcting CSV export issues
  - Resolving logging problems
  - Fixing variance filtering logic

- **Minor Improvements**:
  - Better error messages
  - Improved performance
  - Enhanced error handling
  - Documentation updates

- **Compatibility Fixes**:
  - Supporting new CKL file formats
  - Fixing PowerShell version compatibility
  - Resolving encoding issues

#### Example PATCH Change:
```powershell
# Before (v1.1.0) - Bug in XML parsing
$items = $xml.SelectNodes("//VULN")  # Sometimes failed

# After (v1.1.1) - Fixed with fallback
$items = $xml.SelectNodes("//VULN")
if (-not $items) {
    $items = $xml.SelectNodes("//ns:VULN")  # Fallback
}
```

## 📊 Version History Examples

### Version 1.0.0 → 1.1.0 (MINOR)
- **Added**: Variance filtering system
- **Added**: Excluded items reporting
- **Enhanced**: XML namespace handling
- **Added**: Enhanced logging capabilities

**Why MINOR?** New features that don't break existing functionality.

### Version 1.1.0 → 1.2.0 (MINOR)
- **Added**: JSON export functionality
- **Enhanced**: Directory path handling
- **Added**: JSON configuration options
- **Added**: Command-line JSON compression

**Why MINOR?** New features and improvements that maintain backward compatibility.

### Version 1.0.0 → 2.0.0 (MAJOR) - Hypothetical
- **Changed**: Configuration file structure completely
- **Removed**: Support for old CKL format
- **Changed**: Required PowerShell 7.0+

**Why MAJOR?** Breaking changes that require user action and configuration updates.

## 🎯 When to Release

### 🔴 MAJOR Release (X.0.0)
- Breaking changes that affect all users
- Major architectural changes
- Incompatible configuration updates
- **Release Strategy**: Plan carefully, provide migration guides

### 🟡 MINOR Release (1.X.0)
- New features and enhancements
- Performance improvements
- Additional configuration options
- **Release Strategy**: Regular releases, feature-focused

### 🟢 PATCH Release (1.1.X)
- Bug fixes and minor improvements
- Documentation updates
- Compatibility fixes
- **Release Strategy**: As needed, quick turnaround

## 📝 Release Checklist

### Before Release:
- [ ] Update version in `config.json`
- [ ] Update version in `README.md`
- [ ] Update `CHANGELOG.md` with new version
- [ ] Test all functionality
- [ ] Verify backward compatibility (for MINOR/PATCH)

### Release Notes Should Include:
- **Version Number**: Clear version identifier
- **Change Type**: MAJOR/MINOR/PATCH
- **Breaking Changes**: What users need to know (for MAJOR)
- **New Features**: What's been added (for MINOR)
- **Bug Fixes**: What's been resolved (for PATCH)
- **Migration Guide**: How to upgrade (for MAJOR)

## 🔍 Version Compatibility Matrix

| CKL-Parser Version | PowerShell Version | CKL Support | CKLB Support | JSON Export |
|-------------------|-------------------|-------------|--------------|-------------|
| 1.0.0             | 5.1+              | ✅          | ✅           | ❌          |
| 1.1.0             | 5.1+              | ✅          | ✅           | ❌          |
| 1.2.0             | 5.1+              | ✅          | ✅           | ✅          |

## 💡 Best Practices

### For Developers:
1. **Always test backward compatibility** before MINOR/PATCH releases
2. **Document breaking changes** clearly for MAJOR releases
3. **Use feature flags** when possible to maintain compatibility
4. **Provide migration paths** for breaking changes

### For Users:
1. **Review release notes** before upgrading
2. **Test in non-production** environments first
3. **Backup configurations** before MAJOR version upgrades
4. **Follow migration guides** for breaking changes

## 📚 References

- [Semantic Versioning 2.0.0](https://semver.org/)
- [Keep a Changelog](https://keepachangelog.com/)
- [Conventional Commits](https://www.conventionalcommits.org/)

---

**Last Updated**: 2025-08-19  
**Current Version**: 1.2.0  
**Next Planned Release**: 1.2.1 (PATCH) or 1.3.0 (MINOR)
