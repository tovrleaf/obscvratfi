#!/usr/bin/env python3
"""MCP server for managing Obscvrat gear inventory."""

import asyncio
import os
import sys
from pathlib import Path
from typing import Any, Dict, List

import yaml
from mcp.server import Server
from mcp.types import TextContent, Tool

# Get gear data directory from environment or default
GEAR_DATA_DIR = Path(os.getenv("GEAR_DATA_DIR", "website/data/gear"))

server = Server("gear-manager")


def slugify(text: str) -> str:
    """Convert text to URL-friendly slug."""
    return text.lower().replace(" ", "-").replace("/", "-")


def generate_filename(name: str, manufacturer: str) -> str:
    """Generate YAML filename from gear name and manufacturer."""
    slug = f"{slugify(manufacturer)}-{slugify(name)}"
    return f"{slug}.yaml"


def read_gear_file(filepath: Path) -> Dict[str, Any]:
    """Read and parse a gear YAML file."""
    with open(filepath) as f:
        return yaml.safe_load(f)


def write_gear_file(filepath: Path, data: Dict[str, Any]) -> None:
    """Write gear data to YAML file."""
    with open(filepath, "w") as f:
        yaml.dump(data, f, default_flow_style=False, sort_keys=False, allow_unicode=True)


@server.list_tools()
async def list_tools() -> List[Tool]:
    """List available gear management tools."""
    return [
        Tool(
            name="add_gear",
            description="Add new gear to inventory. Required: name, manufacturer, category, technology. Optional: types, controls, url, description.",
            inputSchema={
                "type": "object",
                "properties": {
                    "name": {"type": "string", "description": "Gear name (e.g., 'BD-2 Blues Driver')"},
                    "manufacturer": {"type": "string", "description": "Manufacturer name (e.g., 'BOSS')"},
                    "category": {"type": "string", "enum": ["Pedal", "Synth"], "description": "Gear category"},
                    "technology": {"type": "string", "enum": ["Analog", "Digital", "Hybrid"], "description": "Technology type"},
                    "types": {"type": "array", "items": {"type": "string"}, "description": "Gear types (e.g., ['Distortion', 'Overdrive'])"},
                    "controls": {"type": "array", "items": {"type": "string"}, "description": "Control names as labeled on device"},
                    "url": {"type": "string", "description": "Official product URL"},
                    "description": {"type": "string", "description": "Brief description (1-2 sentences)"}
                },
                "required": ["name", "manufacturer", "category", "technology"]
            }
        ),
        Tool(
            name="list_gear",
            description="List all gear in inventory with optional filters.",
            inputSchema={
                "type": "object",
                "properties": {
                    "category": {"type": "string", "description": "Filter by category (Pedal/Synth)"},
                    "manufacturer": {"type": "string", "description": "Filter by manufacturer"},
                    "technology": {"type": "string", "description": "Filter by technology (Analog/Digital/Hybrid)"}
                }
            }
        ),
        Tool(
            name="search_gear",
            description="Search gear by name, manufacturer, types, or description.",
            inputSchema={
                "type": "object",
                "properties": {
                    "query": {"type": "string", "description": "Search query"}
                },
                "required": ["query"]
            }
        ),
        Tool(
            name="update_gear",
            description="Update existing gear. Provide slug and fields to update.",
            inputSchema={
                "type": "object",
                "properties": {
                    "slug": {"type": "string", "description": "Gear filename without .yaml (e.g., 'boss-bd-2-blues-driver')"},
                    "types": {"type": "array", "items": {"type": "string"}},
                    "controls": {"type": "array", "items": {"type": "string"}},
                    "url": {"type": "string"},
                    "description": {"type": "string"}
                },
                "required": ["slug"]
            }
        ),
        Tool(
            name="delete_gear",
            description="Delete gear from inventory.",
            inputSchema={
                "type": "object",
                "properties": {
                    "slug": {"type": "string", "description": "Gear filename without .yaml"}
                },
                "required": ["slug"]
            }
        )
    ]


