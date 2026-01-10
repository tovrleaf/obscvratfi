# 8. Typo Font - Custom Typography for Body Text

**Status:** Accepted

**Date:** 2025-01-10

## Context

The Obscvrat homepage design system (ADR-007) initially specified Courier Prime as the primary body font. However, during implementation, a need emerged for more distinctive, custom typography that would better reflect the experimental and noisework nature of Obscvrat while maintaining the intentional monospace aesthetic.

The design goal is to create a unique visual identity that stands out from generic monospace typography found on many technical/experimental websites. While Courier Prime is legible and appropriate, it lacks distinctiveness and feels somewhat generic when used as the primary body font.

Key considerations:
- **Distinctiveness**: Body font should contribute to unique brand identity
- **Readability**: Must maintain high legibility on dark backgrounds
- **Aesthetic Alignment**: Should reinforce experimental/noisework design principles
- **Performance**: Local font serving to avoid external CDN dependencies
- **Fallbacks**: Proper fallback chain ensures graceful degradation if custom font fails to load

## Decision

We will implement **Typo** as the primary body font for the Obscvrat homepage, replacing Courier Prime as the initial choice.

### Implementation Details:
- **Primary Font**: Typo (custom font served locally)
  - Format: TrueType (.ttf)
  - Location: `/website/static/fonts/Typo.ttf`
  - Loading method: @font-face CSS rule
  - Applied to: Body text, general content, and all elements using `--font-body` CSS variable
  
- **Fallback Chain**: Typo → Courier Prime → monospace
  - Ensures legible fallback if Typo fails to load
  - Maintains monospace aesthetic across all scenarios
  
- **Body Font Size**: 0.9rem
  - Refined visual hierarchy
  - Improved page balance with reduced text size
  - Maintains readability while reducing visual weight

- **Complementary Font**: Fira Mono
  - Used for navigation, headings, UI elements, and action links
  - Creates visual hierarchy through two distinct monospace fonts
  - See ADR-007 for detailed Fira Mono application

## Alternatives Considered

### Alternative 1: Keep Courier Prime Only
Use Courier Prime as originally planned in ADR-007.

- **Pros:**
  - Familiar, widely-supported font
  - No additional font files to serve
  - Proven readability on dark backgrounds
  - Simpler implementation
  
- **Cons:**
  - Generic appearance, similar to many technical websites
  - Doesn't contribute to distinctive brand identity
  - Misses opportunity for custom, experimental aesthetic
  - Feels less intentional given Obscvrat's experimental focus
  
- **Why rejected:** While Courier Prime is solid and readable, it doesn't provide the distinctive visual identity that Obscvrat requires to stand out in the marketplace. The goal is to create memorable, unique typography that reinforces the experimental noisework aesthetic.

### Alternative 2: Use JetBrains Mono for Body Text
Apply JetBrains Mono to body text instead of Courier Prime.

- **Pros:**
  - More modern monospace aesthetic
  - High-quality, professional font
  - Works well for both display and body text
  - Maintains consistent monospace family across site
  
- **Cons:**
  - JetBrains Mono is larger/wider, requires more space
  - Less suitable for extended body text (more designed for code)
  - Would require reducing already-reduced font size further
  - Loses visual hierarchy between body and display text
  - Doesn't address distinctiveness goal as effectively
  
- **Why rejected:** While JetBrains Mono is high-quality, it's primarily designed for code and development contexts. Using it for body text would sacrifice readability and the intentional visual hierarchy created by using two complementary monospace fonts.

### Alternative 3: Use Web-Safe Fonts Only
Continue with web-safe monospace fonts (system fonts).

- **Pros:**
  - No font loading delays or failures
  - Supports all browsers and devices
  - No external dependencies
  - Smaller page weight
  
- **Cons:**
  - Limited control over font rendering
  - Cannot guarantee consistent appearance across platforms
  - Reduced distinctiveness and brand identity
  - Misses opportunity for custom design
  - Less aligned with experimental design aesthetic
  
- **Why rejected:** Web-safe fonts don't provide the control and distinctiveness needed for Obscvrat's experimental aesthetic. The custom Typo font allows for intentional, unique design that reinforces brand identity.

### Alternative 4: Custom Variable Font
Use a custom variable monospace font for both body and display text.

- **Pros:**
  - Single font file reduces HTTP requests
  - Variable weight/width provides flexibility
  - Modern font format (smaller file size than multiple font files)
  - Creates cohesive design language
  
