# Live Crash Analytics Dashboard (BigQuery + Chart.js)

A lightweight, client-only dashboard that authenticates with Google and queries BigQuery to visualize unified crash data from Firebase Crashlytics and Sentry.

## Prerequisites

- A Google Cloud project with BigQuery enabled
- The datasets/tables referenced by the view:
  - `yotam-395120.peerplay.firebase_crashlytics_realtime_flattened`
  - `yotam-395120.peerplay.sentry_errors`
- OAuth 2.0 Client ID (Web) and an API Key
- The provided SQL view deployed as `peerplay.crash_analytics_dashboard`

## 1) Create the BigQuery View

Open BigQuery Console and run the SQL in:

- `bq/unified_crash_analytics_view.sql`

This creates/overwrites the view:

- `yotam-395120.peerplay.crash_analytics_dashboard`

You can adjust the project/dataset names in the SQL as needed.

## 2) Configure OAuth and API Key

1. In Google Cloud Console → APIs & Services → Credentials
2. Create Credentials → OAuth client ID → Application type: Web application
3. Add Authorized JavaScript origins for your local dev origin, e.g.:
   - `http://localhost:8080`
   - `http://127.0.0.1:8080`
4. Create an API key.
5. Enable APIs → Enable BigQuery API for your project.

Update `index.html` CONFIG:

```js
const CONFIG = {
  CLIENT_ID: '57935720907-du91l7v9gj0i4nbpl3otal7f2ti88c8m.apps.googleusercontent.com',
  API_KEY: 'AIzaSyCXhemEKZQzP3_jhkB9Stc81-zmR-Bdxus',
  PROJECT_ID: 'yotam-395120',
  DATASET_ID: 'peerplay'
};
```

## 3) Serve Locally

Any static server works. Example using Python:

```bash
# From the project directory
python3 -m http.server 8080
```

Or using `npx`:

```bash
npx serve -l 8080
```

Then open `http://localhost:8080`.

## 4) Use the Dashboard

- Click “Connect to BigQuery” and complete Google sign-in.
- Pick filters; click “Refresh Data” (or enable auto-refresh).
- The page queries the view and renders:
  - Total Crashes
  - Affected Users
  - Fatal Crashes
  - Avg Risk Score
  - Crash Trend (line)
  - Platform Distribution (doughnut)

## Notes

- The dashboard reads from the view for performance and consistent schema. Adjust the view to change/extend metrics.
- The view currently scopes to the last 7 days. You can adapt logic or add a parameterized table function for flexible ranges.
- Because this is a client-only app, ensure your OAuth/Key restrictions are appropriate.

## Troubleshooting

- If auth seems stuck, check browser console for OAuth/redirect origin errors.
- If BigQuery calls fail: verify BigQuery API is enabled, credentials are correct, and your user has `roles/bigquery.readSessionUser` and `roles/bigquery.dataViewer` or equivalent.
- CORS errors typically indicate an origin misconfiguration in OAuth credentials.


