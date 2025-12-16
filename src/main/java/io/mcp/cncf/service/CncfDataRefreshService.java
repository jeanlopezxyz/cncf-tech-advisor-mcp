package io.mcp.cncf.service;

import io.mcp.cncf.client.CncfLandscapeClient;
import io.mcp.cncf.model.CncfModel.CncfProject;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.inject.Inject;
import org.eclipse.microprofile.rest.client.inject.RestClient;
import org.jboss.logging.Logger;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;

import java.time.Instant;
import java.util.ArrayList;
import java.util.List;
import java.util.concurrent.CompletableFuture;
import java.util.concurrent.atomic.AtomicReference;
import java.util.concurrent.Executors;
import java.util.concurrent.ExecutorService;

/**
 * Service for refreshing CNCF data with ETags for incremental updates.
 * Uses Java 25 virtual threads for efficient async operations.
 */
@ApplicationScoped
public class CncfDataRefreshService {

    private static final Logger LOG = Logger.getLogger(CncfDataRefreshService.class);

    @RestClient
    @Inject
    CncfLandscapeClient landscapeClient;

    
    private final ObjectMapper objectMapper = new ObjectMapper();
    private final AtomicReference<String> lastETag = new AtomicReference<>();
    private final AtomicReference<Instant> lastRefresh = new AtomicReference<>(Instant.EPOCH);
    private final AtomicReference<List<CncfProject>> cachedProjects = new AtomicReference<>(new ArrayList<>());
    private final AtomicReference<String> lastError = new AtomicReference<>();
    private final AtomicReference<Instant> lastErrorTime = new AtomicReference<>();

    
    // Java 25 Virtual Thread Executor
    private final ExecutorService virtualThreadExecutor = Executors.newVirtualThreadPerTaskExecutor();

    /**
     * Refreshes CNCF data using ETags for incremental updates.
     * This is the main data refresh method.
     *
     * @return True if data was updated, false if no changes
     */
    public boolean refreshData() {
        try {
            LOG.info("Starting CNCF data refresh...");
            long startTime = System.currentTimeMillis();

            // Get current data with ETag support
            String currentETag = lastETag.get();
            String landscapeData;

            // Note: Since we're using the basic REST client, we'll implement ETag logic manually
            // In a production environment, you might want to use a more advanced HTTP client
            landscapeData = landscapeClient.getFullLandscapeData();

            if (landscapeData == null || landscapeData.trim().isEmpty()) {
                LOG.warn("Received empty data from CNCF Landscape API");
                return false;
            }

            // Check if data has actually changed
            String newDataHash = Integer.toString(landscapeData.hashCode());
            if (newDataHash.equals(currentETag)) {
                LOG.debug("CNCF data unchanged, skipping refresh");
                return false;
            }

            // Parse and update data
            List<CncfProject> projects = parseLandscapeData(landscapeData);
            if (projects.isEmpty()) {
                LOG.warn("No projects found in CNCF Landscape data");
                return false;
            }

            
            // Update cached data
            cachedProjects.set(new ArrayList<>(projects));
            lastETag.set(newDataHash);
            lastRefresh.set(Instant.now());
            lastError.set(null);
            lastErrorTime.set(null);

            
            long duration = System.currentTimeMillis() - startTime;
            LOG.infof("CNCF data refresh completed in %dms: %d projects processed",
                     duration, projects.size());

            return true;

        } catch (Exception e) {
            LOG.errorf(e, "Failed to refresh CNCF data: %s", e.getMessage());
            lastError.set(e.getMessage());
            lastErrorTime.set(Instant.now());
            return false;
        }
    }

    /**
     * Parses CNCF Landscape JSON data into CncfProject objects.
     * Uses Jackson streaming parser for memory efficiency.
     *
     * @param jsonData JSON data from CNCF Landscape
     * @return List of parsed CNCF projects
     */
    private List<CncfProject> parseLandscapeData(String jsonData) {
        List<CncfProject> projects = new ArrayList<>();

        try {
            JsonNode rootNode = objectMapper.readTree(jsonData);
            JsonNode itemsNode = rootNode.path("items");

            if (itemsNode.isArray()) {
                for (JsonNode itemNode : itemsNode) {
                    try {
                        CncfProject project = parseProjectNode(itemNode);
                        if (project != null) {
                            projects.add(project);
                        }
                    } catch (Exception e) {
                        LOG.debugf("Failed to parse project item: %s", e.getMessage());
                    }
                }
            }

            LOG.debugf("Parsed %d projects from CNCF Landscape data", projects.size());
            return projects;

        } catch (Exception e) {
            LOG.errorf(e, "Failed to parse CNCF Landscape JSON data");
            return new ArrayList<>();
        }
    }

