# 🚀 Advanced Crash Analytics Dashboard

A comprehensive, real-time crash analytics dashboard that unifies data from Firebase Crashlytics and Sentry. Features advanced filtering, critical event analysis, and interactive visualizations powered by BigQuery and Chart.js.

## ✨ Key Features

### 🔥 Critical Events Analysis
- **5-second timing window** analysis of events before crashes
- **Top 10 visual chart** + comprehensive scrollable list
- **Platform-specific breakdown** (iOS 🍎 / Android 🤖)
- **Event timing correlation** showing exact seconds before crash

### 📊 Enhanced Crash Visualization
- **Multi-colored pie charts** with 20 distinct colors for crash types
- **Clean crash names** (removes UnityFramework/technical clutter)
- **Interactive hover effects** with detailed statistics
- **Platform-specific color coding** and animations

### 🎯 Advanced Filtering & Search
- **Multi-select filters** for memory ranges and app versions
- **Flexible date ranges** (custom hours, absolute date picker)
- **User ID search** for investigating specific users
- **Manual search button** (no auto-refresh for better performance)

### 📱 Platform Intelligence
- **iOS vs Android** comparative analysis
- **Platform-specific metrics** and visualizations
- **Cross-platform event correlation**
- **Device-specific crash patterns**

### 🔧 Technical Enhancements
- **Custom CORS-enabled server** for Google OAuth support
- **Enhanced BigQuery view** with breadcrumb data parsing
- **Robust error handling** with JSON parsing fallbacks
- **Comprehensive user data aggregation**

## 🚀 Quick Start

### 1. Prerequisites

- Google Cloud project with BigQuery enabled
- OAuth 2.0 Client ID and API Key
- Access to your crash data tables:
  - Firebase Crashlytics data
  - Sentry error data

### 2. Setup BigQuery View

Run the SQL in `bq/unified_crash_analytics_view.sql` to create the unified analytics view:

```sql
-- Creates: your-project.your-dataset.crash_analytics_dashboard
```

### 3. Configure Authentication

Update `index.html` CONFIG section:

```js
const CONFIG = {
  CLIENT_ID: 'your-oauth-client-id.apps.googleusercontent.com',
  API_KEY: 'your-bigquery-api-key',
  PROJECT_ID: 'your-project-id',
  DATASET_ID: 'your-dataset'
};
```

### 4. Launch Dashboard

**Recommended:** Use the custom server for full OAuth support:

```bash
python3 server.py
```

**Alternative:** Standard Python server:

```bash
python3 -m http.server 8000
```

Visit **http://localhost:8000**

## 🎯 Dashboard Features

### Critical Events Analysis
- **Real-time breadcrumb analysis** showing user actions before crashes
- **5-second critical window** filtering for relevant events
- **Event frequency ranking** to identify common crash triggers
- **Platform comparison** of critical event patterns

### Interactive Crash Breakdown
- **Top 10 crash types** in visual pie chart
- **Complete crash inventory** in scrollable lists
- **Risk scoring** and affected user counts
- **Memory correlation** analysis

### Advanced Filtering
- **Memory Range**: Multi-select from predefined ranges
- **App Versions**: Dynamic loading and multi-selection
- **Date Ranges**: Last N hours, days, or absolute date ranges
- **User Search**: Find crashes for specific user IDs
- **Platform Filter**: iOS, Android, or combined analysis

### Data Export
- **CSV export** of filtered results
- **Complete event data** including all 5 breadcrumb events
- **Filtered user tables** maintaining search context

## 🔧 Technical Architecture

### Frontend
- **Vanilla JavaScript** with Chart.js visualizations
- **Google Identity Services** for authentication
- **Responsive design** with mobile support
- **Real-time data updates** with manual refresh control

### Backend
- **BigQuery** as the primary data warehouse
- **Unified SQL view** combining Crashlytics + Sentry
- **Custom Python server** with CORS support
- **OAuth 2.0** secure authentication

### Data Processing
- **Intelligent crash name cleaning** removes technical noise
- **Platform-specific aggregation** for accurate metrics
- **Breadcrumb parsing** supports multiple data formats
- **Time-based correlation** analysis

## 📂 Project Structure

```
├── index.html              # Main dashboard application
├── server.py               # Custom CORS-enabled server
├── bq/
│   └── unified_crash_analytics_view.sql  # BigQuery view
├── update_view.sql         # Helper for view updates
└── README.md              # This file
```

## 🔍 Usage Guide

### Authentication
1. Click **"Connect to BigQuery"**
2. Complete Google sign-in flow
3. Grant BigQuery access permissions

### Filtering Data
1. **Select filters** (memory, versions, dates, user ID)
2. Click **"Search Results"** to apply filters
3. **View results** in charts and tables
4. **Export data** using the CSV button

### Analyzing Critical Events
1. Check the **"Critical Events"** chart for top 10 events
2. **Scroll through** the complete events list below
3. **Click user rows** to see individual breadcrumb details
4. **Look for patterns** in platform-specific events

### Investigating Crashes
1. Use the **crash names pie chart** for overview
2. **Filter by crash type** (Fatal/Non-Fatal/All)
3. **Examine user details** in the high-risk users table
4. **Search specific users** by ID for deep-dive analysis

## 🛠 Troubleshooting

### Authentication Issues
- **CORS errors**: Use `server.py` instead of basic Python server
- **OAuth redirect**: Ensure authorized origins match your local URL
- **API permissions**: Verify BigQuery API is enabled

### Data Issues
- **No results**: Check BigQuery view exists and has data
- **Missing events**: Verify breadcrumb data format in source tables
- **Performance**: Use filters to limit data scope for large datasets

### Technical Issues
- **Port conflicts**: Change port in `server.py` if 8000 is occupied
- **Memory errors**: Apply date/platform filters for large datasets
- **Chart rendering**: Check browser console for JavaScript errors

## 🚀 Advanced Configuration

### Custom Time Windows
Modify the critical events window in `index.html`:
```js
// Change from 5 seconds to custom value
AND TIMESTAMP_DIFF(...) BETWEEN 0 AND 10  -- 10 seconds
```

### Additional Platforms
Extend platform support by updating the platform detection logic:
```js
const platformIcon = crash.platform === 'IOS' ? '🍎' : 
                     crash.platform === 'ANDROID' ? '🤖' : 
                     crash.platform === 'WEB' ? '🌐' : '❓';
```

## 📊 Data Schema

The dashboard expects specific BigQuery table schemas. Key fields include:
- `user_id`, `distinct_id` - User identification
- `platform` - iOS/ANDROID/etc
- `crash_name`, `error_type` - Crash classification  
- `last_5_breadcrumbs_formatted` - User event timeline
- `memory_free`, `app_display_version` - Device/app context

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test with your BigQuery setup
5. Submit a pull request

## 📄 License

This project is open source. Customize for your crash analytics needs.

---

**Built with ❤️ for better crash analysis and user experience insights.**


