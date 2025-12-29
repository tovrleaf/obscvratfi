# 4. Instagram Feed Integration & Dynamic Content Strategy

**Status:** Accepted

**Date:** 2025-12-27

## Context

The band website is built as a static site (see ADR-003) but needs dynamic content from Instagram
to keep the homepage fresh and engaging without requiring manual rebuilds every time Instagram posts
are updated.

Current requirements:
- Display latest Instagram posts on the band website
- Posts should update automatically without manual rebuild/redeploy of the entire site
- No full backend server desired (keep infrastructure simple)
- Instagram Business account will be used for API access
- Only display images from Instagram feed (no captions, metadata, or text)
- Number of images to display will be determined during layout phase based on grid design
- Graceful degradation: if Instagram is unavailable, hide the feed rather than show errors
- Also planning Bandcamp music embeds and YouTube video links
- Need secure API key management (keys should never be exposed in frontend code)

The challenge is integrating dynamic content (Instagram) with a static site architecture while
keeping infrastructure simple, secure, and cost-effective.

## Decision

We will use a **hybrid architecture** combining static site with serverless dynamic content:

**Architecture Overview:**
1. **Frontend (Static):** Hugo-generated static HTML/CSS/JavaScript
2. **Backend (Serverless):** AWS Lambda function for Instagram data fetching
3. **API Communication:** Frontend JavaScript calls Lambda via HTTP (API Gateway)
4. **Caching:** Lambda caches Instagram results for 1 hour to minimize API calls
5. **Authentication:** Instagram Business Account with Graph API access token (secure in Lambda env vars)

**Implementation Details:**

**Lambda Function:**
- Fetches latest Instagram posts via Instagram Graph API
- Caches results for 1 hour (TTL-based)
- Returns only image URLs and basic post metadata
- Handles errors gracefully (returns empty list if Instagram unavailable)
- Runs on-demand (called by frontend JavaScript)
- Environment variables store Instagram access token securely

**Frontend Integration:**
- JavaScript function in Hugo templates
- Calls Lambda function on page load and hourly
- Displays images in responsive grid layout
- Image count determined during design phase (e.g., 3x3=9 images, 1x5=5 images)
- Shows only images (no captions or text)
- If Lambda unavailable or returns error, feed section is hidden (graceful degradation)

**Bandcamp & YouTube:**
- Bandcamp music embeds via iframe (handled in Markdown content)
- YouTube videos via iframe (handled in Markdown content)
- Music Schema markup for Bandcamp embeds (SEO benefit)

**Instagram API Setup:**
- Use official Instagram Graph API (not scraping)
- Requires Instagram Business Account (free to convert from regular account)
- Free tier: 200 API calls/hour (more than enough for hourly refresh)
- No payment required for basic API access

**AWS Services:**
- **Lambda:** Runs Instagram fetching function
- **API Gateway:** Provides HTTP endpoint for frontend to call
- **CloudWatch Logs:** Monitors Lambda execution and errors
- **IAM:** Manages permissions for Lambda execution

## Alternatives Considered

### Alternative 1: Build-Time Generation
- Fetch Instagram posts during local Hugo build
- Include images in generated static HTML
- Redeploy site whenever new Instagram posts needed
- **Pros:**
  - Simpler architecture (no Lambda needed)
  - Fewer AWS services to manage
  - No runtime latency for image fetching
  - No JavaScript required
- **Cons:**
  - Manual rebuild required to show new posts
  - Posts only update when developer deploys
  - Not truly dynamic
  - Requires discipline to update regularly
- **Why rejected:** Defeats purpose of having dynamic Instagram content; requires manual action to update

### Alternative 2: Client-Side JavaScript Only
- Frontend JavaScript directly calls Instagram Graph API
- No Lambda function needed
- **Pros:**
  - No backend infrastructure needed
  - Simple frontend implementation
  - Reduces AWS complexity
- **Cons:**
  - CORS (Cross-Origin) issues with Instagram API
  - Instagram API restrictions prevent direct browser calls
  - API key would be exposed in frontend code (security risk)
  - Rate limiting issues
  - Not practical for Instagram Graph API
- **Why rejected:** Instagram API doesn't support client-side calls; security risk of exposing API key

### Alternative 3: Full Backend Server
- Run Node.js/Python server continuously (EC2 instance or similar)
- Server manages Instagram data fetching and caching
- Frontend calls server for images
- **Pros:**
  - More control and flexibility
  - Can add more dynamic features easily
  - Better observability
- **Cons:**
  - Server maintenance overhead
  - Need to manage security patches and updates
  - Constant cost (server runs 24/7)
  - Overkill for simple Instagram fetch
  - More complexity than needed
- **Why rejected:** Too much infrastructure overhead for simple Instagram fetching; Lambda is better fit

### Alternative 4: No Dynamic Content
- Static links to Instagram profile
- No embedded Instagram feed
- **Pros:**
  - Simplest architecture
  - No backend needed
  - No Lambda complexity
  - Minimal maintenance
- **Cons:**
  - Users must leave site to see Instagram
  - Less engagement on homepage
  - Misses opportunity to keep content fresh
  - Less reason for repeat visits
- **Why rejected:** Embedded Instagram feed provides better UX and keeps homepage fresh

## Consequences

### Positive
- **Dynamic without full backend:** Get dynamic content without server maintenance overhead
- **Real-time updates:** Instagram posts appear automatically without manual rebuild
- **Secure API management:** Instagram credentials hidden in Lambda environment variables
- **Cost efficient:** Lambda free tier covers typical usage (200 posts/month)
- **Simple frontend:** Minimal JavaScript required to display images
- **Graceful degradation:** If Instagram is unavailable, feed simply hides (no broken UI)
- **Scalable:** Can easily increase image count if needed
- **No server maintenance:** Lambda is managed service, no patches or updates needed
- **Flexible:** Can easily add more social media feeds later (YouTube, TikTok, etc.)

### Negative
- **Added complexity:** Introduces Lambda and API Gateway to architecture
- **Learning curve:** Requires understanding of AWS Lambda and API Gateway
- **Slight runtime latency:** Frontend must wait for Lambda response to display images
- **Instagram API dependency:** Feature depends on Instagram API availability and terms
- **Setup complexity:** Instagram Business Account and API approval process
- **Cached data:** Posts update at most hourly (not instant real-time)
- **Additional AWS configuration:** Need to set up Lambda, API Gateway, IAM roles

### Neutral
- **1-hour caching:** Good balance between freshness and API efficiency
- **Image-only display:** Simpler than displaying full posts with captions and metadata
- **Error hiding:** Feed silently hides on error rather than showing error messages
- **Instagram Business Account:** Free to convert but requires setup and approval
- **API rate limits:** 200 calls/hour very generous for small band (1-2 posts/day)

## Notes

- Instagram Graph API requires Business Account but no payment for basic access
- Hourly caching is efficient: 1-2 band posts/day = 24-48 API calls/day vs 200/hour limit
- Lambda can easily be reused for other social media feeds if needed later (YouTube, TikTok)
- Number of Instagram images to display (e.g., 9 for 3x3 grid, 5 for single row) decided during layout design phase
- Error handling is critical: if Instagram down, feed should gracefully hide without breaking page
- Consider adding image lazy-loading for performance optimization
- Open Graph tags on homepage can feature latest Instagram image for social sharing
- Related: ADR-003 describes the static site hosting and SEO strategy that this complements

