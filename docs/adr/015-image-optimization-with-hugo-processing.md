# 15. Image Optimization with Hugo Processing

**Status:** Accepted

**Date:** 2026-02-05

## Context

The Obscvrat website currently serves full-resolution images directly from the `static/` directory, resulting in large file sizes and high bandwidth consumption. For example, the homepage hero image `obscvrat-harsh-noise-experimental.jpg` is served at full resolution even though it's displayed at a smaller size.

Current issues:
- Large image files consume significant CloudFront bandwidth
- Slow page load times, especially on mobile
- Poor Core Web Vitals scores (LCP - Largest Contentful Paint)
- Unnecessary data transfer for users on slow connections
- Higher CloudFront costs
- Negative impact on SEO rankings (page speed is a ranking factor)

Hugo has built-in image processing capabilities that can automatically generate optimized thumbnails and responsive image sets at build time. Images in the `assets/` directory can be processed with `.Resize`, `.Fit`, and `.Fill` methods to create multiple sizes and formats.

Some pages already use Hugo image processing (media gallery, live performance posters), but it's not applied consistently across the site. The homepage and other pages still serve full-resolution images from `static/`.

Requirements:
- Reduce bandwidth consumption
- Improve page load times
- Maintain image quality
- Support responsive images (different sizes for different screens)
- Preserve SEO benefits
- Apply optimization site-wide

## Decision

We will implement **comprehensive image optimization using Hugo's built-in image processing** for all images across the site.

### Implementation Strategy

**1. Image Organization**
- Move all images from `static/` to `assets/` directory
- Organize by content type: `assets/images/`, `assets/media/live/`, etc.
- Keep original high-resolution images in `assets/`
- Hugo generates optimized versions at build time

**2. Standard Image Sizes**
Define three responsive breakpoints:
- **Small:** 400px width (mobile)
- **Medium:** 800px width (tablet/small desktop)
- **Large:** 1200px width (desktop)

**3. Image Quality**
- JPEG quality: 85% (good balance of quality vs file size)
- WebP format where supported (better compression)
- Fallback to JPEG for older browsers

**4. Responsive Images**
Use `srcset` attribute for responsive delivery:
```html
<img srcset="image-400w.jpg 400w,
             image-800w.jpg 800w,
             image-1200w.jpg 1200w"
     sizes="(max-width: 768px) 100vw, 800px"
     src="image-800w.jpg"
     alt="Descriptive text"
     loading="lazy">
```

**5. Hugo Template Pattern**
```go-html-template
{{ $image := resources.Get "images/hero.jpg" }}
{{ $small := $image.Resize "400x q85" }}
{{ $medium := $image.Resize "800x q85" }}
{{ $large := $image.Resize "1200x q85" }}

<img srcset="{{ $small.RelPermalink }} 400w,
             {{ $medium.RelPermalink }} 800w,
             {{ $large.RelPermalink }} 1200w"
     src="{{ $medium.RelPermalink }}"
     alt="{{ .Title }}">
```

**6. WebP Support**
```go-html-template
{{ $imageJPG := $image.Resize "800x q85" }}
{{ $imageWebP := $image.Resize "800x q85 webp" }}

<picture>
  <source srcset="{{ $imageWebP.RelPermalink }}" type="image/webp">
  <img src="{{ $imageJPG.RelPermalink }}" alt="{{ .Title }}">
</picture>
```

**7. Lazy Loading**
Add `loading="lazy"` to all images below the fold to defer loading until needed.

### Scope

**Apply to all pages:**
- Homepage (hero image, featured content)
- Live performance pages (posters, photos)
- Music pages (album covers)
- Media gallery (photos, video thumbnails)
- About page (any images)

**Already implemented:**
- Media gallery photos (using Hugo processing)
- Live performance posters (using Hugo processing)

**Needs implementation:**
- Homepage hero image
- Music album covers (if not already optimized)
- Any other static images in `static/`

### SEO Considerations

**Positive impacts:**
- Faster page load times (major ranking factor)
- Better Core Web Vitals (LCP, CLS, FID)
- Improved mobile experience (mobile-first indexing)
- Lower bounce rate (users stay on fast sites)

**Maintain SEO best practices:**
- Keep descriptive alt text on all images
- Use original URLs in structured data (schema markup)
- Provide multiple sizes via srcset (Google supports this)
- Maintain image quality (85% JPEG quality is sufficient)

**No negative SEO impact** as long as:
- Alt text is descriptive and relevant
- Image quality remains high (85%+)
- Original images available for schema markup
- Responsive images properly implemented

## Alternatives Considered

### Alternative 1: External Image CDN (Cloudinary/imgix)

**Pros:**
- Automatic optimization and resizing
- Dynamic image transformations
- Advanced features (face detection, smart cropping)
- CDN delivery included

**Cons:**
- External dependency
- Monthly cost ($25-100+)
- Requires API integration
- Less control over processing
- Another service to manage

**Why rejected:** Hugo's built-in processing is free, works with existing S3/CloudFront setup, and provides sufficient control.

### Alternative 2: Manual Image Optimization

**Pros:**
- Full control over each image
- Can use specialized tools (Photoshop, ImageOptim)
- No build-time processing overhead

**Cons:**
- Time-consuming and error-prone
- Inconsistent optimization
- Hard to maintain responsive sizes
- Doesn't scale as content grows
- Easy to forget for new images

**Why rejected:** Automation is essential for consistency and maintainability.

### Alternative 3: Client-Side Lazy Loading Library

