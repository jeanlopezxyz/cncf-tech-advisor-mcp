package io.mcp.cncf.config;

/**
 * Configuration constants for search and scoring algorithms.
 * Contains only essential constants used by the application.
 */
public final class SearchConstants {

    private SearchConstants() {
        // Utility class - prevent instantiation
    }

    // Search limits
    public static final int DEFAULT_SEARCH_LIMIT = 50;
    public static final int MAX_SEARCH_RESULTS = 100;

    // Scoring thresholds
    public static final double CONFIDENCE_THRESHOLD = 0.5;

    // Project maturity values
    public static final String MATURITY_SANDBOX = "sandbox";
    public static final String MATURITY_INCUBATING = "incubating";
    public static final String MATURITY_GRADUATED = "graduated";

    // Technology matching thresholds
    public static final int MIN_QUERY_LENGTH = 2;
}