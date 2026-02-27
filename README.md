<p align="center">
  <img src="logo.png" alt="Obscvrat">
</p>

<p align="center">
  Built entirely with AI. Develop. Preview. Ship.
</p>

<p align="center">
  <a href="AGENTS.md">Documentation</a> · <a href="CHANGELOG.md">Changelog</a> · <a href="docs/adr/">Architecture</a> · <a href="docs/CI-CD.md">CI/CD</a>
</p>

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
- `make test sh` - Test shell scripts
- `make test yaml` - Test YAML files
- `make test md` - Test markdown
- `make hooks setup` - Install pre-commit hooks
- `make adr new TITLE="..."` - Create ADR
- `make deploy production` - Deploy to AWS

### Documentation
- [AGENTS.md](AGENTS.md) - AI agent guidelines (PRIMARY)
- [CONTRIBUTING.md](CONTRIBUTING.md) - Git conventions
- [docs/adr/](docs/adr/) - Architecture decisions
- [docs/CI-CD.md](docs/CI-CD.md) - Pipeline details
- [docs/DEPLOYMENT.md](docs/DEPLOYMENT.md) - Deployment guide

---

**Version:** 1.5.0 | **License:** MIT & CC BY-NC-SA 4.0 | **Site:** https://obscvrat.fi
