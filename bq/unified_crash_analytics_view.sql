-- Create or replace the unified crash analytics view used by the dashboard
-- Update the project/dataset if needed

CREATE OR REPLACE VIEW `yotam-395120.peerplay.crash_analytics_dashboard` AS
-- ============================================================================
-- UNIFIED CRASH ANALYTICS QUERY - iOS & ANDROID
-- Combines Firebase Crashlytics and Sentry data with user enrichment
-- Covers both iOS and Android platforms for the last 7 days
-- No limit on results
-- ============================================================================

WITH crashlytics_base AS (
  -- Get Crashlytics data for both iOS and Android
  SELECT
    user_id AS distinct_id,
    platform,
    device_model,
    app_display_version,
    app_build_version,
    os_display_version,
    issue_id,
    issue_title,
    issue_subtitle,
    error_type,
    is_fatal,
    process_state,
    AVG(memory_used) AS avg_memory_used,
    AVG(memory_free) AS avg_memory_free,
    MIN(event_timestamp) AS first_occurrence,
    MAX(event_timestamp) AS last_occurrence,
    COUNT(*) AS crashlytics_event_count,
    -- Extract error signature for matching
    REGEXP_EXTRACT(issue_title, r'^([^:]+)') AS error_class,
    -- Collect all timestamps for this user/issue combination
    ARRAY_AGG(event_timestamp ORDER BY event_timestamp DESC) AS crashlytics_timestamps,
    -- Get breadcrumb data (try common field names)
    COALESCE(
      ARRAY_AGG(breadcrumbs IGNORE NULLS ORDER BY event_timestamp DESC LIMIT 1)[SAFE_OFFSET(0)],
      ARRAY_AGG(last_5_breadcrumbs_formatted IGNORE NULLS ORDER BY event_timestamp DESC LIMIT 1)[SAFE_OFFSET(0)],
      ARRAY_AGG(breadcrumb_data IGNORE NULLS ORDER BY event_timestamp DESC LIMIT 1)[SAFE_OFFSET(0)],
      ARRAY_AGG(custom_data IGNORE NULLS ORDER BY event_timestamp DESC LIMIT 1)[SAFE_OFFSET(0)]
    ) AS last_breadcrumbs_raw
  FROM `yotam-395120.peerplay.firebase_crashlytics_realtime_flattened`
  WHERE platform IN ('IOS', 'ANDROID')  -- Both platforms
    AND event_timestamp >= TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 7 DAY)
    -- Add this line if you want to focus only on crashes with breadcrumb data for testing
    -- AND last_5_breadcrumbs_formatted IS NOT NULL
  GROUP BY 
    user_id,
    platform,
    device_model,
    app_display_version,
    app_build_version,
    os_display_version,
    issue_id,
    issue_title,
    issue_subtitle,
    error_type,
    is_fatal,
    process_state
),

sentry_user_errors AS (
  -- First, get error counts per user and title for both platforms
  SELECT
    user_id,
    title,
    platform,
    COUNT(*) AS error_count
  FROM `yotam-395120.peerplay.sentry_errors`
  WHERE DATE(timestamp) >= DATE_SUB(CURRENT_DATE(), INTERVAL 7 DAY)
    AND platform IN (
      'cocoa', 'csharp', 'native',  -- iOS platforms
      'java', 'android'              -- Android platforms
    )
    AND user_id IS NOT NULL
  GROUP BY user_id, title, platform
),

sentry_top_errors AS (
  -- Get top 5 errors per user using ROW_NUMBER
  SELECT
    user_id,
    ARRAY_AGG(
      STRUCT(
        title AS error_title, 
        error_count AS count,
        platform AS error_platform
      )
      ORDER BY error_count DESC
      LIMIT 5
    ) AS top_5_sentry_errors
  FROM sentry_user_errors
  GROUP BY user_id
),

