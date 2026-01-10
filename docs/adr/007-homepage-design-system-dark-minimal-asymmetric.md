# 7. Homepage Design System - Dark Minimal Aesthetic with Asymmetric Layout

**Status:** Accepted

**Date:** 2025-01-09

## Context

The Obscvrat website currently has a basic minimal design with limited visual identity. The homepage needs a cohesive design system that:

- Reflects the experimental and noisework nature of the Obscvrat band
- Establishes visual consistency for future page development
- Creates a memorable, distinctive user experience
- Prioritizes visual hierarchy and layout over content
- Maintains accessibility while embracing unconventional design

The current design uses a gray/blue color scheme with system fonts and traditional centered layout. We need to evolve this into a more intentional, cohesive visual system that aligns with contemporary dark minimal design trends seen in technical/experimental spaces (e.g., OpenCode, Vercel).

## Decision

We will implement a comprehensive dark minimal design system for the Obscvrat homepage featuring:

### 1. **Color Palette**
- **Primary Background**: `#1a1a1a` (deep black)
- **Secondary Background**: `#2d2d2d` (slightly lighter, for subtle contrast)
- **Text Primary**: `#e5e5e5` (light gray, high contrast for readability)
- **Text Secondary**: `#b0b0b0` (medium gray for supporting text)
- **Accent Color**: `#5a5a5a` (muted cool gray for interactive elements and visual accents)
- **Border Color**: `#3a3a3a` (subtle borders/dividers)

This palette creates a dark, minimal aesthetic that reduces eye strain, conveys sophistication, and aligns with experimental/technical design sensibilities.

### 2. **Typography System**
- **Body Text (Monospace)**: Courier Prime
  - Used for body text and general content
  - Monospace aesthetic reflects technical/experimental nature
  - Highly legible on dark background
  - Weights: 400 (regular), 700 (bold)

- **Display/Structural (Monospace)**: JetBrains Mono
  - Used for navigation, headings (h1, h2, h3)
  - Technical, code-like appearance
  - Reinforces noisework/experimental identity
  - Creates visual hierarchy alongside Courier Prime
  - Weights: 400 (regular), 500 (medium), 700 (bold)

This **all-monospace approach** differs from traditional hybrid typography. Both fonts are monospace but serve different purposes: Courier Prime for readability and body content, JetBrains Mono for structure and emphasis. This creates a cohesive, intentional aesthetic inspired by designers like Isabel Moranta who prioritize experimental typography.

### 3. **Layout & Visual Hierarchy**
- **Asymmetric Design**: Content sections flow diagonally and unexpectedly rather than in traditional grids
- **Logo Placement**: Centered both vertically and horizontally on the homepage, slightly offset for visual interest
- **Logo as Visual Anchor**: The intricate, organic Obscvrat logo serves as the primary focal point
- **Band Name**: Small text positioned at top-left corner
- **Content Sections**: Arranged asymmetrically around the logo to create visual flow
- **Layout-First Philosophy**: Emphasize visual hierarchy and layout design over content prominence

### 4. **Visual Elements**
- **Hero Image**: `website/static/picture.gif` (animated GIF with continuous loop)
  - Replaces static SVG logo for enhanced visual engagement
  - Features pulsing blur animation (12-second cycle) for subtle, hypnotic effect
  - Animated content reinforces experimental/noisework aesthetic
- **Hover States**: Muted accent color (`#5a5a5a`) for interactive feedback
- **Spacing**: Generous whitespace to support dark minimal aesthetic
- **Responsive Design**: Asymmetric layouts gracefully degrade on smaller screens

## Alternatives Considered

### Alternative 1: Vibrant/Colorful Design
Introduce multiple bright colors to reflect experimental nature.

- **Pros:**
  - Eye-catching, energetic
  - Emphasizes experimentation and noisework themes
  - Can convey creative energy
- **Cons:**
  - Risk of visual chaos if not carefully controlled
  - Difficult to maintain consistency across pages
  - May feel dated or distract from content
  - Harder to scale to full website
- **Why rejected:** Dark minimal approach better conveys intentionality and sophistication while still reflecting experimental nature through asymmetric layout.

### Alternative 2: Traditional Centered Layout
Maintain conventional grid-based design with centered content.

- **Pros:**
  - Familiar to users, predictable navigation
  - Easier to implement and maintain
  - Better conventional usability patterns
- **Cons:**
  - Generic, lacks visual distinctiveness
  - Doesn't reflect experimental nature of noisework
  - Missed opportunity for memorable design
  - Contradicts Obscvrat's unconventional aesthetic
- **Why rejected:** Asymmetric layout better differentiates the brand and creates memorable visual experience aligned with experimental music identity.

### Alternative 3: Colorful + Monospace-Only Typography
All text in monospace with vibrant color accents.

- **Pros:**
  - Maximizes technical/experimental feel
  - Visually cohesive
  - Strong identity
  - All-monospace approach creates intentional aesthetic (like Isabel Moranta)
