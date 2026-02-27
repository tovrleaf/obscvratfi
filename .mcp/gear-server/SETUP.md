# MCP Gear Server Setup

## What Was Created

1. **MCP Server** (`.mcp/gear-server/`)
   - `server.py` - Main MCP server implementation
   - `pyproject.toml` - Python dependencies
   - `README.md` - Documentation
   - `test_server.py` - Test script

2. **Configuration** (`.kiro/mcp.json`)
   - Workspace-specific MCP server configuration
   - Automatically loaded by Kiro CLI

3. **Documentation Updates**
   - `AGENTS.md` - Added MCP servers section
   - `.kiro/prompts/add-gear.md` - Updated to use MCP tools

## Available Tools

### add_gear
Add new gear with validation.

**Required:** name, manufacturer, category, technology  
**Optional:** types, controls, url, description

**Example:**
```python
add_gear(
    name="BD-2 Blues Driver",
    manufacturer="BOSS",
    category="Pedal",
    technology="Analog",
    types=["Overdrive"],
    controls=["Level", "Tone", "Gain"],
    url="https://...",
    description="..."
)
```

### list_gear
List all gear with optional filters.

**Filters:** category, manufacturer, technology

**Example:**
```python
list_gear(category="Pedal")
```

### search_gear
Search by name, manufacturer, types, or description.

**Example:**
```python
search_gear(query="delay")
```

### update_gear
Update existing gear fields.

**Example:**
```python
update_gear(
    slug="boss-bd-2-blues-driver",
    controls=["Level", "Tone", "Gain", "Mode"]
)
```

### delete_gear
Remove gear from inventory.

**Example:**
```python
delete_gear(slug="boss-bd-2-blues-driver")
```

## How It Works

1. **Kiro CLI starts the server** when you begin a chat session
2. **Server runs in background**, communicates via stdio
3. **Tools are available** to all agents automatically
4. **No manual management** needed

## Benefits

- **Type-safe validation** - Enforces required fields and enums
- **Consistent formatting** - All YAML files formatted identically
- **Duplicate prevention** - Checks if gear already exists
- **Atomic operations** - All-or-nothing writes
- **Better error handling** - Structured error messages
- **Update capability** - Can modify existing gear (new feature!)

## Next Steps

The MCP server is ready to use! In your next chat session:

1. Kiro CLI will automatically start the gear server
2. You can use `@add-gear` prompt which now uses MCP tools
3. Or directly ask me to add/list/search/update gear

**Example usage:**
```
You: Add BOSS HM-2 Heavy Metal
Me: [uses add_gear tool with validated data]
    ✅ Added boss-hm-2-heavy-metal.yaml
```

## Testing

To test the server manually:
```bash
cd .mcp/gear-server
uv run server.py
```

The server will start and wait for JSON-RPC messages on stdin.

## Troubleshooting

If the server doesn't start:
1. Check `.kiro/mcp.json` configuration
2. Ensure `uv` is installed: `brew install uv`
3. Check Kiro CLI logs for errors

## Future Enhancements

Potential additions:
- **validate_gear** - Check existing gear files for issues
- **export_gear** - Export inventory to different formats
- **import_gear** - Bulk import from CSV/JSON
- **stats_gear** - Show inventory statistics
