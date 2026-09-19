# Gerex High-Resolution Robot Mascot — Asset Specifications

This folder contains the high-resolution sprite sheets for the Gerex Robot Mascot system.

## File & Slot Requirements

All sprite sheet PNG files have a **transparent background** and uniform 512x512 px frame layout.

| Slot File Name | Action State | Total Frames | Grid Layout (Cols x Rows) | Frame Dimensions | Sheet Dimensions | Default Frame Duration | Loop |
| :--- | :--- | :---: | :---: | :---: | :---: | :---: | :---: |
| `gerex_robot_idle.png` | Idle (breathing/blinking) | 1 | 1 x 1 | 1254 x 1254 px | 1254 x 1254 px | 200ms | Yes |
| `gerex_robot_smiling.png` | Wave / Smile greeting | 6 | 3 x 2 | 512 x 512 px | 1536 x 1024 px | 140ms | Yes |
| `gerex_robot_walking.png` | Walking (tab transition) | 6 | 3 x 2 | 512 x 512 px | 1536 x 1024 px | 120ms | Yes |
| `gerex_robot_running.png` | Running (fast navigation) | 6 | 3 x 2 | 512 x 512 px | 1536 x 1024 px | 80ms | Yes |
| `gerex_robot_exercise.png` | Flex / Gym celebration | 6 | 3 x 2 | 512 x 512 px | 1536 x 1024 px | 130ms | No |
| `gerex_robot_sweating.png` | Sweating recovery | 6 | 3 x 2 | 204 x 204 px | 612 x 408 px | 140ms | Yes |
| `gerex_robot_sweating_and_tired.png` | Sweating & Tired recovery | 6 | 3 x 2 | 512 x 512 px | 1536 x 1024 px | 130ms | Yes |
| `gerex_robot_tired.png` | Tired resting pose | 1 | 1 x 1 | 1024 x 1024 px | 1024 x 1024 px | 180ms | Yes |
| `gerex_robot_pushup.png` | Pushup workout animation | 6 | 3 x 2 | 204 x 204 px | 612 x 408 px | 140ms | Yes |

## Expected Animations

- **`gerex_robot_idle.png`**: Gentle cyan eye glow and breathing pose.
- **`gerex_robot_smiling.png`**: Waving arm greeting and smiling expression.
- **`gerex_robot_walking.png`**: Stepping leg cycle with arm swings.
- **`gerex_robot_running.png`**: Fast forward leaning sprint cycle.
- **`gerex_robot_exercise.png`**: Biceps workout flex celebration pose.
- **`gerex_robot_sweating.png`**: Robot wiping sweat drop after workout.
- **`gerex_robot_sweating_and_tired.png`**: Heavy panting workout recovery pose.
- **`gerex_robot_tired.png`**: Exhausted resting pose.
- **`gerex_robot_pushup.png`**: Floor pushup workout repetition cycle.