- **Cons:**
  - Increased complexity in implementation
  - Variable fonts have limited browser support for older devices
  - Requires more careful axis selection and testing
  - Over-engineering for current design needs
  - May introduce performance overhead
  
- **Why rejected:** While variable fonts are powerful, they add unnecessary complexity for this project. The current approach with two distinct fonts (Typo for body, Fira Mono for display) achieves the design goals more simply and with better browser compatibility.

## Consequences

### Positive
- **Distinctive Brand Identity**: Typo font creates unique, memorable visual presence that stands out from generic monospace websites
- **Intentional Design**: Custom font demonstrates deliberate, experimental approach aligned with Obscvrat aesthetic
- **Local Font Serving**: Avoids reliance on external CDN; full control over font delivery and performance
- **No License Restrictions**: Custom font eliminates concerns about font licensing and usage restrictions
- **Visual Hierarchy**: Typo paired with Fira Mono creates sophisticated layered typography
- **Reduced Font Requests**: Custom local font plus one Google Font (Fira Mono) is efficient
- **Consistent Rendering**: Local font ensures predictable, consistent appearance across all browsers and platforms
- **Fallback Chain**: Proper fallback chain ensures graceful degradation if primary font fails to load

### Negative
- **Additional HTTP Request**: Typo.ttf requires additional font file download (though relatively small)
- **Local Server Configuration**: Requires proper static file serving configuration for `/website/static/fonts/`
- **Browser Compatibility**: Some older browsers may not support TrueType format, though fallbacks ensure functionality
- **Font Loading Strategy**: Must implement appropriate `@font-face` CSS and consider font-display strategy
- **Testing Burden**: Requires testing across browsers/devices to ensure Typo renders as expected
- **Maintenance**: Custom font requires version control and deployment configuration
- **Unfamiliar Typography**: Users unfamiliar with Typo font may experience initial cognitive load

### Neutral
- **Font Weight Availability**: Typo may have limited weight variations; currently using default weight
- **Internationalization**: Typo may have limited Unicode coverage; may require supplementary font for non-ASCII characters
- **Performance Perception**: Minimal impact on page load time; imperceptible to end users with proper font-display strategy
- **Design Evolution**: Decisions can be revisited if user feedback indicates issues with Typo readability or aesthetic fit

## Notes

### Implementation Checklist
- ✅ Add Typo.ttf to `/website/static/fonts/` directory
- ✅ Define @font-face CSS rule in baseof.html
- ✅ Update CSS custom property: `--font-body: 'Typo', 'Courier Prime', monospace`
- ✅ Set body font-size to 0.9rem
- ✅ Test rendering across modern browsers (Chrome, Firefox, Safari, Edge)
- ✅ Verify fallback chain works if primary font fails
- ✅ Ensure static font files are included in Git and deployed to production

### Font Specifications
- **Font Name**: Typo
- **Format**: TrueType (.ttf)
- **File Size**: ~22KB
- **Location**: `/website/static/fonts/Typo.ttf`
- **CSS Property**: `font-family: 'Typo', 'Courier Prime', monospace`
- **Font Size**: 0.9rem (body text)
- **Line Height**: 1.6 (inherited from body)
- **Font Weight**: Regular (400)
- **Supported Weights**: Default only (may be expanded if variable font approach adopted in future)

### Future Considerations
- Monitor typography feedback from users to validate Typo effectiveness
- Consider adding additional font weights (bold, italic) if design requires them
- Evaluate variable font approach if multiple weights/widths become necessary
- Test Typo rendering on various devices and screen sizes
- Consider font subsetting if Unicode coverage becomes an issue
- Monitor font loading performance and adjust strategy if needed
- Document Typo usage guidelines for future developers working on Obscvrat

### Browser Support
- Modern browsers: Full support via @font-face TrueType
- Older browsers (IE < 9): Falls back to Courier Prime (acceptable degradation)
- Mobile browsers: Full support, though file size impact is negligible
- Progressive enhancement: Site remains functional and readable even if font fails to load

### Related Decisions
- **ADR-007**: Homepage Design System - defines overall typography strategy including Typo usage
- **ADR-003**: Website Hosting & Static Site Generation (Hugo) - Typo font served via Hugo static file system

### References
- W3C @font-face specification: https://www.w3.org/TR/css-fonts-3/#font-face-rule
- Google Fonts font-display strategy: https://fonts.google.com/metadata
- Font loading best practices: https://web.dev/font-display/