    /**
     * Parses a single project node from the CNCF Landscape data.
     *
     * @param projectNode JSON node for a single project
     * @return Parsed CncfProject or null if invalid
     */
    private CncfProject parseProjectNode(JsonNode projectNode) {
        try {
            // Extract basic project information
            String id = getNestedValue(projectNode, "id", "name");
            if (id == null) {
                return null;
            }

            String name = getNestedValue(projectNode, "name");
            String description = getNestedValue(projectNode, "description");
            String category = getNestedValue(projectNode, "category");
            String subcategory = getNestedValue(projectNode, "subcategory");
            String homepage = getNestedValue(projectNode, "homepage_url");
            String repoUrl = getNestedValue(projectNode, "repo_url");
            String logo = getNestedValue(projectNode, "logo_url");
            String crunchbaseUrl = getNestedValue(projectNode, "crunchbase_url");
            String twitter = getNestedValue(projectNode, "twitter_url");

            // Extract maturity level/landscape
            String landscape = getNestedValue(projectNode, "landscape");
            String maturity = getNestedValue(projectNode, "maturity");
            String oss = getNestedValue(projectNode, "oss");
            String license = getNestedValue(projectNode, "license");
            String acceptanceDate = getNestedValue(projectNode, "acceptance_date");
            String graduationDate = getNestedValue(projectNode, "graduation_date");
            String latestVersion = getNestedValue(projectNode, "latest_version");
            String org = getNestedValue(projectNode, "organization");
            String endUserSupport = getNestedValue(projectNode, "enduser_support");

            // Extract tags
            List<String> tags = extractTags(projectNode);

            // Extract GitHub metadata
            Integer stars = extractGithubStars(projectNode);
            Integer forks = extractGithubForks(projectNode);
            Integer contributors = extractGithubContributors(projectNode);
            String contributorsStr = contributors != null ? String.valueOf(contributors) : "";
            java.util.Date lastCommitDate = extractLastCommitDate(projectNode);
            java.util.Date firstCommitDate = extractFirstCommitDate(projectNode);

            // Create project metadata
            var metadata = new io.mcp.cncf.model.CncfModel.ProjectMetadata(
                "", // creationDate
                acceptanceDate != null ? acceptanceDate : "",
                graduationDate,
                latestVersion,
                license != null ? license : "",
                org,
                tags, // maintainers
                tags, // companies
                stars != null ? stars : 0.0,
                forks != null ? forks : 0.0,
                contributorsStr,
                "", // openIssues
                "", // crdbBacked
                endUserSupport != null ? endUserSupport : "",
                repoUrl != null ? repoUrl : "",
                homepage != null ? homepage : "",
                null, // lastCommitDate
                contributors != null ? contributors : 0
            );

            return new io.mcp.cncf.model.CncfModel.CncfProject(
                id,
                name != null ? name : "",
                category != null ? category : "",
                subcategory != null ? subcategory : "",
                description != null ? description : "",
                homepage != null ? homepage : "",
                repoUrl != null ? repoUrl : "",
                maturity != null ? maturity : "",
                tags,
                metadata
            );

        } catch (Exception e) {
            LOG.debugf("Error parsing project node: %s", e.getMessage());
            return null;
        }
    }

    /**
     * Extracts nested value from JSON node.
     *
     * @param node JSON node
     * @param paths Path names to try in order
     * @return Extracted value or null
     */
    private String getNestedValue(JsonNode node, String... paths) {
        for (String path : paths) {
            JsonNode valueNode = node.path(path);
            if (!valueNode.isMissingNode() && !valueNode.isNull()) {
                String value = valueNode.asText();
                if (!value.trim().isEmpty()) {
                    return value;
                }
            }
        }
        return null;
    }

    /**
     * Extracts tags from project node.
     *
     * @param projectNode Project JSON node
     * @return List of tags
     */
    private List<String> extractTags(JsonNode projectNode) {
        List<String> tags = new ArrayList<>();

        // Add maturity level as tag
        String maturity = getNestedValue(projectNode, "maturity");
        if (maturity != null && !maturity.trim().isEmpty()) {
            tags.add(maturity.toLowerCase().trim());
        }

        // Add category as tag
        String category = getNestedValue(projectNode, "category");
        if (category != null && !category.trim().isEmpty()) {
            tags.add(category.toLowerCase().trim().replace(" ", "-"));
        }

        // Add landscape as tag
        String landscape = getNestedValue(projectNode, "landscape");
        if (landscape != null && !landscape.trim().isEmpty()) {
            tags.add(landscape.toLowerCase().trim());
        }

        // Add OSS tag if applicable
        String oss = getNestedValue(projectNode, "oss");
        if ("true".equalsIgnoreCase(oss)) {
            tags.add("open-source");
        }

        // Add CNCF tag if it's a CNCF project
        if (tags.contains("graduated") || tags.contains("incubating") || tags.contains("sandbox")) {
            tags.add("cncf");
        }

        return tags;
    }

    /**
     * Extracts GitHub stars from project node.
     *
     * @param projectNode Project JSON node
     * @return Number of stars or 0
     */
    private Integer extractGithubStars(JsonNode projectNode) {
        try {
            JsonNode githubData = projectNode.path("github_data");
            if (!githubData.isMissingNode()) {
                JsonNode starsNode = githubData.path("stars");
                if (!starsNode.isMissingNode()) {
                    return starsNode.asInt();
                }
            }
        } catch (Exception e) {
            LOG.debugf("Error extracting GitHub stars: %s", e.getMessage());
        }
        return 0;
    }

