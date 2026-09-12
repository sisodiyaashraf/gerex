# Gerex 8-Bit Pixel Robot Mascot — Asset Slot Specifications

This folder contains the sprite sheets for the 8-Bit Gerex Robot Mascot. The animation system is **asset-agnostic** — real artwork can be swapped in by replacing these files without changing any code.

## File & Slot Requirements

All sprite sheet PNG files must have a **transparent background** and uniform frame layout.

| Slot File Name | Action State | Total Frames | Grid Layout (Cols x Rows) | Frame Dimensions (Width x Height) | Sheet Dimensions (Width x Height) | Default Frame Duration | Loop |
| :--- | :--- | :---: | :---: | :---: | :---: | :---: | :---: |
| `robot_idle.png` | Idle (breathing/blinking) | 4 | 4 x 1 | 32 x 32 px | 128 x 32 px | 180ms | Yes |
| `robot_walk.png` | Walk (tab transitions) | 4 | 4 x 1 | 32 x 32 px | 128 x 32 px | 140ms | No |
| `robot_run.png` | Run (fast transition) | 4 | 4 x 1 | 32 x 32 px | 128 x 32 px | 100ms | No |
| `robot_wave.png` | Wave ("Hi" greeting) | 4 | 4 x 1 | 32 x 32 px | 128 x 32 px | 160ms | No |
| `robot_flex.png` | Flex (gym celebration) | 4 | 4 x 1 | 32 x 32 px | 128 x 32 px | 180ms | No |

*Note: If you use higher-resolution pixel art (e.g. 64x64 or 128x128 per frame), update the `frameWidth` and `frameHeight` parameters in `mascot_controller.dart` to match your sheet.*

## Expected Animations

- **`robot_idle.png`**: Gentle pixel eye blinking and chest light breathing pulse.
- **`robot_walk.png`**: Side-stepping or marching robot leg cycle.
- **`robot_run.png`**: Fast forward leaning dash cycle with speed trail lines.
- **`robot_wave.png`**: Hand raised up and waving 8-bit palm back and forth.
- **`robot_flex.png`**: Double biceps pose / celebration pose with 8-bit sparkle effect.