@server.call_tool()
async def call_tool(name: str, arguments: Dict) -> List[TextContent]:
    """Handle tool calls."""
    
    if name == "add_gear":
        # Generate filename
        filename = generate_filename(arguments["name"], arguments["manufacturer"])
        filepath = GEAR_DATA_DIR / filename
        
        # Check if already exists
        if filepath.exists():
            return [TextContent(
                type="text",
                text=f"❌ Gear already exists: {filename}\nUse update_gear to modify it."
            )]
        
        # Build gear data
        gear_data = {
            "name": arguments["name"],
            "manufacturer": arguments["manufacturer"],
            "category": arguments["category"],
            "technology": arguments["technology"]
        }
        
        # Add optional fields
        if "types" in arguments:
            gear_data["types"] = arguments["types"]
        if "url" in arguments:
            gear_data["url"] = arguments["url"]
        if "description" in arguments:
            gear_data["description"] = arguments["description"]
        if "controls" in arguments:
            gear_data["controls"] = arguments["controls"]
        
        # Write file
        write_gear_file(filepath, gear_data)
        
        missing = []
        if "controls" not in arguments:
            missing.append("controls")
        if "url" not in arguments:
            missing.append("url")
        if "description" not in arguments:
            missing.append("description")
        
        result = f"✅ Added gear: {filename}"
        if missing:
            result += f"\n⚠️  Missing optional fields: {', '.join(missing)}"
        
        return [TextContent(type="text", text=result)]
    
    elif name == "list_gear":
        # Read all gear files
        gear_files = sorted(GEAR_DATA_DIR.glob("*.yaml"))
        gear_list = []
        
        for filepath in gear_files:
            gear = read_gear_file(filepath)
            
            # Apply filters
            if "category" in arguments and gear.get("category") != arguments["category"]:
                continue
            if "manufacturer" in arguments and gear.get("manufacturer") != arguments["manufacturer"]:
                continue
            if "technology" in arguments and gear.get("technology") != arguments["technology"]:
                continue
            
            types_str = ", ".join(gear.get("types", [])) if gear.get("types") else "N/A"
            gear_list.append(
                f"• {gear['manufacturer']} {gear['name']} ({gear['category']}, {gear['technology']}) - {types_str}"
            )
        
        if not gear_list:
            return [TextContent(type="text", text="No gear found matching filters.")]
        
        result = f"Found {len(gear_list)} items:\n\n" + "\n".join(gear_list)
        return [TextContent(type="text", text=result)]
    
    elif name == "search_gear":
        query = arguments["query"].lower()
        gear_files = sorted(GEAR_DATA_DIR.glob("*.yaml"))
        matches = []
        
        for filepath in gear_files:
            gear = read_gear_file(filepath)
            
            # Search in name, manufacturer, types, description
            searchable = [
                gear.get("name", ""),
                gear.get("manufacturer", ""),
                " ".join(gear.get("types", [])),
                gear.get("description", "")
            ]
            
            if any(query in field.lower() for field in searchable):
                types_str = ", ".join(gear.get("types", [])) if gear.get("types") else "N/A"
                matches.append(
                    f"• {gear['manufacturer']} {gear['name']} ({types_str})\n  {filepath.stem}"
                )
        
        if not matches:
            return [TextContent(type="text", text=f"No gear found matching '{arguments['query']}'.")]
        
        result = f"Found {len(matches)} matches:\n\n" + "\n\n".join(matches)
        return [TextContent(type="text", text=result)]
    
    elif name == "update_gear":
        filepath = GEAR_DATA_DIR / f"{arguments['slug']}.yaml"
        
        if not filepath.exists():
            return [TextContent(
                type="text",
                text=f"❌ Gear not found: {arguments['slug']}.yaml"
            )]
        
        # Read existing data
        gear_data = read_gear_file(filepath)
        
        # Update fields
        updated_fields = []
        if "types" in arguments:
            gear_data["types"] = arguments["types"]
            updated_fields.append("types")
        if "controls" in arguments:
            gear_data["controls"] = arguments["controls"]
            updated_fields.append("controls")
        if "url" in arguments:
            gear_data["url"] = arguments["url"]
            updated_fields.append("url")
        if "description" in arguments:
            gear_data["description"] = arguments["description"]
            updated_fields.append("description")
        
        if not updated_fields:
            return [TextContent(type="text", text="⚠️  No fields to update.")]
        
        # Write updated data
        write_gear_file(filepath, gear_data)
        
        return [TextContent(
            type="text",
            text=f"✅ Updated {arguments['slug']}.yaml\nFields updated: {', '.join(updated_fields)}"
        )]
    
    elif name == "delete_gear":
        filepath = GEAR_DATA_DIR / f"{arguments['slug']}.yaml"
        
        if not filepath.exists():
            return [TextContent(
                type="text",
                text=f"❌ Gear not found: {arguments['slug']}.yaml"
            )]
        
        filepath.unlink()
        return [TextContent(type="text", text=f"✅ Deleted {arguments['slug']}.yaml")]
    
    return [TextContent(type="text", text=f"Unknown tool: {name}")]


async def main():
    """Run the MCP server."""
    from mcp.server.stdio import stdio_server
    
    async with stdio_server() as (read_stream, write_stream):
        await server.run(
            read_stream,
            write_stream,
            server.create_initialization_options()
        )


if __name__ == "__main__":
    asyncio.run(main())