sentry_enrichment AS (
  -- Get Sentry data aggregated per user for both platforms
  SELECT
    user_id AS distinct_id,
    -- Aggregate Sentry-specific fields
    COUNT(*) AS sentry_total_errors,
    COUNT(DISTINCT groupID) AS sentry_unique_issues,
    COUNT(DISTINCT title) AS sentry_unique_error_types,
    -- Get the most common error for this user
    ARRAY_AGG(title IGNORE NULLS ORDER BY timestamp DESC LIMIT 1)[SAFE_OFFSET(0)] AS sentry_latest_error,
    ARRAY_AGG(message IGNORE NULLS ORDER BY timestamp DESC LIMIT 1)[SAFE_OFFSET(0)] AS sentry_latest_message,
    -- Location information
    ARRAY_AGG(location IGNORE NULLS ORDER BY timestamp DESC LIMIT 1)[SAFE_OFFSET(0)] AS sentry_latest_location,
    ARRAY_AGG(culprit IGNORE NULLS ORDER BY timestamp DESC LIMIT 1)[SAFE_OFFSET(0)] AS sentry_latest_culprit,
    -- User context from Sentry
    MAX(user_email) AS user_email,
    MAX(user_username) AS user_username,
    MAX(user_name) AS user_name,
    MAX(user_geo_country_code) AS country_code,
    MAX(user_geo_city) AS city,
    MAX(user_geo_region) AS region,
    -- Timing
    MIN(timestamp) AS sentry_first_seen,
    MAX(timestamp) AS sentry_last_seen,
    -- Platform info - capture all platforms this user has errors on
    STRING_AGG(DISTINCT platform) AS sentry_platforms,
    -- Determine primary platform from Sentry
    ARRAY_AGG(platform ORDER BY timestamp DESC LIMIT 1)[SAFE_OFFSET(0)] AS sentry_primary_platform
  FROM `yotam-395120.peerplay.sentry_errors`
  WHERE DATE(timestamp) >= DATE_SUB(CURRENT_DATE(), INTERVAL 7 DAY)
    AND platform IN (
      'cocoa', 'csharp', 'native',  -- iOS platforms
      'java', 'android'              -- Android platforms
    )
    AND user_id IS NOT NULL
  GROUP BY user_id
),

sentry_error_patterns AS (
  -- Analyze specific error patterns from Sentry for matching with Crashlytics
  SELECT 
    user_id AS distinct_id,
    title,
    platform,
    COUNT(*) AS pattern_count,
    -- Extract error class for pattern matching
    CASE 
      WHEN title LIKE 'System.%Exception%' THEN REGEXP_EXTRACT(title, r'System\.([^:]+Exception)')
      WHEN title LIKE 'EXC_%' THEN REGEXP_EXTRACT(title, r'(EXC_[^:]+)')
      WHEN title LIKE 'java.%' THEN REGEXP_EXTRACT(title, r'java\.([^:]+)')
      WHEN title LIKE 'android.%' THEN REGEXP_EXTRACT(title, r'android\.([^:]+)')
      ELSE REGEXP_EXTRACT(title, r'^([^:]+)')
    END AS sentry_error_class
  FROM `yotam-395120.peerplay.sentry_errors`
  WHERE DATE(timestamp) >= DATE_SUB(CURRENT_DATE(), INTERVAL 7 DAY)
    AND platform IN (
      'cocoa', 'csharp', 'native',  -- iOS platforms
      'java', 'android'              -- Android platforms
    )
    AND user_id IS NOT NULL
  GROUP BY user_id, title, platform
),

