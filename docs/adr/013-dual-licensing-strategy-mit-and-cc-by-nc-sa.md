# 13. Dual Licensing Strategy - MIT and CC BY-NC-SA 4.0

**Status:** Accepted

**Date:** 2026-02-03

## Context

The Obscvrat website contains two distinct types of intellectual property:

1. **Code:** Hugo templates, CSS, JavaScript, build scripts, infrastructure configuration
2. **Content:** Music, photos, videos, text, artwork, band information

These require different licensing approaches:
- Code should be open and reusable to encourage learning and contribution
- Content should be protected from commercial exploitation while allowing sharing

Without clear licensing:
- Legal ambiguity about what others can do with the code
- No protection for creative work (music, photos, artwork)
- Unclear attribution requirements
- Potential commercial exploitation of band content

Additionally, the site uses third-party dependencies with their own licenses:
- Hugo (Apache 2.0)
- Swiper.js (MIT)
- Font Awesome (CC BY 4.0, SIL OFL 1.1, MIT)
- Fira Mono font (SIL OFL 1.1)
- Typo font (unrestricted/custom)

We need a licensing strategy that:
- Protects creative content from commercial use
- Encourages code reuse and learning
- Complies with third-party license requirements
- Is clear and easy to understand for visitors

## Decision

We will implement a **dual licensing strategy**:

### MIT License (Code)

**Applies to:**
- Hugo templates (`website/layouts/**`)
- CSS stylesheets (`website/static/*.css`, styles in templates)
- JavaScript (`website/static/*.js`)
- Build scripts (`scripts/**`)
- Infrastructure code (`infrastructure/**`, `.github/**`)
- Configuration files (`Makefile`, `Dockerfile`, `hugo.toml`)
- Documentation (`docs/**`, `README.md`, `CONTRIBUTING.md`, `AGENTS.md`)

**Permissions:**
- ✅ Commercial use
- ✅ Modification
- ✅ Distribution
- ✅ Private use
- ⚠️ Requires attribution (copyright notice)

### CC BY-NC-SA 4.0 (Content)

**Applies to:**
- Music files and recordings
- Photos and images (`website/static/media/**`)
- Videos (embedded or hosted)
- Text content (`website/content/**`)
- Artwork and graphics (`website/static/picture.gif`)
- Custom fonts (`website/static/fonts/**`)
- Band information and descriptions

**Permissions:**
- ✅ Share and adapt
- ✅ Attribution required
- ❌ No commercial use
- ⚠️ ShareAlike (derivatives must use same license)

### Implementation

**1. License Files:**
- `LICENSE-CODE.md` - Full MIT License text
- `LICENSE-CONTENT.md` - Full CC BY-NC-SA 4.0 text
- `NOTICE.md` - Third-party dependency acknowledgments

**2. Footer Display:**
```
License: MIT & CC BY-NC-SA 4.0
```
Links to `/license/` page

**3. License Page (`/license/`):**
- Explains dual licensing approach
- Lists what each license covers
- Links to full license texts
- Credits and acknowledgments section
- Third-party dependency licenses

**4. Third-Party Acknowledgments:**

In `NOTICE.md` and on `/license/` page:
- **Hugo** - Apache 2.0 (build tool)
- **Swiper.js** - MIT (carousel/slider library)
- **Font Awesome** - CC BY 4.0 (icons), SIL OFL 1.1 (fonts), MIT (code)
- **Fira Mono** - SIL OFL 1.1 (font)
- **Typo font** - Unrestricted/custom (font)

## Alternatives Considered

### Alternative 1: Single License (MIT for Everything)

**Pros:**
- Simplest approach
- No confusion about what's covered
- Maximum openness

**Cons:**
- No protection for creative content
- Allows commercial exploitation of music/photos
- Band loses control over content use
- Not appropriate for artistic work

**Why rejected:** Creative content needs protection from commercial use

### Alternative 2: Single License (CC BY-NC-SA 4.0 for Everything)

**Pros:**
- Protects all content
- Simple single license
- ShareAlike ensures derivatives stay open

**Cons:**
- Restricts code reuse (NC clause problematic for developers)
- Discourages learning from code
- Not standard for software code
- May prevent legitimate code use cases

**Why rejected:** Code should be freely reusable; NC clause too restrictive for software

### Alternative 3: All Rights Reserved (No License)

**Pros:**
- Maximum control
- No permissions granted
- Simplest legal position

**Cons:**
- Discourages code learning and contribution
- Unfriendly to open source community
- Doesn't align with experimental/collaborative ethos
- No clear permissions for sharing content

**Why rejected:** Too restrictive; doesn't encourage community engagement

### Alternative 4: GPL v3 for Code

**Pros:**
- Strong copyleft protection
- Ensures derivatives stay open
- Well-known license

**Cons:**
- More restrictive than MIT
- Requires derivatives to be GPL
- May discourage some developers
- Overkill for website code

