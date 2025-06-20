# CSV/Excel Import & Export Feature

## Overview

The SevaFinance app now supports comprehensive CSV and Excel import/export functionality, allowing users to:

- **Import** historic expense data from bank statements and other sources
- **Export** their transaction data for reporting, tax preparation, or personal archives
- **Map** CSV/Excel columns to app fields with reusable presets
- **Validate** data during import with detailed error reporting

## Features

### Import Functionality

#### Supported Formats
- **CSV** files (comma-separated values)
- **Excel** files (.xlsx, .xls)
- Maximum file size: 10MB

#### File Processing
- **Drag & Drop** or browse file selection
- **Live Preview** of first 10 rows
- **Column Mapping** with visual interface
- **Validation** with detailed error reporting
- **Progress Tracking** during import
- **Batch Processing** for large files (300 transactions per batch)

#### Column Mapping
Required fields:
- **Date** - Transaction date (supports multiple formats)
- **Amount** - Transaction amount (automatically converts to positive)

Optional fields:
- **Description** - Transaction description/note
- **Category** - Expense category (creates new categories if needed)

#### Mapping Presets
- **Save** frequently used column mappings
- **Reuse** saved presets for similar file formats
- **Manage** presets (create, load, delete)

### Export Functionality

#### Export Formats
- **CSV** - Compatible with Excel, Google Sheets
- **Excel** - Native .xlsx format with formatting

#### Export Options
- **Date Ranges**:
  - All Time
  - Current Month
  - Last Month
  - Last 3/6 Months
  - Current Year
  - Custom Range

#### Export Data
- Date (YYYY-MM-DD format)
- Description
- Category Name
- Amount

### Rate Limiting & Security

#### Import Limits
- Maximum 5 imports per day per user
- Maximum 10MB file size
- Firestore batch limits respected

#### Export Limits
- Maximum 3 exports per hour per user

#### Data Security
- All data processed locally and in Firebase
- No third-party data sharing
- User-specific access controls

## User Interface

### Access Points

#### Expenses Screen
1. Tap the **floating action button** (camera icon)
2. Select **"Import Expenses"** from the modal
3. Select **"Export Expenses"** from the modal

#### Account Screen
1. Navigate to **Account** tab
2. Go to **"Data Management"** section
3. Tap **"Export Data"**

### Import Flow

1. **File Selection**
   - Tap "Browse Files" or drag & drop
   - Preview shows file structure
   - File validation occurs

2. **Column Mapping**
   - Map CSV columns to app fields
   - Required: Date, Amount
   - Optional: Description, Category
   - Save mapping as preset for reuse

3. **Import Process**
   - Progress bar shows completion
   - Real-time error reporting
   - Summary shows success/failure counts

4. **Results**
   - Import summary dialog
   - Error details for failed rows
   - Option to view imported expenses

### Export Flow

1. **Format Selection**
   - Choose CSV or Excel
   - See format descriptions

2. **Date Range**
   - Select predefined range or custom dates
   - Preview shows what will be exported

3. **Export Process**
   - Progress indicator during generation
   - Automatic download to device

4. **Completion**
   - Success confirmation
   - File location information

## Technical Implementation

### File Processing
- **CSV Parsing**: Uses `csv` package with UTF-8 encoding
- **Excel Processing**: Uses `excel` package for .xlsx/.xls files
- **Date Recognition**: Supports multiple date formats automatically
- **Amount Parsing**: Handles currency symbols and formatting

### Data Validation
- **Date Validation**: Multiple format support with error reporting
- **Amount Validation**: Numeric validation with currency cleaning
- **Category Handling**: Auto-creation of new categories
- **Duplicate Prevention**: Uses unique IDs for all imports

### Storage & Sync
- **Local Storage**: Hive for offline access
- **Cloud Sync**: Firestore for cross-device sync
- **Batch Operations**: Efficient bulk writes
- **Error Recovery**: Graceful handling of partial failures

### Platform Support
- **Web**: Direct download using universal_html
- **Mobile**: Save to Downloads folder
- **Cross-platform**: Consistent experience across devices

## Error Handling

### Import Errors
- **File Format**: Unsupported file types
- **File Size**: Files exceeding 10MB limit
- **Data Validation**: Invalid dates, amounts, or formats
- **Rate Limits**: Daily import limits exceeded
- **Network Issues**: Firestore connection problems

### Export Errors
- **Rate Limits**: Hourly export limits exceeded
- **Data Access**: Permission or authentication issues
- **File Generation**: Processing or download failures

### Error Recovery
- **Partial Success**: Import continues despite row-level errors
- **Error Details**: Specific error messages for each failure
- **Retry Options**: Users can fix and retry failed imports

## Performance

### Optimization Features
- **Streaming**: Large files processed in chunks
- **Batch Processing**: Firestore writes optimized in batches
- **Progress Tracking**: Real-time feedback for long operations
- **Memory Management**: Efficient handling of large datasets

### Scalability
- **File Size**: Up to 10MB files supported
- **Transaction Volume**: Thousands of transactions per import
- **Concurrent Users**: Rate limiting prevents system overload

## Future Enhancements

### Planned Features
- **Automatic Categorization**: AI-powered category suggestions
- **Bank Integration**: Direct bank statement import
- **Scheduled Exports**: Automatic periodic exports
- **Advanced Filtering**: More granular export options
- **Template Management**: Enhanced preset management
- **Bulk Operations**: Advanced data manipulation tools

### Format Support
- **QIF Files**: Quicken Interchange Format
- **OFX Files**: Open Financial Exchange
- **PDF Parsing**: Extract data from PDF statements
- **Image OCR**: Receipt scanning integration

## Troubleshooting

### Common Issues

#### Import Problems
1. **"File too large"**: Reduce file size or split into smaller files
2. **"Invalid date format"**: Ensure dates are in recognizable format
3. **"Rate limit exceeded"**: Wait for daily limit reset
4. **"Column mapping required"**: Map Date and Amount columns

#### Export Problems
1. **"No data to export"**: Ensure date range contains transactions
2. **"Export limit reached"**: Wait for hourly limit reset
3. **"Download failed"**: Check browser permissions and storage space

### Support
- Check error messages for specific guidance
- Verify file format and size requirements
- Ensure stable internet connection for cloud sync
- Contact support for persistent issues

## Security & Privacy

### Data Protection
- **Local Processing**: Files processed on device when possible
- **Encrypted Transit**: All data encrypted in transit
- **User Isolation**: Each user's data completely isolated
- **No Data Mining**: Import/export data not used for analytics

### Compliance
- **GDPR Ready**: Full data export and deletion support
- **Privacy First**: Minimal data collection
- **Transparent Processing**: Clear data usage policies

---

This CSV/Excel import/export feature transforms SevaFinance into a comprehensive expense management solution, bridging the gap between manual entry and automated data processing while maintaining the highest standards of security and user experience. 