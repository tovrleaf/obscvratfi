# Obscvrat Website

**Built entirely with AI.** This project is developed through AI agents following instructions in AGENTS.md. Humans provide direction, AI implements everything.

Official noisework website for Obscvrat - static site built with Hugo, deployed to AWS CloudFront.

## For AI Agents

See [AGENTS.md](AGENTS.md) for comprehensive guidelines, workflows, and prompts.

## For Humans

### Prerequisites
- Hugo Extended v0.128.2+
- Python 3.9+
- Make

### Quick Start
```bash
# Clone and setup
git clone https://github.com/tovrleaf/obscvratfi.git
cd obscvratfi
make hooks setup

# Start development
make serve  # http://localhost:1313

# Test changes
make test

# Deploy
make deploy production
```

### Common Commands
- `make serve` - Start dev server
- `make test` - Run all tests
- `make hooks setup` - Install pre-commit hooks
- `make adr-new TITLE="..."` - Create ADR
- `make deploy production` - Deploy to AWS

### Documentation
- [AGENTS.md](AGENTS.md) - AI agent guidelines (PRIMARY)
- [CONTRIBUTING.md](CONTRIBUTING.md) - Git conventions
- [docs/adr/](docs/adr/) - Architecture decisions
- [docs/CI-CD.md](docs/CI-CD.md) - Pipeline details
- [docs/DEPLOYMENT.md](docs/DEPLOYMENT.md) - Deployment guide

---

**Version:** 1.2.0 | **License:** MIT & CC BY-NC-SA 4.0 | **Site:** https://obscvrat.fi
