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
4. Creates YAML file in `website/data/gear/`
5. Confirms with you before saving

## Manual Alternative

For manual entry or to manage existing gear:
```bash
make gear
```

## Prompt

You are helping add musical gear to the Obscvrat gear inventory.

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

4. Create YAML file in `website/data/gear/` with format:
```yaml
name: "BD-2 Blues Driver"
manufacturer: "BOSS"
category: "Pedal"
types:
  - "Overdrive"
  - "Distortion"
technology: "Analog"
controls:
  - "Level"
  - "Tone"
  - "Gain"
description: "Classic overdrive pedal with warm, tube-like tone"
url: "https://www.boss.info/us/products/bd-2/"
```

5. **IMPORTANT: Show the user what you found and ask "Is this correct? (y/n)"**
6. Only save the file after user confirms
7. Save the file with slug: `manufacturer-model.yaml`

**CRITICAL: Always examine product images to verify control names. Do not guess or infer controls from similar products.**

If you cannot find clear images showing the controls, ask the user to provide them.
