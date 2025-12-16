package io.mcp.cncf.util;

import io.quarkus.logging.Log;

/**
 * Simple, focused error handling for CNCF MCP.
 * Only what's needed - no over-engineering.
 */
public final class ErrorHandler {

    private ErrorHandler() {
        // Utility class
    }

    /**
     * Get user-friendly error message.
     * Simple switch expressions - no complex pattern matching needed.
     */
    public static String getFriendlyMessage(Throwable error) {
        if (error instanceof jakarta.ws.rs.WebApplicationException webEx) {
            int status = webEx.getResponse().getStatus();
            return switch (status) {
                case 404 -> "🔍 Project not found. Check the CNCF project name and try again.";
                case 429 -> "⏱️ Rate limit exceeded. Please wait a moment before making more requests.";
                case 500 -> "🔧 CNCF Landscape API is experiencing issues. Please try again later.";
                default -> "⚠️ Request failed: " + webEx.getMessage();
            };
        }

        if (error instanceof java.net.ConnectException) {
            return "🌐 Cannot connect to CNCF Landscape API. Please check your internet connection.";
        }

        if (error instanceof java.util.concurrent.TimeoutException) {
            return "⏰ Request timeout. The CNCF service may be experiencing high load.";
        }

        if (error instanceof IllegalArgumentException) {
            return "❌ Invalid request: " + error.getMessage();
        }

        if (error instanceof com.fasterxml.jackson.core.JsonProcessingException) {
            return "📄 Error parsing CNCF data. The data format may have changed recently.";
        }

        // Default case
        return "💥 An error occurred: " + error.getMessage();
    }

    /**
     * Log error with appropriate level.
     */
    public static void logError(String operation, Throwable error) {
        String friendlyMessage = getFriendlyMessage(error);

        if (error instanceof java.net.ConnectException ||
            error instanceof java.util.concurrent.TimeoutException) {
            Log.warnf("%s: %s", operation, friendlyMessage);
        } else if (error instanceof jakarta.ws.rs.WebApplicationException webEx) {
            int status = webEx.getResponse().getStatus();
            if (status >= 500) {
                Log.errorf("%s: %s (HTTP %s)", operation, friendlyMessage, status);
            } else {
                Log.infof("%s: %s (HTTP %s)", operation, friendlyMessage, status);
            }
        } else if (error instanceof IllegalArgumentException) {
            Log.debugf("%s: %s", operation, friendlyMessage);
        } else {
            Log.errorf("%s: %s", operation, friendlyMessage);
        }
    }

    /**
     * Create error response for MCP tool.
     */
    public static io.quarkiverse.mcp.server.ToolResponse createErrorResponse(String operation, Throwable error) {
        logError(operation, error);
        return io.quarkiverse.mcp.server.ToolResponse.error(getFriendlyMessage(error));
    }

    /**
     * Simple check if error is recoverable.
     */
    public static boolean isRecoverable(Throwable error) {
        return error instanceof java.net.ConnectException ||
               error instanceof java.util.concurrent.TimeoutException ||
               error instanceof jakarta.ws.rs.WebApplicationException webEx &&
               webEx.getResponse().getStatus() >= 500;
    }

    /**
     * Simple retry delay based on error type.
     */
    public static long getRetryDelayMs(Throwable error) {
        if (error instanceof jakarta.ws.rs.WebApplicationException webEx) {
            int status = webEx.getResponse().getStatus();
            return switch (status) {
                case 429 -> 5000;  // 5 seconds for rate limit
                case 503 -> 2000;  // 2 seconds for service unavailable
                default -> 1000;  // 1 second default
            };
        }

        if (error instanceof java.net.ConnectException) {
            return 3000; // 3 seconds for connection issues
        }

        if (error instanceof java.util.concurrent.TimeoutException) {
            return 1000; // 1 second for timeout
        }

        return 1000; // Default 1 second
    }

    /**
     * Get error severity for monitoring.
     */
    public static ErrorSeverity getSeverity(Throwable error) {
        if (error instanceof IllegalArgumentException ||
            error instanceof SecurityException) {
            return ErrorSeverity.LOW;
        }

        if (error instanceof java.net.ConnectException ||
            error instanceof java.util.concurrent.TimeoutException) {
            return ErrorSeverity.MEDIUM;
        }

        if (error instanceof jakarta.ws.rs.WebApplicationException webEx) {
            return webEx.getResponse().getStatus() >= 500 ? ErrorSeverity.HIGH : ErrorSeverity.MEDIUM;
        }

        if (error instanceof RuntimeException) {
            return ErrorSeverity.HIGH;
        }

        return ErrorSeverity.MEDIUM;
    }

    /**
     * Error severity levels for monitoring.
     */
    public enum ErrorSeverity {
        LOW, MEDIUM, HIGH
    }
}