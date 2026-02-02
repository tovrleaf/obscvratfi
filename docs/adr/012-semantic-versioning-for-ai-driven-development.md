# 12. Semantic Versioning for AI-Driven Development

**Status:** Accepted

**Date:** 2026-02-02

## Context

The Obscvrat website is built through AI-assisted development, where every change goes through a pull request workflow with specialized agents (see ADR-010). The development process is systematic, automated, and "robotic" by design - reflecting the experimental/technical nature of the band.

Current situation:
- Every change (content, features, fixes, docs) goes through PR workflow
- No version tracking or release history
- No visible indicator of site evolution
- GitHub releases not utilized

Requirements:
- Professional appearance with version numbers
- Transparent development history
- Automated versioning (no manual intervention)
- Reflect AI-driven, systematic development process
- Version visible in site footer
- GitHub Releases for each deployment

The challenge is implementing versioning that:
1. Works seamlessly with AI agent workflow
2. Requires minimal manual intervention
3. Maintains agent separation of concerns (ADR-010)
4. Provides clear development history

## Decision

We will implement **Semantic Versioning (SemVer)** with automated version management through the Commit Agent.

### Version Format

Follow Semantic Versioning 2.0.0 (https://semver.org/):
- **Major (X.0.0):** Breaking changes, complete redesigns
- **Minor (1.X.0):** New features, new pages, new sections
- **Patch (1.1.X):** Bug fixes, content updates, documentation, tooling

### Single Source of Truth: CHANGELOG.md

Version stored in `CHANGELOG.md` using Keep a Changelog format:

```markdown
# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.2.3] - 2026-02-02

### Added
- New media page with photo gallery
- CloudFront Function for directory handling

### Fixed
- Mobile layout now shows 2 columns

## [1.2.2] - 2026-02-01

### Changed
- Updated about page content
```

### Version Bump Rules

**Every merged PR bumps the version:**

**Major (X.0.0):**
- Complete site redesigns
- Breaking changes to URLs or structure
- Major architectural changes

**Minor (1.X.0):**
- New pages or sections
- New features (media gallery, contact form)
- Significant design changes

**Patch (1.1.X):**
- Bug fixes
- Content updates (new gigs, music, media)
- Documentation updates
- Infrastructure/tooling changes
- Small design tweaks

### Automated Workflow

**1. Commit Agent Responsibilities:**
- Review changes with `git diff`
- Determine version bump type based on changes
- Run `scripts/bump-version.sh [major|minor|patch]`
- Commit changes + updated CHANGELOG.md together
- Create git tag (e.g., `v1.2.3`)
- Push commits and tags: `git push && git push --tags`

**2. Version Bump Script:**
```bash
scripts/bump-version.sh [major|minor|patch]
```
- Reads current version from CHANGELOG.md
- Calculates new version
- Updates CHANGELOG.md with new entry
- Returns new version number

**3. Hugo Integration:**
- Hugo partial (`layouts/partials/version.html`) parses CHANGELOG.md
- Extracts current version at build time
- Makes available to templates
- Footer displays: "Site v1.2.3"

**4. GitHub Actions:**
- After successful deployment to AWS
- Creates GitHub Release automatically
- Uses version from CHANGELOG.md
- Extracts changelog entry for release notes
- Script: `scripts/create-github-release.sh`

### Agent Permissions Update

**Commit Agent (.kiro/agents/commit.json):**
- Add write access to: `CHANGELOG.md`
- Keep read-only for: all other files
- Can run: `scripts/bump-version.sh`, git commands

**No changes needed for:**
- Plan Agent (read-only + ADRs)
- Build Agent (writes code, not CHANGELOG.md)

### Display

**Footer:**
```html
<footer>
  <p>Site v{{ partial "version.html" }} | 
     <a href="https://github.com/tovrleaf/obscvratfi/releases">Releases</a>
  </p>
</footer>
```

**Git Tags:**
- Format: `v1.2.3` (with 'v' prefix)
- Pushed automatically by Commit Agent
- Follows GitHub convention

## Alternatives Considered

### Alternative 1: hugo.toml Storage
Store version in Hugo configuration file.

**Pros:**
- Native Hugo parameter
- Easy to access in templates
- Single configuration file

**Cons:**
- Commit Agent needs write access to hugo.toml
- Breaks agent separation of concerns
- Version mixed with other config
- Not standard practice for versioning

**Why rejected:** Violates agent architecture; CHANGELOG.md is standard practice

### Alternative 2: VERSION File
Separate file with just version number.

**Pros:**
- Simple, single line
- Easy to parse
- Clear purpose

**Cons:**
- Another file to maintain
- No changelog/history
- Not human-readable context
- Duplicates information

**Why rejected:** CHANGELOG.md provides version + history in one place

### Alternative 3: Manual Versioning
Developer manually updates version before each release.

**Pros:**
- Full control over version numbers
- Can batch multiple changes
- Flexible timing

**Cons:**
- Easy to forget
- Breaks automated workflow
- Requires manual intervention
- Doesn't fit AI-driven process

**Why rejected:** Contradicts automated, AI-driven development philosophy

### Alternative 4: No Versioning
Skip versioning entirely, use timestamps or no tracking.

**Pros:**
- No overhead
- Simpler workflow
- No version decisions needed

**Cons:**
- Less professional appearance
- No clear release history
- Harder to reference specific states
- Misses opportunity to showcase systematic process

**Why rejected:** Versioning enhances professionalism and transparency

### Alternative 5: Automated Semantic Release
Use tools like semantic-release to auto-determine version from commits.

**Pros:**
- Fully automated
- Conventional commits standard
- No manual decisions

**Cons:**
- Requires strict commit message format
- Additional tooling dependency
- Less control over version bumps
- Overkill for current needs

**Why rejected:** Too complex; manual determination by Commit Agent is sufficient

## Consequences

### Positive
- **Professional appearance:** Version numbers signal active development
- **Transparent history:** CHANGELOG.md shows all changes
- **Automated workflow:** Commit Agent handles versioning automatically
- **GitHub Releases:** Clear release history for users
- **Systematic aesthetic:** Reflects AI-driven, robotic development process
- **Single source of truth:** CHANGELOG.md contains version + history
- **Agent architecture preserved:** Commit Agent only writes CHANGELOG.md
- **Standard practices:** SemVer + Keep a Changelog are industry standards
- **Git tags:** Easy to reference specific versions
- **No manual intervention:** Fits AI-assisted workflow perfectly

### Negative
- **Version decision overhead:** Every PR requires version bump decision
- **CHANGELOG maintenance:** Must write meaningful changelog entries
- **Learning curve:** Commit Agent must understand SemVer rules
- **Potential for mistakes:** Wrong version bump type if changes misclassified
- **More commits:** CHANGELOG.md updated with every PR
- **Git tag management:** Tags must be pushed correctly

### Neutral
- **Version = deployment:** Every merge creates new version
- **Frequent releases:** Many small versions vs few large ones
- **Documentation counts:** Even doc updates bump version (patch)
- **Infrastructure changes:** Tooling updates bump version (patch)
- **Version history = development history:** Direct correlation

## Notes

### Implementation Checklist

**Phase 1: Setup**
- [ ] Create CHANGELOG.md with v1.0.0 (current state)
- [ ] Create `scripts/bump-version.sh`
- [ ] Create `scripts/create-github-release.sh`
- [ ] Update Commit Agent permissions (add CHANGELOG.md write access)

**Phase 2: Hugo Integration**
- [ ] Create `layouts/partials/version.html` to parse CHANGELOG.md
- [ ] Update footer template to display version
- [ ] Test version extraction works correctly

**Phase 3: GitHub Actions**
- [ ] Update deploy workflow to create releases
- [ ] Test release creation after deployment
- [ ] Verify changelog appears in release notes

**Phase 4: Documentation**
- [ ] Update CONTRIBUTING.md with versioning guidelines
- [ ] Update AGENTS.md with Commit Agent versioning responsibilities
- [ ] Update README.md to mention versioning

**Phase 5: Testing**
- [ ] Test version bump script (major/minor/patch)
- [ ] Test Commit Agent workflow with versioning
- [ ] Test Hugo version display
- [ ] Test GitHub Release creation

### CHANGELOG.md Format

Follow Keep a Changelog categories:
- **Added:** New features
- **Changed:** Changes to existing functionality
- **Deprecated:** Soon-to-be removed features
- **Removed:** Removed features
- **Fixed:** Bug fixes
- **Security:** Security fixes

### Version Bump Examples

**Patch (1.2.3 → 1.2.4):**
- Add new gig to live performances
- Fix mobile layout bug
- Update README.md
- Add deployment script

**Minor (1.2.0 → 1.3.0):**
- Add media page with photo gallery
- Add contact form
- Redesign about page

**Major (1.0.0 → 2.0.0):**
- Complete site redesign
- Change URL structure
- Migrate to new hosting platform

### Starting Version

**v1.0.0** - Current state of the site
- Represents the site as it exists when versioning is implemented
- All previous work considered part of v1.0.0
- Future changes bump from this baseline

### Future Considerations

- Consider adding version to HTML meta tags for debugging
- Consider version-specific analytics tracking
- Consider changelog RSS feed for subscribers
- Consider automated changelog generation from commit messages
- Consider version badges in README.md
- Consider semantic-release if workflow becomes too manual

## Related Decisions

- **ADR-010:** Specialized Agent Architecture - defines Commit Agent responsibilities
- **ADR-006:** Repository Branch Protection - PR workflow that triggers versioning
- **ADR-003:** Website Hosting & Static Site Generation - Hugo integration for version display

## References

- Semantic Versioning 2.0.0: https://semver.org/
- Keep a Changelog: https://keepachangelog.com/
- GitHub Releases: https://docs.github.com/en/repositories/releasing-projects-on-github
