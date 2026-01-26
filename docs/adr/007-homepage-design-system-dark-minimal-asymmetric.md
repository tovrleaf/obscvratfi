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
- **Body Text (Monospace)**: Typo
  - Custom font selected for distinctive, experimental aesthetic
  - Used for body text and general content
  - Monospace aesthetic reflects technical/experimental nature
  - Highly legible on dark background
  - Font size: 0.9rem (reduced for refined visual hierarchy)
  - Fallback chain: Typo → Courier Prime → monospace

- **Display/Structural (Monospace)**: Fira Mono
  - Used for navigation, headings (h1, h2, h3), and UI elements
  - Technical, code-like appearance
  - Reinforces noisework/experimental identity
  - Creates visual hierarchy alongside Typo body text
  - Applied to specific UI elements:
    - Navigation links and logo
    - "Read more" and "View all" action links
    - Gig date boxes (featured in separate visual containers)
  - Weights: 400 (regular), 700 (bold)

This **monospace approach** uses two carefully selected monospace fonts for distinct purposes: Typo for readability and body content, Fira Mono for structure and emphasis. This creates a cohesive, intentional aesthetic reflecting experimental design principles. The font size reduction (0.9rem) refines the visual hierarchy and improves overall page balance.

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
- **Text Brightness**: 
  - Scroll-text section and glitch-text elements use primary-color (#e5e5e5) for enhanced visibility and visual impact
  - Creates brighter, more prominent hero section that immediately captures attention
  - Improves readability while maintaining dark aesthetic
- **Navigation Styling**:
  - Removed blur effect (backdrop-filter) for cleaner visual appearance
  - Transparent background (rgba(0, 0, 0, 0)) for seamless integration with content
  - Maintains structural hierarchy through Fira Mono typography
- **Hover States**: Muted accent color (`#5a5a5a`) for interactive feedback
- **Spacing**: Generous whitespace to support dark minimal aesthetic
- **Responsive Design**: Asymmetric layouts gracefully degrade on smaller screens

#### Footer Redesign
- **Social Media Integration**: 
  - Font Awesome icon-based design replaces text links for cleaner, more modern appearance
  - Icons for Instagram, Bandcamp, and YouTube
  - Social icons positioned above copyright text for visual hierarchy
- **Glowing Icon Effect**:
  - Icons feature a visible glow effect at all times (box-shadow with 0.6 opacity outer glow + 0.3 opacity inset glow)
  - Glow intensifies significantly on hover (0.9 opacity outer glow + 0.5 opacity inset glow)
  - Creates elegant, grayscale aesthetic using rgba(229, 229, 229, X) opacity variations
  - Border: 0.5px solid with 0.3 opacity for subtle definition, increases to 0.45 opacity on hover
  - Smooth 0.3s ease transitions for all interactive effects
- **Footer Background & Borders**:
  - Background: Fully transparent (no secondary background color)
  - Border: None (removed top border entirely)
  - Creates seamless integration with dark background
  - Emphasizes social icons as focal point of footer
- **Layout**: 
  - Footer content wrapped in flex container with vertical direction
  - Centered alignment for social icons
  - 1.5rem gap between icon group and copyright text
  - Icons displayed as circular buttons (40px × 40px, border-radius: 50%)
  - Copyright text: 0.9rem size, secondary-color

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
- **Strong Visual Identity**: Dark minimal palette + asymmetric layout + monospace typography (Typo + Fira Mono) creates distinctive, memorable brand presence
- **Experimental Aesthetic**: Monospace typography authentically reflects noisework/experimental nature; matches contemporary experimental design (e.g., Isabel Moranta)
- **Intentional Design**: Deliberate choice of two monospace fonts (Typo + Fira Mono) creates sophisticated, layered visual hierarchy
- **Typography Distinctiveness**: Typo font provides unique, custom feel that differentiates Obscvrat from generic monospace websites
- **Improved Visibility**: Brightened scroll-text and glitch-text (primary-color) creates immediate visual impact and better readability
- **Clean Navigation**: Removing blur effect and making background transparent creates cleaner, more intentional UI
- **Scalability**: Design system provides clear foundation for extending to other pages
- **Accessibility**: Dark background reduces eye strain; high-contrast text maintains readability; monospace fonts enhance technical accessibility
- **Logo Prominence**: Centered placement showcases the intricate organic logo as intended focal point
- **Contemporary**: Aligns with modern design trends in experimental and technical spaces
- **Layout-First Philosophy**: Prioritizes visual hierarchy, creating engaging visual experience
- **Performance**: GIF hero image creates visual engagement; CSS optimizations ensure smooth animation playback without performance degradation
- **Legibility**: Typo is highly readable for body text; Fira Mono provides clear structure and emphasis
- **Footer Redesign**: Icon-based social links with glowing effect creates modern, elegant alternative to text links
- **Interactive Feedback**: Glow effect on social icons provides clear visual feedback for user interaction
- **Refined Visual Hierarchy**: Reduced body font size (0.9rem) and strategic font application improves overall page balance and readability

### Negative
- **Scannability**: Asymmetric layout may reduce initial scannability for first-time visitors unfamiliar with experimental design
- **Complexity**: Asymmetric layouts require careful CSS implementation and testing
- **Responsive Challenges**: Unconventional layouts may be harder to adapt for mobile devices; graceful degradation requires planning
- **Browser Compatibility**: Some advanced CSS features may need fallbacks for older browsers
- **Dark Mode Limitations**: Dark theme complicates printing; may need print stylesheet
- **Accessibility Considerations**: Must ensure sufficient color contrast and focus states for keyboard navigation
- **Monospace Typography**: All-monospace approach may feel unfamiliar to some users; requires careful font selection to avoid readability issues (mitigated by Typo selection)
- **Custom Font Loading**: Typo font file requires additional HTTP request and local server configuration; requires proper @font-face implementation
- **Icon Glow Performance**: Box-shadow glow effects with inset shadows may impact performance on low-end devices or browsers; smooth transitions require GPU acceleration

### Neutral
- **Font Loading**: Google Fonts imports (Fira Mono) add slight performance overhead; Typo served locally avoids external CDN dependency
- **Iteration**: Design may evolve as homepage is used; flexibility to refine asymmetry, typography, and glow effects as user feedback arrives
- **Content Sections**: Original "upcoming live performances" focus de-emphasized in favor of layout; may require content strategy adjustment
- **Monospace Preference**: All-monospace typography is unconventional choice; represents deliberate aesthetic preference rather than universal best practice
- **Social Media Links**: Removal of "Connect" section from homepage means social links now appear only in footer; requires clear discoverability

## Notes

### Implementation Details
- **Color Variables**: CSS custom properties for all colors enable easy theme adjustments
- **Font Loading**: 
  - Typo: Custom font served locally via @font-face from `/website/static/fonts/Typo.ttf`
    - Format: TrueType (.ttf)
    - Loaded immediately without external CDN dependency
    - Fallback chain: Typo → Courier Prime → monospace
  - Fira Mono: Google Fonts with `font-display: swap` for performance
  - Body font size: 0.9rem (reduced for refined visual hierarchy)
- **Icons Library**: Font Awesome 6.4.0 via CDN for social media icons
  - Instagram, Bandcamp, YouTube icons
  - Circular button design: 40px × 40px with 50% border-radius
- **Footer Social Icons Styling**:
  - Default glow: `box-shadow: 0 0 12px 0 rgba(229, 229, 229, 0.6), inset 0 0 8px 0 rgba(229, 229, 229, 0.3)`
  - Hover glow: `box-shadow: 0 0 20px 0 rgba(229, 229, 229, 0.9), inset 0 0 12px 0 rgba(229, 229, 229, 0.5)`
  - Border: 0.5px solid rgba(229, 229, 229, 0.3) → 0.45 on hover
  - Transitions: all 0.3s ease
  - Color on hover: primary-color (#e5e5e5)
- **Social Media Links**: Configured in `website/hugo.toml`
  - Instagram: https://www.instagram.com/obscvrat/
  - Bandcamp: https://iamrat.bandcamp.com/
  - YouTube: https://www.youtube.com/@iamrat2
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
- **Site-wide application**: Design system (colors, typography, navigation, footer) should be applied consistently across all pages (live, albums, about) for cohesive user experience
- Refine accent color usage based on user interaction patterns
- Document design system specifications for team consistency
- Consider extending glow effects to other interactive elements if user feedback is positive
- Monitor social icon visibility and click-through rates

### Related Decisions
- **ADR-008**: Typo Font Typography Decision - decision to use custom Typo font as primary body font
- **ADR-003**: Website Hosting & Static Site Generation (Hugo) - this design works within existing Hugo architecture
- **ADR-004**: Instagram Feed Integration - visual integration with new design system should be considered
- **ADR-009**: Live Performance Media Management - live performance pages should use this design system
- Refine accent color usage based on user interaction patterns
- Document design system specifications for team consistency
- Consider extending glow effects to other interactive elements if user feedback is positive
- Monitor social icon visibility and click-through rates

### Related Decisions
- **ADR-008**: Typo Font Typography Decision - decision to use custom Typo font as primary body font
- **ADR-003**: Website Hosting & Static Site Generation (Hugo) - this design works within existing Hugo architecture
- **ADR-004**: Instagram Feed Integration - visual integration with new design system should be considered
>>>>>>> origin/main

### References
- **Isabel Moranta** (https://www.isabelmoranta.com) - Inspiration for dark minimal + all-monospace typography + asymmetric layout approach; demonstrates effectiveness of experimental typography on dark backgrounds
- OpenCode (https://opencode.ai) - Inspiration for dark minimal + technical design aesthetic
- Design System principles from contemporary technical brands
- Font Awesome Icon Library: https://fontawesome.com