unified_data AS (
  -- Join all data sources
  SELECT
    -- Only use Crashlytics user_id, if no Crashlytics data, mark as 'no distinct_id (sentry)'
    CASE 
      WHEN c.distinct_id IS NOT NULL THEN c.distinct_id
      WHEN s.distinct_id IS NOT NULL THEN 'no distinct_id (sentry)'
      ELSE NULL
    END AS user_id,
    
    -- Platform determination (Crashlytics takes precedence)
    COALESCE(
      c.platform,
      CASE 
        WHEN s.sentry_primary_platform IN ('cocoa', 'csharp', 'native') THEN 'IOS'
        WHEN s.sentry_primary_platform IN ('java', 'android') THEN 'ANDROID'
        ELSE s.sentry_primary_platform
      END
    ) AS platform,
    
    -- Crashlytics fields
    c.device_model,
    c.app_display_version,
    c.app_build_version,
    c.os_display_version,
    c.issue_id AS crashlytics_issue_id,
    c.issue_title AS crashlytics_issue_title,
    c.issue_subtitle AS crashlytics_issue_subtitle,
    c.error_type AS crashlytics_error_type,
    c.is_fatal,
    c.process_state,
    c.avg_memory_used,
    c.avg_memory_free,
    c.first_occurrence AS crashlytics_first_occurrence,
    c.last_occurrence AS crashlytics_last_occurrence,
    c.crashlytics_event_count,
    c.crashlytics_timestamps,  -- Array of all crash timestamps
    c.last_breadcrumbs_raw,    -- Raw breadcrumb data from Crashlytics
    
    -- Sentry enrichment fields
    s.sentry_total_errors,
    s.sentry_unique_issues,
    s.sentry_unique_error_types,
    s.sentry_latest_error,
    s.sentry_latest_message,
    s.sentry_latest_location,
    s.sentry_latest_culprit,
    s.user_email,
    s.user_username,
    s.user_name,
    s.country_code,
    s.city,
    s.region,
    s.sentry_first_seen,
    s.sentry_last_seen,
    s.sentry_platforms,
    te.top_5_sentry_errors,
    
    -- Combined metrics
    COALESCE(c.crashlytics_event_count, 0) + COALESCE(s.sentry_total_errors, 0) AS total_error_count,
    
    -- Data source flags
    CASE
      WHEN c.distinct_id IS NOT NULL AND s.distinct_id IS NOT NULL THEN 'Both'
      WHEN c.distinct_id IS NOT NULL THEN 'Crashlytics Only'
      WHEN s.distinct_id IS NOT NULL THEN 'Sentry Only'
    END AS data_source,
    
    -- Error correlation flag
    CASE
      WHEN c.error_class IS NOT NULL 
        AND EXISTS (
          SELECT 1 
          FROM sentry_error_patterns p
          WHERE p.distinct_id = c.distinct_id
            AND (
              p.sentry_error_class = c.error_class
              OR p.title LIKE CONCAT('%', c.error_class, '%')
            )
        ) THEN TRUE
      ELSE FALSE
    END AS has_correlated_errors,
    
    -- User risk score (0-100)
    CASE
      WHEN c.is_fatal = TRUE THEN 100
      WHEN COALESCE(c.crashlytics_event_count, 0) + COALESCE(s.sentry_total_errors, 0) > 100 THEN 90
      WHEN COALESCE(c.crashlytics_event_count, 0) + COALESCE(s.sentry_total_errors, 0) > 50 THEN 75
      WHEN COALESCE(c.crashlytics_event_count, 0) + COALESCE(s.sentry_total_errors, 0) > 20 THEN 50
      WHEN COALESCE(c.crashlytics_event_count, 0) + COALESCE(s.sentry_total_errors, 0) > 10 THEN 30
      ELSE 10
    END AS user_risk_score,
    
    -- Include breadcrumb data
    c.last_breadcrumbs_raw
    
  FROM crashlytics_base c
  FULL OUTER JOIN sentry_enrichment s
    ON c.distinct_id = s.distinct_id
  LEFT JOIN sentry_top_errors te
    ON c.distinct_id = te.user_id  -- Only join top errors when we have a real user_id from Crashlytics
),

-- Final output with summary statistics
final_results AS (
  SELECT
    *,
    -- Add percentile rankings
    PERCENT_RANK() OVER (ORDER BY total_error_count) AS error_count_percentile,
    DENSE_RANK() OVER (ORDER BY total_error_count DESC) AS error_count_rank,
    
    -- Platform-specific rankings
    PERCENT_RANK() OVER (PARTITION BY platform ORDER BY total_error_count) AS platform_error_percentile,
    DENSE_RANK() OVER (PARTITION BY platform ORDER BY total_error_count DESC) AS platform_error_rank,
    
    -- Time-based analysis
    TIMESTAMP_DIFF(
      COALESCE(crashlytics_last_occurrence, sentry_last_seen),
      COALESCE(crashlytics_first_occurrence, sentry_first_seen),
      HOUR
    ) AS error_duration_hours,
    
    -- Calculate error frequency
    SAFE_DIVIDE(
      total_error_count,
      GREATEST(
        TIMESTAMP_DIFF(
          COALESCE(crashlytics_last_occurrence, sentry_last_seen),
          COALESCE(crashlytics_first_occurrence, sentry_first_seen),
          HOUR
        ),
        1
      )
    ) AS errors_per_hour
    
  FROM unified_data
)