**Why rejected:** MIT is more permissive and appropriate for website code

### Alternative 5: CC BY-NC (No ShareAlike) for Content

**Pros:**
- Simpler than ShareAlike
- Still protects from commercial use
- Allows derivatives with different licenses

**Cons:**
- Derivatives could become proprietary
- Less protection for content integrity
- ShareAlike ensures community benefits

**Why rejected:** ShareAlike better aligns with open/collaborative values

## Consequences

### Positive

- **Clear legal boundaries:** Visitors know what they can/cannot do
- **Code reusability:** Developers can learn from and reuse code freely
- **Content protection:** Music and artwork protected from commercial exploitation
- **Attribution guaranteed:** Both licenses require credit
- **Community-friendly:** Encourages sharing and learning while protecting creative work
- **Standard licenses:** MIT and CC BY-NC-SA are well-known and understood
- **Compliance:** Properly acknowledges third-party dependencies
- **Transparency:** Clear licensing builds trust with community

### Negative

- **Dual license complexity:** Visitors must understand two licenses
- **Boundary ambiguity:** Some files may be unclear (e.g., CSS with embedded images)
- **Maintenance overhead:** Must keep NOTICE.md updated with dependencies
- **ShareAlike requirement:** Derivatives of content must use same license
- **NonCommercial enforcement:** Difficult to enforce NC clause in practice
- **License page needed:** Requires dedicated page to explain licensing

### Neutral

- **No privacy policy needed:** Unless analytics/forms added later
- **Font licensing:** Typo font unrestricted, Fira Mono open (SIL OFL)
- **Third-party licenses:** All compatible with our dual license approach
- **Version 4.0:** Using latest CC version (better than 3.0)

## Notes

### License Text Locations

**LICENSE-CODE.md:**
```
MIT License

Copyright (c) 2026 Obscvrat

Permission is hereby granted, free of charge, to any person obtaining a copy...
[Full MIT text]
```

**LICENSE-CONTENT.md:**
```
Creative Commons Attribution-NonCommercial-ShareAlike 4.0 International

Copyright (c) 2026 Obscvrat

This work is licensed under CC BY-NC-SA 4.0...
[Link to full CC BY-NC-SA 4.0 text]
```

### NOTICE.md Structure

```markdown
# Third-Party Licenses and Acknowledgments

This project uses the following open source software:

## Build Tools
- **Hugo** - Apache License 2.0
  - https://gohugo.io
  - Static site generator

## JavaScript Libraries
- **Swiper.js** - MIT License
  - https://swiperjs.com
  - Carousel/slider functionality

## Fonts and Icons
- **Font Awesome** - Multiple licenses
  - Icons: CC BY 4.0
  - Fonts: SIL OFL 1.1
  - Code: MIT
  - https://fontawesome.com

- **Fira Mono** - SIL Open Font License 1.1
  - https://github.com/mozilla/Fira
  - Monospace font for navigation and headings

- **Typo** - Unrestricted/Custom
  - Custom font for body text
```

### /license/ Page Content Structure

1. **Introduction**
   - "This website uses a dual license"
   - Brief explanation of why

2. **MIT License (Code)**
   - What it covers
   - What you can do
   - Link to LICENSE-CODE.md

3. **CC BY-NC-SA 4.0 (Content)**
   - What it covers
   - What you can do
   - What you cannot do
   - Link to LICENSE-CONTENT.md

4. **Credits & Acknowledgments**
   - List of third-party tools/fonts
   - Links to their licenses
   - Brief description of each

5. **Questions**
   - Contact information for licensing questions

### Implementation Checklist

- [ ] Create LICENSE-CODE.md with full MIT text
- [ ] Create LICENSE-CONTENT.md with full CC BY-NC-SA 4.0 text
- [ ] Create NOTICE.md with third-party acknowledgments
- [ ] Create /license/ page content
- [ ] Update footer with license link
- [ ] Add copyright year to footer (2026)
- [ ] Test license page displays correctly
- [ ] Verify all links work

### Future Considerations

- Update copyright year annually
- Add privacy policy if analytics/forms added
- Consider DMCA takedown policy if content grows
- Review licensing if commercial opportunities arise
- Update NOTICE.md when dependencies change

## Related Decisions

- **ADR-007:** Homepage Design System - footer styling applies to license link
- **ADR-008:** Typo Font - custom font with no license restrictions
- **ADR-003:** Website Hosting - static site simplifies licensing (no user data)

## References

- MIT License: https://opensource.org/licenses/MIT
- CC BY-NC-SA 4.0: https://creativecommons.org/licenses/by-nc-sa/4.0/
- Hugo License: https://github.com/gohugoio/hugo/blob/master/LICENSE
- Swiper.js License: https://github.com/nolimits4web/swiper/blob/master/LICENSE
- Font Awesome License: https://fontawesome.com/license
- SIL OFL 1.1: https://scripts.sil.org/OFL
