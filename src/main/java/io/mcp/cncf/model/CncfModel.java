package io.mcp.cncf.model;

import io.mcp.cncf.config.SearchConstants;
import java.time.Instant;
import java.util.List;
import java.util.Objects;

/**
 * Essential CNCF data models for MCP server.
 * Only what's actually used - no over-engineering.
 */
public final class CncfModel {

    /**
     * Core CNCF project record.
     */
    public record CncfProject(
        String id,
        String name,
        String category,
        String subcategory,
        String description,
        String homepageUrl,
        String repoUrl,
        String maturity,
        List<String> tags,
        ProjectMetadata metadata
    ) {
        public CncfProject {
            Objects.requireNonNull(id, "Project ID cannot be null");
            Objects.requireNonNull(name, "Project name cannot be null");
            Objects.requireNonNull(category, "Project category cannot be null");

            if (id.isBlank()) throw new IllegalArgumentException("Project ID cannot be empty");
            if (name.isBlank()) throw new IllegalArgumentException("Project name cannot be empty");
            if (category.isBlank()) throw new IllegalArgumentException("Project category cannot be empty");
        }

        public boolean isPopular() {
            return metadata != null && metadata.stars() >= 1000;
        }

        public String getQualityRating() {
            if (metadata == null) return "⭐⭐";

            double stars = metadata.stars();
            if (stars >= 10000) return "⭐⭐⭐⭐⭐";
            if (stars >= 1000) return "⭐⭐⭐⭐";
            if (stars >= 100) return "⭐⭐⭐";
            return "⭐⭐";
        }

        public boolean isGraduated() {
            return SearchConstants.MATURITY_GRADUATED.equalsIgnoreCase(maturity);
        }
    }

    /**
     * Project metadata.
     */
    public record ProjectMetadata(
        String creationDate,
        String acceptanceDate,
        String graduationDate,
        String latestVersion,
        String license,
        String organization,
        List<String> maintainers,
        List<String> companies,
        double stars,
        double forks,
        String contributors,
        String openIssues,
        String crdbBacked,
        String endUserSupport,
        String repoUrl,
        String homepage,
        Instant lastCommitDate,
        int contributorCount
    ) {
        public ProjectMetadata {
            if (stars < 0) throw new IllegalArgumentException("Stars cannot be negative");
            if (forks < 0) throw new IllegalArgumentException("Forks cannot be negative");
            if (contributorCount < 0) throw new IllegalArgumentException("Contributor count cannot be negative");
            Objects.requireNonNull(maintainers, "Maintainers cannot be null");
            Objects.requireNonNull(companies, "Companies cannot be null");
        }

        public boolean isActivelyMaintained() {
            return lastCommitDate != null &&
                   lastCommitDate.isAfter(Instant.now().minusSeconds(90 * 24 * 60 * 60));
        }
    }

    /**
     * Search query.
     */
    public record SearchQuery(
        String keyword,
        String category,
        String tag,
        String maturityLevel,
        int limit
    ) {
        public SearchQuery {
            if (limit <= 0 || limit > SearchConstants.MAX_SEARCH_RESULTS) {
                throw new IllegalArgumentException("Limit must be between 1 and " + SearchConstants.MAX_SEARCH_RESULTS);
            }
            if (keyword != null && keyword.length() < SearchConstants.MIN_QUERY_LENGTH) {
                throw new IllegalArgumentException("Keyword must be at least " + SearchConstants.MIN_QUERY_LENGTH + " characters");
            }
        }

        public boolean hasFilters() {
            return keyword != null && !keyword.isBlank();
        }

        public String getScope() {
            if (category != null && !category.isBlank()) {
                return "category: " + category;
            }
            return keyword != null ? "keyword: " + keyword : "all projects";
        }
    }

    /**
     * Search result.
     */
    public record SearchResult(
        CncfProject project,
        double relevanceScore,
        String matchedField,
        SearchQuery originalQuery
    ) {
        public SearchResult {
            if (relevanceScore < 0 || relevanceScore > 100) {
                throw new IllegalArgumentException("Relevance score must be between 0 and 100");
            }
            Objects.requireNonNull(project, "Project cannot be null");
        }

        public boolean isHighRelevance() {
            return relevanceScore >= SearchConstants.CONFIDENCE_THRESHOLD;
        }

        public String getSummary() {
            return project.name() + " (" + project.category() + ") - Score: " + String.format("%.1f", relevanceScore);
        }
    }

    /**
     * Calculate relevance score for search.
     */
    public static double calculateRelevanceScore(String query, CncfProject project) {
        double score = 0.0;

        if (query == null || query.isBlank()) {
            return 0.0;
        }

        String lowerQuery = query.toLowerCase();

        // Name matching (highest weight)
        if (project.name().toLowerCase().contains(lowerQuery)) {
            score += 40;
        }

        // Description matching
        if (project.description() != null &&
            project.description().toLowerCase().contains(lowerQuery)) {
            score += 25;
        }

        // Tag matching
        if (project.tags() != null) {
            long tagMatches = project.tags().stream()
                .filter(tag -> tag.toLowerCase().contains(lowerQuery))
                .count();
            score += tagMatches * 10;
        }

        // Category matching
        if (project.category().toLowerCase().contains(lowerQuery)) {
            score += 20;
        }

        // Popularity boost
        if (project.isPopular()) {
            score += 15;
        }

        // Graduation boost
        if (project.isGraduated()) {
            score += 10;
        }

        return Math.min(score, 100.0);
    }

    private CncfModel() {
        // Utility class
    }
}