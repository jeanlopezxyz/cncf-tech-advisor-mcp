package io.mcp.cncf.tool;

import io.mcp.cncf.client.CncfLandscapeClient;
import io.mcp.cncf.config.SearchConstants;
import io.mcp.cncf.model.CncfModel.*;
import io.mcp.cncf.service.CncfDataRefreshService;
import io.mcp.cncf.util.ErrorHandler;
import io.quarkiverse.mcp.server.TextContent;
import io.quarkiverse.mcp.server.Tool;
import io.quarkiverse.mcp.server.ToolResponse;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.inject.Inject;
import org.eclipse.microprofile.rest.client.inject.RestClient;

import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.concurrent.CompletableFuture;

/**
 * Simple CNCF Tech Advisor MCP Tool.
 * Provides essential CNCF project search functionality.
 * Clean, focused, production-ready.
 */
@ApplicationScoped
public class CncfTool {

    @RestClient
    @Inject
    CncfLandscapeClient client;

    
    @Inject
    CncfDataRefreshService refreshService;

    /**
     * Search CNCF projects by keyword or category.
     */
    @Tool(name = "search_cncf", description = "Search CNCF projects by keyword or category")
    public ToolResponse searchCncfProjects(String query, String category, Integer limit) {
        try {
            // Ensure data is fresh
            refreshService.refreshData();

            // Get current projects
            List<CncfProject> projects = refreshService.getCurrentProjects();
            if (projects.isEmpty()) {
                return ToolResponse.error("No CNCF projects available. Please try again later.");
            }

            // Create search query
            SearchQuery searchQuery = new SearchQuery(
                query != null && !query.trim().isEmpty() ? query : null,
                category != null && !category.trim().isEmpty() ? category : null,
                null, // tag filter
                null, // maturity filter
                limit != null && limit > 0 ? Math.min(limit, SearchConstants.MAX_SEARCH_RESULTS) : SearchConstants.DEFAULT_SEARCH_LIMIT
            );

            // Perform search
            List<SearchResult> results = performSearch(projects, searchQuery);

            // Format results
            StringBuilder output = new StringBuilder();
            output.append("## CNCF Project Search Results\n\n");

            if (results.isEmpty()) {
                output.append("No projects found matching your criteria.\n");
            } else {
                output.append("Found ").append(results.size()).append(" projects:\n\n");

                for (SearchResult result : results) {
                    CncfProject project = result.project();
                    output.append("### ").append(project.name()).append("\n");
                    output.append("**Category:** ").append(project.category()).append("\n");

                    if (project.subcategory() != null && !project.subcategory().isEmpty()) {
                        output.append("**Subcategory:** ").append(project.subcategory()).append("\n");
                    }

                    if (project.description() != null && !project.description().isEmpty()) {
                        output.append("**Description:** ").append(project.description()).append("\n");
                    }

                    output.append("**Maturity:** ").append(project.maturity()).append("\n");
                    output.append("**Quality Rating:** ").append(project.getQualityRating()).append("\n");

                    if (project.homepageUrl() != null && !project.homepageUrl().isEmpty()) {
                        output.append("**Homepage:** ").append(project.homepageUrl()).append("\n");
                    }

                    if (project.repoUrl() != null && !project.repoUrl().isEmpty()) {
                        output.append("**Repository:** ").append(project.repoUrl()).append("\n");
                    }

                    output.append("**Relevance Score:** ").append(String.format("%.1f", result.relevanceScore())).append("\n");
                    output.append("\n---\n\n");
                }
            }

            return ToolResponse.success(List.of(new TextContent(output.toString())));

        } catch (Exception e) {
            return ErrorHandler.createErrorResponse("search_cncf", e);
        }
    }

    /**
     * Get information about a specific CNCF project.
     */
    @Tool(name = "get_cncf_project", description = "Get detailed information about a specific CNCF project")
    public ToolResponse getCncfProject(String projectName) {
        try {
            if (projectName == null || projectName.trim().isEmpty()) {
                return ToolResponse.error("Project name is required");
            }

            // Ensure data is fresh
            refreshService.refreshData();

            // Search for the project
            List<CncfProject> projects = refreshService.getCurrentProjects();
            CncfProject foundProject = null;

            for (CncfProject project : projects) {
                if (project.name().equalsIgnoreCase(projectName.trim())) {
                    foundProject = project;
                    break;
                }
            }

            if (foundProject == null) {
                return ToolResponse.error("Project '" + projectName + "' not found in CNCF Landscape");
            }

            // Format project details
            StringBuilder output = new StringBuilder();
            output.append("## ").append(foundProject.name()).append("\n\n");

            output.append("**Category:** ").append(foundProject.category()).append("\n");
            if (foundProject.subcategory() != null && !foundProject.subcategory().isEmpty()) {
                output.append("**Subcategory:** ").append(foundProject.subcategory()).append("\n");
            }

            output.append("**Description:** ").append(foundProject.description()).append("\n");
            output.append("**Maturity Level:** ").append(foundProject.maturity()).append("\n");
            output.append("**Quality Rating:** ").append(foundProject.getQualityRating()).append("\n");

            if (foundProject.metadata() != null) {
                var metadata = foundProject.metadata();
                output.append("**Stars:** ").append(String.format("%.0f", metadata.stars())).append("\n");
                output.append("**Forks:** ").append(String.format("%.0f", metadata.forks())).append("\n");
                output.append("**Contributors:** ").append(metadata.contributorCount()).append("\n");

                if (metadata.latestVersion() != null && !metadata.latestVersion().isEmpty()) {
                    output.append("**Latest Version:** ").append(metadata.latestVersion()).append("\n");
                }

                if (metadata.license() != null && !metadata.license().isEmpty()) {
                    output.append("**License:** ").append(metadata.license()).append("\n");
                }

                output.append("**Actively Maintained:** ").append(metadata.isActivelyMaintained() ? "Yes" : "No").append("\n");
            }

            if (foundProject.homepageUrl() != null && !foundProject.homepageUrl().isEmpty()) {
                output.append("**Homepage:** ").append(foundProject.homepageUrl()).append("\n");
            }

            if (foundProject.repoUrl() != null && !foundProject.repoUrl().isEmpty()) {
                output.append("**Repository:** ").append(foundProject.repoUrl()).append("\n");
            }

            if (foundProject.tags() != null && !foundProject.tags().isEmpty()) {
                output.append("**Tags:** ").append(String.join(", ", foundProject.tags())).append("\n");
            }

            return ToolResponse.success(List.of(new TextContent(output.toString())));

        } catch (Exception e) {
            return ErrorHandler.createErrorResponse("get_cncf_project", e);
        }
    }