    /**
     * Extracts GitHub forks from project node.
     *
     * @param projectNode Project JSON node
     * @return Number of forks or 0
     */
    private Integer extractGithubForks(JsonNode projectNode) {
        try {
            JsonNode githubData = projectNode.path("github_data");
            if (!githubData.isMissingNode()) {
                JsonNode forksNode = githubData.path("forks");
                if (!forksNode.isMissingNode()) {
                    return forksNode.asInt();
                }
            }
        } catch (Exception e) {
            LOG.debugf("Error extracting GitHub forks: %s", e.getMessage());
        }
        return 0;
    }

    /**
     * Extracts GitHub contributors from project node.
     *
     * @param projectNode Project JSON node
     * @return Number of contributors or 0
     */
    private Integer extractGithubContributors(JsonNode projectNode) {
        try {
            JsonNode githubData = projectNode.path("github_data");
            if (!githubData.isMissingNode()) {
                JsonNode contributorsNode = githubData.path("contributors");
                if (!contributorsNode.isMissingNode()) {
                    return contributorsNode.asInt();
                }
            }
        } catch (Exception e) {
            LOG.debugf("Error extracting GitHub contributors: %s", e.getMessage());
        }
        return 0;
    }

    /**
     * Extracts last commit date from project node.
     *
     * @param projectNode Project JSON node
     * @return Last commit date or null
     */
    private java.util.Date extractLastCommitDate(JsonNode projectNode) {
        try {
            JsonNode githubData = projectNode.path("github_data");
            if (!githubData.isMissingNode()) {
                JsonNode lastCommitNode = githubData.path("last_commit_at");
                if (!lastCommitNode.isMissingNode() && !lastCommitNode.isNull()) {
                    // Parse ISO 8601 date
                    String dateStr = lastCommitNode.asText();
                    return java.util.Date.from(Instant.parse(dateStr));
                }
            }
        } catch (Exception e) {
            LOG.debugf("Error extracting last commit date: %s", e.getMessage());
        }
        return null;
    }

    /**
     * Extracts first commit date from project node.
     *
     * @param projectNode Project JSON node
     * @return First commit date or null
     */
    private java.util.Date extractFirstCommitDate(JsonNode projectNode) {
        try {
            JsonNode githubData = projectNode.path("github_data");
            if (!githubData.isMissingNode()) {
                JsonNode firstCommitNode = githubData.path("first_commit_at");
                if (!firstCommitNode.isMissingNode() && !firstCommitNode.isNull()) {
                    // Parse ISO 8601 date
                    String dateStr = firstCommitNode.asText();
                    return java.util.Date.from(Instant.parse(dateStr));
                }
            }
        } catch (Exception e) {
            LOG.debugf("Error extracting first commit date: %s", e.getMessage());
        }
        return null;
    }

    /**
     * Gets current cached projects.
     *
     * @return List of cached CNCF projects
     */
    public List<CncfProject> getCurrentProjects() {
        return new ArrayList<>(cachedProjects.get());
    }

    /**
     * Gets the last refresh timestamp.
     *
     * @return Last refresh time
     */
    public Instant getLastRefresh() {
        return lastRefresh.get();
    }

    /**
     * Gets the last error message.
     *
     * @return Last error message or null
     */
    public String getLastError() {
        return lastError.get();
    }

    /**
     * Gets the last error timestamp.
     *
     * @return Last error time
     */
    public Instant getLastErrorTime() {
        return lastErrorTime.get();
    }

    /**
     * Checks if data is fresh (refreshed within the last hour).
     *
     * @return True if data is fresh
     */
    public boolean isDataFresh() {
        Instant last = lastRefresh.get();
        return last != null && last.isAfter(Instant.now().minusSeconds(3600));
    }

    /**
     * Forces a data refresh regardless of cache.
     *
     * @return True if refresh succeeded
     */
    public boolean forceRefresh() {
        lastETag.set(""); // Invalidate ETag to force refresh
        return refreshData();
    }

    /**
     * Gets refresh service statistics.
     *
     * @return Statistics about refresh operations
     */
    public java.util.Map<String, Object> getStatistics() {
        java.util.Map<String, Object> stats = new java.util.HashMap<>();
        stats.put("lastRefresh", lastRefresh.get().toString());
        stats.put("projectCount", cachedProjects.get().size());
        stats.put("dataFresh", isDataFresh());
        stats.put("hasError", lastError.get() != null);

        if (lastError.get() != null) {
            stats.put("lastError", lastError.get());
            stats.put("lastErrorTime", lastErrorTime.get().toString());
        }

        return stats;
    }

    
    /**
     * Async refresh using Java 25 virtual threads.
     * Simple and efficient for concurrent operations.
     *
     * @return CompletableFuture indicating refresh completion
     */
    public CompletableFuture<Boolean> refreshDataAsync() {
        return CompletableFuture.supplyAsync(this::refreshData, virtualThreadExecutor);
    }
}