- **Cons:**
  - Monospace body text can reduce readability at length
  - Can be fatiguing with poor font choice
  - Limits typographic hierarchy if not carefully balanced
- **Why rejected (initially):** Concerns about readability with poor font pairing
- **Why reconsidered (adopted):** Courier Prime + JetBrains Mono pairing is highly legible and creates intentional, experimental aesthetic aligned with noisework brand. Both are monospace but serve distinct purposes.

### Alternative 4: Logo in Top-Right Corner
Place logo in traditional header/navigation area.

- **Pros:**
  - Conventional brand placement
  - Easy to find and recognize
  - Familiar navigation pattern
- **Cons:**
  - Predictable, safe choice
  - Doesn't leverage logo as visual centerpiece
  - Less memorable homepage experience
  - Underutilizes visual impact of intricate logo design
- **Why rejected:** Centered logo placement creates stronger focal point and more memorable, distinctive homepage experience.

## Consequences

### Positive
- **Strong Visual Identity**: Dark minimal palette + asymmetric layout + all-monospace typography creates distinctive, memorable brand presence
- **Experimental Aesthetic**: All-monospace typography authentically reflects noisework/experimental nature; matches contemporary experimental design (e.g., Isabel Moranta)
- **Intentional Design**: Deliberate choice of two monospace fonts (Courier Prime + JetBrains Mono) creates sophisticated, layered visual hierarchy
- **Scalability**: Design system provides clear foundation for extending to other pages
- **Accessibility**: Dark background reduces eye strain; high-contrast text maintains readability; monospace fonts enhance technical accessibility
- **Logo Prominence**: Centered placement showcases the intricate organic logo as intended focal point
- **Contemporary**: Aligns with modern design trends in experimental and technical spaces
- **Layout-First Philosophy**: Prioritizes visual hierarchy, creating engaging visual experience
- **Performance**: GIF hero image creates visual engagement; CSS optimizations ensure smooth animation playback without performance degradation
- **Legibility**: Courier Prime is highly readable for body text; JetBrains Mono provides clear structure

### Negative
- **Scannability**: Asymmetric layout may reduce initial scannability for first-time visitors unfamiliar with experimental design
- **Complexity**: Asymmetric layouts require careful CSS implementation and testing
- **Responsive Challenges**: Unconventional layouts may be harder to adapt for mobile devices; graceful degradation requires planning
- **Browser Compatibility**: Some advanced CSS features may need fallbacks for older browsers
- **Dark Mode Limitations**: Dark theme complicates printing; may need print stylesheet
- **Accessibility Considerations**: Must ensure sufficient color contrast and focus states for keyboard navigation
- **Monospace Typography**: All-monospace approach may feel unfamiliar to some users; requires careful font selection to avoid readability issues (mitigated by Courier Prime choice)

### Neutral
- **Font Loading**: Google Fonts imports add slight performance overhead; mitigation includes `font-display: swap` and preconnect links
- **Iteration**: Design may evolve as homepage is used; flexibility to refine asymmetry and typography as user feedback arrives
- **Content Sections**: Original "upcoming gigs" focus de-emphasized in favor of layout; may require content strategy adjustment
- **Monospace Preference**: All-monospace typography is unconventional choice; represents deliberate aesthetic preference rather than universal best practice

## Notes

### Implementation Details
- **Color Variables**: CSS custom properties for all colors enable easy theme adjustments
- **Font Loading**: Google Fonts (Courier Prime, JetBrains Mono) with `font-display: swap` for performance
  - Courier Prime: Primary body/content font
  - JetBrains Mono: Navigation, headings, structural elements
- **Hero Image**: `website/static/picture.gif` (animated GIF)
  - Includes pulsing blur animation for continuous visual interest
  - Animation cycle: 12 seconds (ease-in-out timing)
  - CSS optimizations: `image-rendering: crisp-edges`, `backface-visibility: hidden` for smooth playback
- **Responsive Breakpoints**:
  - Desktop: 1024px+ (full asymmetric layout)
  - Tablet: 768px-1023px (adapted asymmetry)
  - Mobile: < 768px (graceful stack with preserved visual interest)

### Future Considerations
- Monitor user behavior and scroll patterns to validate asymmetric layout effectiveness
- Consider A/B testing against alternative layouts if analytics suggest issues
- Extend design system to subsequent pages (albums, gigs, about)
- Refine accent color usage based on user interaction patterns
- Document design system specifications for team consistency

### Related Decisions
- **ADR-003**: Website Hosting & Static Site Generation (Hugo) - this design works within existing Hugo architecture
- **ADR-004**: Instagram Feed Integration - visual integration with new design system should be considered

### References
- **Isabel Moranta** (https://www.isabelmoranta.com) - Inspiration for dark minimal + all-monospace typography + asymmetric layout approach; demonstrates effectiveness of experimental typography on dark backgrounds
- OpenCode (https://opencode.ai) - Inspiration for dark minimal + technical design aesthetic
- Design System principles from contemporary technical brands
