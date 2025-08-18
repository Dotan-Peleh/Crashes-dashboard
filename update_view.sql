-- Test and update the BigQuery view to include breadcrumb data
-- Run this in BigQuery Console to update the view with breadcrumb support

-- First, let's test if the breadcrumb field exists in the source table
SELECT 
  'Testing breadcrumb field availability...' as status,
  COUNT(*) as total_rows,
  COUNT(last_5_breadcrumbs_formatted) as rows_with_breadcrumbs,
  COUNT(CASE WHEN last_5_breadcrumbs_formatted IS NOT NULL AND last_5_breadcrumbs_formatted != '' THEN 1 END) as rows_with_data
FROM `yotam-395120.peerplay.firebase_crashlytics_realtime_flattened`
WHERE platform IN ('IOS', 'ANDROID')
  AND event_timestamp >= TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 7 DAY)
LIMIT 1;

-- If the above query works and shows breadcrumb data, run the view update below:
-- (Copy the entire content from bq/unified_crash_analytics_view.sql and run it in BigQuery Console)