    /**
     * List all CNCF categories.
     */
    @Tool(name = "list_cncf_categories", description = "List all available CNCF project categories")
    public ToolResponse listCncfCategories() {
        try {
            // Ensure data is fresh
            refreshService.refreshData();

            // Get projects and extract categories
            List<CncfProject> projects = refreshService.getCurrentProjects();
            Map<String, Integer> categoryCounts = new java.util.HashMap<>();

            for (CncfProject project : projects) {
                categoryCounts.merge(project.category(), 1, Integer::sum);
            }

            // Format categories
            StringBuilder output = new StringBuilder();
            output.append("## CNCF Project Categories\n\n");
            output.append("Total projects: ").append(projects.size()).append("\n\n");

            categoryCounts.entrySet().stream()
                .sorted(Map.Entry.<String, Integer>comparingByValue().reversed())
                .forEach(entry -> output
                    .append("- **").append(entry.getKey()).append("** (").append(entry.getValue()).append(" projects)\n"));

            return ToolResponse.success(List.of(new TextContent(output.toString())));

        } catch (Exception e) {
            return ErrorHandler.createErrorResponse("list_cncf_categories", e);
        }
    }

    /**
     * Refresh CNCF data from the landscape API.
     */
    @Tool(name = "refresh_cncf_data", description = "Refresh CNCF project data from the landscape API")
    public CompletableFuture<ToolResponse> refreshCncfData() {
        return refreshService.refreshDataAsync()
            .thenApply(success -> {
                if (success) {
                    var stats = refreshService.getStatistics();
                    String message = "CNCF data refreshed successfully!\n" +
                        "Projects: " + stats.get("projectCount") + "\n" +
                        "Last refresh: " + stats.get("lastRefresh") + "\n" +
                        "Data fresh: " + stats.get("dataFresh");
                    return ToolResponse.success(List.of(new TextContent(message)));
                } else {
                    String error = refreshService.getLastError();
                    return ToolResponse.error("Failed to refresh CNCF data: " + (error != null ? error : "Unknown error"));
                }
            })
            .exceptionally(throwable -> ErrorHandler.createErrorResponse("refresh_cncf_data", throwable));
    }

    /**
     * Simple search implementation.
     */
    private List<SearchResult> performSearch(List<CncfProject> projects, SearchQuery query) {
        List<SearchResult> results = new ArrayList<>();

        for (CncfProject project : projects) {
            double score = 0.0;
            String matchedField = "";

            if (query.keyword() != null && !query.keyword().isEmpty()) {
                String keyword = query.keyword().toLowerCase();

                // Name matching (highest weight)
                if (project.name().toLowerCase().contains(keyword)) {
                    score += 40;
                    matchedField = "name";
                }

                // Description matching
                if (project.description() != null &&
                    project.description().toLowerCase().contains(keyword)) {
                    score += 25;
                    if (matchedField.isEmpty()) matchedField = "description";
                }

                // Category matching
                if (project.category().toLowerCase().contains(keyword)) {
                    score += 20;
                    if (matchedField.isEmpty()) matchedField = "category";
                }

                // Tag matching
                if (project.tags() != null) {
                    long tagMatches = project.tags().stream()
                        .filter(tag -> tag.toLowerCase().contains(keyword))
                        .count();
                    score += tagMatches * 10;
                    if (matchedField.isEmpty() && tagMatches > 0) matchedField = "tags";
                }
            }

            // Category filter
            if (query.category() != null && !query.category().isEmpty() &&
                project.category().equalsIgnoreCase(query.category())) {
                score += 30;
                if (matchedField.isEmpty()) matchedField = "category";
            }

            // Popularity boost
            if (project.isPopular()) {
                score += 15;
            }

            // Graduation boost
            if (project.isGraduated()) {
                score += 10;
            }

            if (score > 0) {
                results.add(new SearchResult(project, Math.min(score, 100.0), matchedField, query));
            }
        }

        // Sort by relevance score and limit results
        results.sort((a, b) -> Double.compare(b.relevanceScore(), a.relevanceScore()));
        return results.stream()
            .limit(query.limit())
            .toList();
    }
}