# 🚀 Universal Dashboard Template

A powerful, configurable dashboard template for BigQuery analytics. Built with the advanced filtering, visualization, and user experience patterns from our crash analytics dashboard - now reusable for any data analysis use case.

## ✨ Template Features

### 🎯 **What's Included**
- **Advanced filtering system** with multi-select, date ranges, and search
- **Top 10 + comprehensive list pattern** for all chart types
- **Platform-aware visualizations** with emojis and color coding
- **Manual search button** for performance (no auto-refresh)
- **20-color distinct palette** for clear visual separation
- **Responsive design** with professional styling
- **Custom CORS server** for Google OAuth integration
- **Export functionality** with CSV download
- **Robust error handling** and data validation

### 🏗️ **Architecture**
```
📁 Universal Dashboard Template/
├── 📄 dashboard-template.html    # Main configurable template
├── 🐍 server.py                 # Enhanced CORS server
├── 📋 template-bigquery-view.sql # BigQuery view pattern
├── 📚 README.md                 # This documentation
└── 📂 examples/                 # Configuration examples
    ├── 🔥 crash-analytics-config.js   # Crash/error analytics
    ├── 👥 user-analytics-config.js    # User behavior analytics  
    └── 💰 sales-analytics-config.js   # Sales/revenue analytics
```

## 🚀 Quick Start

### 1. **Copy Template Files**
```bash
# Copy the template to your new project
cp -r "Dashboard Template" "My New Dashboard"
cd "My New Dashboard"
```

### 2. **Configure Your Dashboard**
Edit `dashboard-template.html` and update the `DASHBOARD_CONFIG` section:

```javascript
const DASHBOARD_CONFIG = {
    title: 'My Analytics Dashboard',
    CLIENT_ID: 'your-oauth-client-id.apps.googleusercontent.com',
    API_KEY: 'your-bigquery-api-key', 
    PROJECT_ID: 'your-project-id',
    DATASET_ID: 'your-dataset',
    VIEW_NAME: 'your-analytics-view'
};
```

### 3. **Launch Your Dashboard**
```bash
python3 server.py
# Visit http://localhost:8000
```

See the `examples/` directory for complete configuration examples for different dashboard types.

## 📞 **Support**

This template is based on proven patterns from production analytics dashboards. Whether you're building crash analytics, user behavior dashboards, sales reports, or any other data visualization tool - this template provides the proven foundation.

🎯 **Start building your next dashboard in minutes, not weeks!**

## 🌍 Country Filtering and Breakdown

- **Country filter**: Multi-select countries to constrain all metrics and charts (uses `country_code`).
- **Top Countries chart**: Bar chart of the top countries by total events under current filters.

### URL Parameters
The dashboard syncs filters to the URL so you can share exact views.
- `dateType`: `relative` | `absolute`
- `dateRange`: `hour` | `1` | `3` | `7` | `14` | `30` | `custom_hours`
- `from`, `to`: YYYY-MM-DD (when `dateType=absolute`)
- `hours`: number (when `dateRange=custom_hours`)
- `platform`: `IOS` | `ANDROID`
- `risk`: minimum user risk score (e.g. `75`)
- `source`: `Both` | `Crashlytics Only` | `Sentry Only`
- `crash`: `fatal` | `non-fatal`
- `memory`: comma-separated memory categories (`critical,low,medium,good,excellent`)
- `country`: comma-separated country codes (e.g. `US,CA`)
- `appVersion`: comma-separated app display versions (e.g. `1.2.3,1.3.0`)
- `user`: distinct user id filter

### Compare versions within a country
1) Pick a country in the Country filter (e.g., `US`).
2) Select the two app versions in the App Version filter.
3) Click Search. All charts/tables reflect the selected country and versions.

Tip: The Error Events Trend and Top App Versions breakdown are constrained by country when the Country filter is set.