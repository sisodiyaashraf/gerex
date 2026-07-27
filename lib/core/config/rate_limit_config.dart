class RateLimitConfig {
  // Auth Attempt Limits
  static const int authMaxFailedAttempts = 5;
  static const int authBaseBackoffMs = 2000; // 2 seconds base
  static const int authMaxBackoffMs = 60000; // 1 minute maximum delay

  // Throttling durations (Debounce windows)
  static const int readThrottleDurationMs = 1500;
  static const int writeThrottleDurationMs = 2000;

  // AI Call Caps (Gemini free quota protection)
  static const int aiMaxCallsPerHour = 10;
  static const int aiCallsWindowHours = 1;
}
