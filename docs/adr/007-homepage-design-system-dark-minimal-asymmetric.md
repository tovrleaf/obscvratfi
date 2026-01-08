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
- **Sans-Serif (Body/UI)**: Inter
  - Used for body text, navigation, and general UI elements
  - Clean, modern, highly legible
  - Weights: 400 (regular), 500 (medium), 700 (bold)

- **Monospace (Headings/Accents)**: IBM Plex Mono
  - Used strategically for section headings and visual accents
  - Conveys technical/experimental aesthetic
  - Reinforces noisework identity
  - Weights: 400 (regular), 700 (bold)

This hybrid approach balances readability with visual experimentation, drawing inspiration from technical design systems.

### 3. **Layout & Visual Hierarchy**
- **Asymmetric Design**: Content sections flow diagonally and unexpectedly rather than in traditional grids
- **Logo Placement**: Centered both vertically and horizontally on the homepage, slightly offset for visual interest
- **Logo as Visual Anchor**: The intricate, organic Obscvrat logo serves as the primary focal point
- **Band Name**: Small text positioned at top-left corner
- **Content Sections**: Arranged asymmetrically around the logo to create visual flow
- **Layout-First Philosophy**: Emphasize visual hierarchy and layout design over content prominence

### 4. **Visual Elements**
- **Logo Asset**: `website/static/logo.svg` (scalable, performant SVG format)
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
- **Cons:**
  - Monospace body text reduces readability
  - Can be fatiguing to read at length
  - Limits typographic hierarchy options
  - Less refined than hybrid approach
- **Why rejected:** Hybrid Inter + IBM Plex Mono approach provides better readability while maintaining experimental aesthetic through strategic monospace use.

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
- **Strong Visual Identity**: Dark minimal palette + asymmetric layout creates distinctive, memorable brand presence
- **Experimental Aesthetic**: Design language authentically reflects noisework/experimental nature of the music
- **Scalability**: Design system provides clear foundation for extending to other pages
- **Accessibility**: Dark background reduces eye strain; high-contrast text maintains readability
- **Logo Prominence**: Centered placement showcases the intricate organic logo as intended focal point
- **Contemporary**: Aligns with modern design trends in technical and experimental spaces
- **Layout-First Philosophy**: Prioritizes visual hierarchy, creating engaging visual experience
- **Performance**: SVG logo is lightweight and scalable

### Negative
- **Scannability**: Asymmetric layout may reduce initial scannability for first-time visitors unfamiliar with experimental design
- **Complexity**: Asymmetric layouts require careful CSS implementation and testing
- **Responsive Challenges**: Unconventional layouts may be harder to adapt for mobile devices; graceful degradation requires planning
- **Browser Compatibility**: Some advanced CSS features may need fallbacks for older browsers
- **Dark Mode Limitations**: Dark theme complicates printing; may need print stylesheet
- **Accessibility Considerations**: Must ensure sufficient color contrast and focus states for keyboard navigation

### Neutral
- **Font Loading**: External font imports (Inter, IBM Plex Mono) add slight performance overhead; mitigation includes font-display strategy and preloading
- **Iteration**: Design may evolve as homepage is used; flexibility to refine asymmetry as user feedback arrives
- **Content Sections**: Original "upcoming gigs" focus de-emphasized in favor of layout; may require content strategy adjustment

## Notes

### Implementation Details
- **Color Variables**: CSS custom properties for all colors enable easy theme adjustments
- **Font Loading**: Google Fonts or self-hosted fonts with `font-display: swap` for performance
- **Logo Path**: `website/static/logo.svg`
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
- OpenCode (https://opencode.ai) - inspiration for dark minimal + hybrid typography approach
- Design System principles from contemporary technical brands