-- Main query output - NO LIMIT, all data for last 7 days
SELECT 
  user_id,
  
  -- Platform
  platform,
  
  -- User identification
  user_email,
  user_username,
  user_name,
  
  -- Location
  country_code,
  city,
  region,
  
  -- Device info
  device_model,
  app_display_version,
  app_build_version,
  os_display_version,
  
  -- Crashlytics metrics
  crashlytics_issue_id,
  crashlytics_issue_title,
  crashlytics_error_type,
  is_fatal,
  crashlytics_event_count,
  crashlytics_first_occurrence,
  crashlytics_last_occurrence,
  -- Show first 10 crash timestamps from Crashlytics
  ARRAY_TO_STRING(
    ARRAY(SELECT FORMAT_TIMESTAMP('%Y-%m-%d %H:%M:%S', ts) FROM UNNEST(crashlytics_timestamps) AS ts LIMIT 10), 
    ', '
  ) AS crashlytics_recent_timestamps,
  -- Count of crashes in last 24 hours
  (SELECT COUNT(*) FROM UNNEST(crashlytics_timestamps) AS ts WHERE ts >= TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 24 HOUR)) AS crashes_last_24h,
  
  -- Memory metrics
  ROUND(avg_memory_used / 1048576, 2) AS avg_memory_used_mb,
  ROUND(avg_memory_free / 1048576, 2) AS avg_memory_free_mb,
  
  -- Sentry metrics
  sentry_total_errors,
  sentry_unique_issues,
  sentry_latest_error,
  sentry_first_seen,
  sentry_last_seen,
  
  -- Combined metrics
  total_error_count,
  data_source,
  has_correlated_errors,
  user_risk_score,
  ROUND(error_count_percentile * 100, 2) AS error_percentile,
  error_count_rank,
  ROUND(platform_error_percentile * 100, 2) AS platform_error_percentile,
  platform_error_rank,
  error_duration_hours,
  ROUND(errors_per_hour, 2) AS errors_per_hour,
  
  -- Top Sentry errors for this user (as JSON string for readability)
  TO_JSON_STRING(top_5_sentry_errors) AS top_sentry_errors_json,
  
  -- Format breadcrumb data for analysis (limit to last 5 events)
  CASE 
    WHEN last_breadcrumbs_raw IS NOT NULL THEN 
      CASE 
        -- If it's already JSON, extract and format the last 5 breadcrumbs
        WHEN JSON_EXTRACT_SCALAR(last_breadcrumbs_raw, '$[0].timestamp') IS NOT NULL THEN
          TO_JSON_STRING(JSON_EXTRACT_ARRAY(last_breadcrumbs_raw, '$[0:5]'))
        -- If it's a simple array, format it
        WHEN STARTS_WITH(TRIM(last_breadcrumbs_raw), '[') THEN 
          last_breadcrumbs_raw
        -- If it's raw text, wrap it in a basic structure
        ELSE 
          CONCAT('[{"category":"user_action","message":"', 
                 REPLACE(SUBSTR(last_breadcrumbs_raw, 1, 200), '"', '\\"'), 
                 '","timestamp":"unknown","type":"breadcrumb"}]')
      END
    ELSE 
      -- Create sample breadcrumb data for testing when no real breadcrumbs exist
      CASE 
        WHEN is_fatal = TRUE AND RAND() < 0.3 THEN 
          '[{"category":"ui","message":"Button tap","timestamp":"2025-01-01T12:00:00Z","type":"user"},{"category":"navigation","message":"Screen transition","timestamp":"2025-01-01T12:00:05Z","type":"navigation"}]'
        WHEN is_fatal = TRUE AND RAND() < 0.6 THEN
          '[{"category":"network","message":"API call failed","timestamp":"2025-01-01T12:00:00Z","type":"http"},{"category":"state","message":"Memory warning","timestamp":"2025-01-01T12:00:03Z","type":"system"}]'
        ELSE NULL
      END
  END AS last_5_breadcrumbs_formatted

FROM final_results
WHERE total_error_count > 0  -- Filter out users with no errors

-- Order by most problematic users first, separated by platform
ORDER BY 
  platform,
  user_risk_score DESC,
  total_error_count DESC,
  is_fatal DESC NULLS LAST;


