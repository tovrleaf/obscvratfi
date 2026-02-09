# 16. CloudFront Analytics for Website Traffic Monitoring

**Status:** Accepted

**Date:** 2026-02-09

## Context

The Obscvrat website needs basic analytics to understand:
- How many visitors are accessing the site
- Where visitors are coming from (geographic location)
- Which pages are most popular
- Traffic sources (referrers)

Requirements:
- Privacy-friendly (no invasive tracking)
- Low/no cost
- Minimal performance impact
- No code changes to website
- Basic metrics sufficient (not comprehensive analytics)

The site is hosted on AWS S3 + CloudFront (see ADR-003), which provides built-in analytics capabilities.

## Decision

We will use **CloudFront Analytics** (built-in monitoring) for website traffic analysis.

### What CloudFront Analytics Provides

**Metrics Available:**
- Total requests (page views)
- Data transfer (bandwidth usage)
- Geographic distribution (countries)
- Popular pages (most requested URLs)
- Referrers (traffic sources)
- Status codes (errors, success rates)

**Access Method:**
- AWS Console → CloudFront → Distribution → Monitoring tab
- Metrics available with 15-minute delay
- Historical data retained for 60 days

**Key Features:**
- ✅ Free (included with CloudFront)
- ✅ Privacy-friendly (no cookies or user tracking)
- ✅ Zero performance impact (server-side logging)
- ✅ No code changes needed
- ✅ Shows geographic location and referrers

### Limitations

**What it doesn't provide:**
- Unique visitors (shows total requests, not unique users)
- Real-time data (15-minute delay)
- User behavior tracking (no session analysis)
- Conversion tracking
- Custom events or goals
- Detailed user demographics

**Note:** CloudFront geographic and referrer data is only available in AWS Console UI, not via AWS CLI.

## Alternatives Considered

### Alternative 1: Google Analytics

**Pros:**
- Comprehensive analytics (user behavior, demographics, conversions)
- Real-time data
- Free tier available
- Industry standard
- Detailed reports and insights

**Cons:**
- Privacy concerns (extensive user tracking)
- Requires cookie consent banners (GDPR compliance)
- JavaScript dependency (performance impact)
- Code changes required (tracking script)
- Overkill for basic traffic monitoring

**Why rejected:** Privacy concerns and complexity outweigh benefits for basic traffic monitoring needs

### Alternative 2: Plausible Analytics

**Pros:**
- Privacy-friendly (no cookies)
- Simple, clean interface
- GDPR compliant
- Lightweight JavaScript (< 1KB)
- Real-time data

**Cons:**
- $9/month cost (paid service)
- Requires JavaScript (performance impact)
- Code changes needed (tracking script)
- External dependency

**Why rejected:** Cost and external dependency not justified when CloudFront provides sufficient free analytics

### Alternative 3: Self-Hosted Analytics (Matomo/Umami)

**Pros:**
- Full control over data
- Privacy-friendly
- No external dependencies
- Comprehensive features

**Cons:**
- Requires server infrastructure (EC2 instance or similar)
- Maintenance overhead (updates, security patches)
- Database management needed
- Ongoing costs (server hosting)
- Complex setup

**Why rejected:** Too much infrastructure overhead for basic analytics needs

### Alternative 4: AWS CloudWatch Logs Insights

**Pros:**
- More detailed than CloudFront metrics
- Query logs with custom filters
- Free tier available

**Cons:**
- Requires enabling CloudFront logging (additional cost)
- Complex query language (CloudWatch Insights)
- Not user-friendly for basic metrics
- Costs can add up with high traffic

**Why rejected:** More complex than needed; CloudFront metrics sufficient

### Alternative 5: No Analytics

**Pros:**
- Zero overhead
- Maximum privacy
- No dependencies
- Simplest approach

**Cons:**
- No visibility into traffic
- Can't measure growth
- No insight into popular content
- Can't identify traffic sources

**Why rejected:** Basic analytics valuable for understanding site usage and growth

## Consequences

### Positive

- **Free:** No additional cost beyond existing CloudFront usage
- **Privacy-friendly:** No cookies, no user tracking, GDPR compliant
- **Zero performance impact:** Server-side metrics, no JavaScript
- **No code changes:** Works with existing infrastructure
- **Sufficient metrics:** Provides key insights (traffic, geography, referrers)
- **Easy access:** AWS Console provides simple dashboard
- **Already available:** No setup required, metrics already being collected

### Negative

- **Not real-time:** 15-minute delay in metrics
- **Basic metrics only:** No user behavior tracking or detailed analytics
- **Total requests, not unique visitors:** Can't distinguish unique users
- **AWS Console only:** Geographic/referrer data not available via CLI
- **60-day retention:** Historical data limited to 60 days
- **No custom events:** Can't track specific user actions

### Neutral

- **Good enough for current needs:** Basic metrics sufficient for small band website
- **Can upgrade later:** Can add Google Analytics or Plausible if needs grow
- **Complements SEO:** CloudFront metrics help understand traffic patterns
- **No migration needed:** Already using CloudFront, metrics available immediately

## Notes

### Accessing CloudFront Analytics

**Via AWS Console:**
1. Log in to AWS Console
2. Navigate to CloudFront service
3. Select your distribution
4. Click "Monitoring" tab
5. View metrics: Requests, Data Transfer, Popular Objects, etc.

**IAM Permissions Required:**

To grant read-only access to CloudFront analytics, use the IAM policy in:
`infrastructure/iam-cloudfront-analytics-readonly.json`

This policy provides:
- CloudFront distribution viewing (GetDistribution, ListDistributions)
- CloudWatch metrics access (GetMetricStatistics, ListMetrics)
- Read-only access (no modification permissions)

**Metrics Available:**
- **Requests:** Total number of requests over time
- **Bytes Downloaded:** Data transfer (bandwidth usage)
- **Error Rate:** 4xx and 5xx errors
- **Popular Objects:** Most requested URLs
- **Top Referrers:** Traffic sources
- **Viewer Location:** Geographic distribution

### Future Considerations

- Consider adding Plausible Analytics if detailed user behavior tracking becomes important
- Monitor CloudFront costs if traffic grows significantly
- Evaluate Google Analytics if conversion tracking or detailed demographics needed
- Consider AWS CloudWatch Logs Insights for advanced query capabilities

### Related Decisions

- **ADR-003:** Website Hosting & Static Site Generation - CloudFront is part of hosting architecture
- **ADR-007:** Homepage Design System - Analytics help measure design effectiveness
- **ADR-015:** Image Optimization - CloudFront metrics show bandwidth savings from optimization

## References

- CloudFront Monitoring: https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/monitoring-using-cloudwatch.html
- CloudFront Reports: https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/reports.html
- Plausible Analytics: https://plausible.io
- Google Analytics: https://analytics.google.com
