# Gear Management MCP Server

Model Context Protocol (MCP) server for managing the Obscvrat gear inventory.

## Features

- **add_gear** - Add new gear with validation
- **list_gear** - List all gear with optional filters
- **search_gear** - Search by name, manufacturer, types, or description
- **update_gear** - Update existing gear fields
- **delete_gear** - Remove gear from inventory

## Configuration

Add to `.kiro/mcp.json`:

```json
{
  "mcpServers": {
    "gear": {
      "command": "uv",
      "args": ["run", ".mcp/gear-server/server.py"],
      "cwd": "${workspaceFolder}",
      "env": {
        "GEAR_DATA_DIR": "${workspaceFolder}/website/data/gear"
      }
    }
  }
}
```

## Usage

The server provides tools that can be invoked by AI agents:

### Add Gear

```python
add_gear(
    name="BD-2 Blues Driver",
    manufacturer="BOSS",
    category="Pedal",
    technology="Analog",
    types=["Overdrive", "Distortion"],
    controls=["Level", "Tone", "Gain"],
    url="https://www.boss.info/us/products/bd-2/",
    description="Classic overdrive pedal with warm, tube-like tone"
)
```

### List Gear

```python
# List all gear
list_gear()

# Filter by category
list_gear(category="Pedal")

# Filter by manufacturer
list_gear(manufacturer="BOSS")
```

### Search Gear

```python
search_gear(query="delay")
```

### Update Gear

```python
update_gear(
    slug="boss-bd-2-blues-driver",
    controls=["Level", "Tone", "Gain", "Mode"]
)
```

### Delete Gear

```python
delete_gear(slug="boss-bd-2-blues-driver")
```

## Data Validation

The server enforces:
- Required fields: name, manufacturer, category, technology
- Category enum: Pedal, Synth
- Technology enum: Analog, Digital, Hybrid
- Consistent YAML formatting
- Duplicate prevention

## Development

Install dependencies:
```bash
uv pip install -e .mcp/gear-server
```

Test the server:
```bash
uv run .mcp/gear-server/server.py
```
