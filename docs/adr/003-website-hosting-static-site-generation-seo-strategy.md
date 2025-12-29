# 3. Website Hosting, Static Site Generation & SEO Strategy

**Status:** Accepted

**Date:** 2025-12-27

## Context

Building a band website for obscvratfi with the following requirements:
- Showcase gigs, music (Bandcamp), videos (YouTube), and basic band info
- Content managed locally via Markdown files
- Manual updates and deployments to AWS infrastructure
- Custom domain: obscvrat.fi
- SEO is critical for discoverability - fans should find the band through search engines
- No database or server-side user interactions needed (except dynamic Instagram feed)
- Content should be fast-loading and mobile-responsive
- Integrate with external platforms: YouTube, Instagram, Bandcamp

The primary challenge is choosing a hosting and site generation approach that balances:
- Performance (critical for SEO)
- Ease of content management (Markdown-based)
- Cost efficiency
- SEO optimization capabilities
- Integration with third-party platforms

## Decision

We will use the following architecture:

**Static Site Generator:** Hugo
- Fast compilation and excellent performance
- Built-in SEO features (sitemaps, canonical URLs)
- Strong schema markup support for structured data
- Flexible templating for custom layouts
- Large community and ecosystem

**Hosting & CDN:** AWS S3 + CloudFront
- S3 for static file storage
- CloudFront for global CDN distribution
- Custom domain via Route 53
- HTTPS/SSL included
- Excellent performance for SEO

**Content Management:** Markdown-based pipeline
- Content stored in Markdown files
- Hugo compiles Markdown → HTML locally
- Version controlled in Git
- Easy to update and maintain

**SEO Strategy:**
- Event Schema markup for gigs (location, date, performer info)
- Music Schema markup for Bandcamp embeds (album, artist, track info)
- Open Graph tags for social media sharing
- Dynamic sitemap and robots.txt generation
- Mobile-responsive design (critical for Google rankings)
- Links to YouTube, Instagram, Bandcamp in footer/sidebar for authority
- Proper meta descriptions and title tags

**Deployment Process:**
- Local Hugo build: `hugo` command
- Manual upload to S3 bucket
- CloudFront cache invalidation
- No automatic CI/CD pipeline initially (manual control preferred)

## Alternatives Considered

### Alternative 1: 11ty (Eleventy)
- **Pros:**
  - Very flexible and extensible
  - JavaScript-based (easier for some developers)
  - Good performance
  - Excellent schema markup support
- **Cons:**
  - Slightly slower build times than Hugo
  - Smaller ecosystem than Hugo
  - Requires more configuration for beginners
- **Why rejected:** Hugo's superior performance and lower learning curve better suited for band website with SEO focus

### Alternative 2: Jekyll
- **Pros:**
  - Simple and straightforward
  - Good GitHub Pages integration
  - Lower barrier to entry
- **Cons:**
  - Slower compilation than Hugo
  - Less performant output
  - Smaller ecosystem
  - Not as good for complex schema markup
- **Why rejected:** Performance is critical for SEO; Hugo significantly outperforms Jekyll

### Alternative 3: GitHub Pages (with Jekyll)
- **Pros:**
  - Completely free
  - Automatic builds and deploys
  - No infrastructure management
- **Cons:**
  - Limited customization
  - No custom CDN (slower global delivery)
  - Less control over performance optimization
  - Limited schema markup capabilities
- **Why rejected:** CDN performance is crucial for SEO; custom domain setup is more complex

### Alternative 4: Netlify
- **Pros:**
  - Free tier available
  - Automatic builds and deploys
  - Good CDN performance
  - Easy integration with Git
- **Cons:**
  - Less control over infrastructure
  - Custom domain setup can be complex
  - Not as performant as CloudFront
  - Smaller ecosystem than Hugo alone
- **Why rejected:** S3 + CloudFront provides better performance and more direct control

## Consequences

### Positive
- **Best-in-class performance:** Hugo's speed is industry-leading, critical for Google rankings
- **Superior SEO:** Fast loading, schema markup, structured data all improve search visibility
- **Cost efficient:** S3 is very cheap for static content; CloudFront pricing is reasonable
- **Full control:** Complete control over infrastructure, configuration, and optimization
- **Version control:** Markdown files tracked in Git, easy to see history and rollback
- **Scalability:** Static sites can handle traffic spikes without issue
- **Global distribution:** CloudFront ensures fast loading worldwide
- **No maintenance burden:** No database to manage, no server patches needed
- **Security:** Static files inherently more secure than dynamic applications

### Negative
- **Learning curve:** Hugo requires understanding of its template system and configuration
- **Manual deployment:** No automatic builds (must run locally and upload manually)
- **AWS complexity:** S3, CloudFront, Route 53 require setup and understanding of AWS
- **Schema markup effort:** Implementing Event and Music schema requires additional setup
- **No automatic deploys:** Every content update requires manual build and upload

### Neutral
- **Static generation time:** Hugo builds are fast but still require developer action
- **Content update workflow:** Must rebuild and redeploy to update live site
- **CDN cache invalidation:** May need to invalidate CloudFront cache to see updates immediately
- **AWS account required:** Need AWS account and basic AWS knowledge

## Notes

- The S3 + CloudFront combination provides better SEO performance than GitHub Pages or Netlify
- Hugo's Event Schema support is excellent for promoting gigs in search results
- Music Schema markup for Bandcamp embeds will help with music discoverability
- Open Graph tags enable better sharing on Instagram, YouTube, and other social platforms
- This architecture scales easily - band can grow without changing infrastructure
- Future optimization opportunities: image optimization, lazy loading, PWA features
- Related: ADR-004 addresses dynamic Instagram feed integration on this static site

