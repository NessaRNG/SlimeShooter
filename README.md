<div align="center">

# <img src="slime_green.png" width="36" alt="Slime"/> Slime Shooter

**A fast-paced top-down survival shooter built with Godot 4.**

[![Play on Itch.io](https://img.shields.io/badge/Play_on-itch.io-fa5c5c?style=for-the-badge&logo=itch.io&logoColor=white)](https://watsson69.itch.io/slimeshooter)
[![Godot Engine](https://img.shields.io/badge/Godot_4.x-478cbf?style=for-the-badge&logo=godot-engine&logoColor=white)](https://godotengine.org)
[![GDScript](https://img.shields.io/badge/GDScript-478cbf?style=for-the-badge&logo=godot-engine&logoColor=white)]()
[![Platform](https://img.shields.io/badge/Platform-Desktop%20%7C%20Mobile-green?style=for-the-badge)]()
[![License](https://img.shields.io/badge/License-MIT-blue.svg?style=for-the-badge)]()

<img src="icon.png" width="150" alt="SlimeShooter Icon"/>

</div>

---

## 🎮 Play Now

You can play the game directly in your browser on itch.io:  
👉 **[Play SlimeShooter on Itch.io](https://watsson69.itch.io/slimeshooter)**

---

## 🌟 Overview

**SlimeShooter** is an intense, twin-stick style survival action game where you face endless waves of colorful slime enemies. Your goal is to survive as long as possible by shooting enemies, collecting XP, and leveling up your weapons. The game features an advanced Dynamic Difficulty Adjustment (DDA) system that scales the challenge perfectly to your skill level.

## 🎯 Key Features

- **Action-Packed Survival**: Survive endless hordes of fast-moving slime enemies!
- **Dynamic Difficulty (DDA)**: Uses fuzzy logic to monitor your health, hit rate, and time survived to adjust spawn rates and enemy speed on the fly.
- **Deep Upgrade System**: Collect dropped XP gems, level up, and pick powerful gun upgrades (e.g., faster fire rate, more damage, multi-shot).
- **Mobile Ready**: Built-in responsive virtual joystick for seamless touch screen play.
- **Varied Enemies**: 
  - 🔴 **Red Slime**: Tanky and slow.
  - 🔵 **Blue Slime**: Fast and agile.
  - 🟢 **Green Slime**: Balanced stats, swarm in large numbers.
- **Audio & Visual FX**: Integrated sound effects, damage numbers pop-ups, and smooth screen transitions.

## 🕹️ Controls

| Action | PC | Mobile |
|:---|:---:|:---:|
| **Move** | `W` `A` `S` `D` / `Arrow Keys` | Virtual Joystick (Left) |
| **Aim** | `Mouse Cursor` | Auto-aim / Virtual Joystick (Right) |
| **Shoot** | `Left Click` (or Auto-fire) | Auto-fire |
| **Pause** | `ESC` | UI Pause Button |

## ⚙️ Game Mechanics

- **XP & Leveling**: Enemies drop XP gems upon death. The required XP scales exponentially each level. When you level up, the game pauses and presents 3 random upgrade choices.
- **Fuzzy DDA**: The script `fuzzy_dda.gd` runs behind the scenes. If you are doing too well, the game ramps up the difficulty (spawning more enemies, faster speeds). If you are struggling, it provides breathing room.

## 🚀 Getting Started

### Prerequisites
- [Godot Engine 4.x](https://godotengine.org/download)

### Installation
1. Clone the repository to your local machine:
   ```bash
   git clone https://github.com/NessaRNG/SlimeShooter.git
   ```
2. Open **Godot Engine 4**.
3. Click on the **Import** button in the Project Manager.
4. Navigate to the cloned folder and select the `project.godot` file.
5. Click **Import & Edit**.
6. Press `F5` to build and run the game!

## 📂 Project Architecture

```text
SlimeShooter/
├── characters/             # Player and mob scripts/scenes
├── addons/                 # External Godot plugins
├── Audio/ & Fonts/         # Game assets
├── survivors_game.tscn     # The main gameplay scene root
├── game.gd                 # Core game loop and wave management
├── fuzzy_dda.gd            # Fuzzy logic dynamic difficulty controller
├── upgrade_menu.gd         # Level up and upgrade selection UI
├── virtual_joystick.gd     # Touch screen joystick implementation
└── clean_assets.gd         # Asset management utility
```

## 🤝 Contributing

Contributions, issues, and feature requests are welcome!
Feel free to check [issues page](#) if you want to contribute.

---

<div align="center">
Made with ❤️ by Watsson.
</div>