**Pros:**
- Can optimize images on-the-fly
- Advanced lazy loading features
- Blur-up placeholders

**Cons:**
- JavaScript dependency
- Doesn't reduce file sizes
- Still serves full-resolution images
- Performance overhead
- Doesn't solve bandwidth issue

**Why rejected:** Doesn't address root problem of large file sizes; Hugo processing is better solution.

### Alternative 4: Keep Images in static/ (No Optimization)

**Pros:**
- No changes needed
- Simplest approach
- No build-time overhead

**Cons:**
- High bandwidth costs
- Slow page loads
- Poor SEO
- Bad mobile experience
- Wasted CloudFront bandwidth

**Why rejected:** Current approach is unsustainable; optimization is necessary.

## Consequences

### Positive

- **Bandwidth savings:** 70-90% reduction in image file sizes
- **Faster page loads:** Significantly improved LCP and overall page speed
- **Better SEO:** Page speed is a ranking factor; faster = better rankings
- **Improved mobile UX:** Smaller images load faster on mobile networks
- **Lower costs:** Reduced CloudFront bandwidth usage
- **Responsive delivery:** Right-sized images for each device
- **Automatic:** Hugo handles optimization at build time
- **Consistent:** All images processed the same way
- **WebP support:** Modern browsers get better compression
- **Lazy loading:** Images below fold load on-demand
- **Cached builds:** Hugo caches processed images between builds

### Negative

- **Build time increase:** First build processes all images (slower)
- **Migration effort:** Need to move images from static/ to assets/
- **Template updates:** Need to update all image references
- **Storage increase:** Multiple versions of each image in public/
- **Complexity:** More complex than serving static files
- **Learning curve:** Team needs to understand Hugo image processing

### Neutral

- **Build caching:** Subsequent builds are fast (only changed images processed)
- **Deployment size:** Larger public/ directory (multiple image versions)
- **Original images:** Still available in assets/ for future use
- **Backward compatibility:** Can keep static/ images during migration

## Notes

### Implementation Checklist

**Phase 1: Setup**
- [ ] Create `assets/images/` directory structure
- [ ] Move homepage images from static/ to assets/
- [ ] Update homepage template to use Hugo processing
- [ ] Test build and verify optimized images generated

**Phase 2: Site-Wide Migration**
- [ ] Audit all pages for static images
- [ ] Move remaining images to assets/
- [ ] Update all templates to use resources.Get
- [ ] Implement responsive srcset on all images
- [ ] Add lazy loading to below-fold images

**Phase 3: WebP Support**
- [ ] Add WebP generation to all images
- [ ] Implement picture element with fallbacks
- [ ] Test in multiple browsers

**Phase 4: Validation**
- [ ] Run Google PageSpeed Insights (before/after)
- [ ] Check Core Web Vitals improvement
- [ ] Verify CloudFront bandwidth reduction
- [ ] Test on mobile devices
- [ ] Validate SEO impact (no broken images)

**Phase 5: Documentation**
- [ ] Update AGENTS.md with image optimization guidelines
- [ ] Document standard sizes and quality settings
- [ ] Add examples to template documentation

### Hugo Image Processing Reference

**Resize methods:**
- `Resize "800x"` - Width 800px, auto height
- `Resize "x600"` - Height 600px, auto width
- `Resize "800x600"` - Exact dimensions (may distort)
- `Fit "800x600"` - Fit within bounds (maintains aspect ratio)
- `Fill "800x600"` - Fill bounds (crops if needed)

**Quality settings:**
- `q85` - 85% quality (recommended for photos)
- `q90` - 90% quality (higher quality, larger files)
- `q75` - 75% quality (smaller files, visible compression)

**Format conversion:**
- `webp` - Convert to WebP format
- `png` - Convert to PNG format
- `jpg` - Convert to JPEG format

**Example:**
```go-html-template
{{ $image := resources.Get "images/photo.jpg" }}
{{ $thumb := $image.Resize "800x q85 webp" }}
```

### Performance Benchmarks

**Expected improvements:**
- Homepage load time: 3s → 1s (67% faster)
- Image file sizes: 2MB → 200KB (90% smaller)
- CloudFront bandwidth: 70-90% reduction
- PageSpeed score: 60 → 90+ (significant improvement)
- LCP: 4s → 1.5s (below 2.5s threshold)

### SEO Monitoring

**Track after implementation:**
- Google PageSpeed Insights score
- Core Web Vitals (LCP, FID, CLS)
- Mobile usability score
- Bounce rate changes
- Average session duration
- Organic search rankings

### Future Enhancements

- Consider blur-up placeholders for progressive loading
- Implement art direction (different crops for mobile/desktop)
- Add AVIF format support (better than WebP, when widely supported)
- Explore image CDN if traffic grows significantly
- Add automated image optimization checks in CI/CD

## Related Decisions

- **ADR-003:** Website Hosting & Static Site Generation - Hugo's image processing fits static site architecture
- **ADR-007:** Homepage Design System - Optimized images maintain visual quality while improving performance
- **ADR-009:** Live Performance Media Management - Already using Hugo processing for media gallery

## References

- Hugo Image Processing: https://gohugo.io/content-management/image-processing/
- Google PageSpeed Insights: https://pagespeed.web.dev/
- Core Web Vitals: https://web.dev/vitals/
- WebP Format: https://developers.google.com/speed/webp
- Responsive Images: https://developer.mozilla.org/en-US/docs/Learn/HTML/Multimedia_and_embedding/Responsive_images
