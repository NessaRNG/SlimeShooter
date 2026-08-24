<div align="center">

# 🟢 SlimeShooter

**A fast-paced top-down survival shooter built with Godot 4.**

[![Godot Engine](https://img.shields.io/badge/Godot_4.x-478cbf?style=for-the-badge&logo=godot-engine&logoColor=white)](https://godotengine.org)
[![GDScript](https://img.shields.io/badge/GDScript-478cbf?style=for-the-badge&logo=godot-engine&logoColor=white)]()
[![Platform](https://img.shields.io/badge/Platform-Desktop%20%7C%20Mobile-green?style=for-the-badge)]()

<img src="icon.png" width="150" alt="SlimeShooter Icon"/>

</div>

## 🌟 Features

- **Action-Packed Survival**: Survive endless hordes of slime enemies!
- **Dynamic Difficulty (DDA)**: Game auto-adjusts difficulty based on your skill.
- **Upgrade System**: Collect XP gems, level up, and pick powerful gun upgrades.
- **Mobile Ready**: Built-in virtual joystick for touch screen play.
- **Varied Enemies**: Face unique slime variants (Red, Blue, Green).

## 🕹️ Controls

| Action | PC | Mobile |
|:---|:---:|:---:|
| **Move** | `W` `A` `S` `D` / `Arrow Keys` | Virtual Joystick |
| **Aim** | `Mouse` | Auto-aim |
| **Pause** | `ESC` | Pause Button |

## 🚀 Getting Started

1. Download [Godot Engine 4.x](https://godotengine.org/download)
2. Clone repo:
   ```bash
   git clone https://github.com/yourusername/SlimeShooter.git
   ```
3. Open Godot, click **Import**, select `project.godot`.
4. Press `F5` to play.

## 📂 Architecture

- `survivors_game.tscn`: Main game scene.
- `fuzzy_dda.gd`: Fuzzy logic dynamic difficulty controller.
- `upgrade_menu.gd` / `xp_gem.gd`: Level up and progression.
- `virtual_joystick.gd`: Touch controls.

<div align="center">
Made with ❤️ by Nessa.
</div>
