# Add Gear (AI-Assisted)

Quickly add musical gear to your inventory using AI-powered web search and auto-fill.

## Usage

```
@add-gear MANUFACTURER MODEL
```

## Examples

```
@add-gear BOSS BD-2 Blues Driver
@add-gear Electro-Harmonix Big Muff Pi
@add-gear Moog Mother-32
```

## What It Does

1. **Searches the web** for gear specifications and product images
2. **Examines product photos** to identify physical controls on the device
3. Extracts:
   - Category (Pedal/Synth)
   - Types (Distortion, Overdrive, Delay, etc.)
   - Technology (Analog/Digital/Hybrid)
   - Controls/Settings (from product images and specs)
   - Description
   - Manufacturer and product URLs
4. **Uses MCP gear server** to add gear with validation
5. Confirms with you before saving

## MCP Server

This prompt uses the `gear` MCP server which provides:
- **add_gear** - Add with validation
- **update_gear** - Update existing gear
- **list_gear** - List with filters
- **search_gear** - Search inventory

See `.mcp/gear-server/README.md` for details.

## Manual Alternative

For manual entry or to manage existing gear:
```bash
make gear
```

## Prompt

You are helping add musical gear to the Obscvrat gear inventory using the MCP gear server.

When the user provides manufacturer and model name:

1. **Search the web** for specifications and product information
2. **Find and examine product images** to identify the physical controls on the device
   - Look for official product photos showing the control panel
   - Read control labels directly from the images
   - Verify control names match what's visible on the actual hardware
3. Extract the following information:
   - **Category**: Pedal or Synth
   - **Types**: Array of types (e.g., ["Distortion", "Overdrive"])
   - **Technology**: Analog, Digital, or Hybrid
   - **Controls**: Array of control names AS LABELED ON THE DEVICE (e.g., ["Volume", "Tone", "Gain"])
   - **Description**: Brief description (1-2 sentences)
   - **URL**: Official manufacturer product page (prefer manufacturer over retailers)

4. **Use the add_gear MCP tool** to add the gear:
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

5. **IMPORTANT: Show the user what you found and ask "Is this correct? (y/n)"**
6. Only call add_gear after user confirms
7. If you cannot find clear images showing the controls, ask the user to provide them

**CRITICAL: Always examine product images to verify control names. Do not guess or infer controls from similar products.**

**If missing optional fields (controls, url, description):**
- You can still add the gear with required fields only
- Inform the user which fields are missing
- They can be added later with update_gear tool
