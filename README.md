# Aetheria Omni-Verse

A Roblox MMORPG experience featuring a unique spirit-based combat system, multiple elemental realms, and cross-realm exploration.

## 🌟 Project Overview

Aetheria Omni-Verse is an ambitious multiplayer role-playing game built on the Roblox platform. Players explore interconnected realms, each governed by one of seven elemental forces (Fire, Water, Earth, Air, Light, Dark, and Lightning). The game features a innovative spirit-based combat system where players collect, upgrade, and strategically deploy spirits in battle.

**Key Features:**
- 7 distinct elemental realms with unique environments and challenges
- Spirit collection and upgrade system with 5 rarity tiers
- Dynamic combat system with elemental strengths and weaknesses
- Cross-realm portals and exploration mechanics
- Persistent player progression and data management
- Client-server architecture with live sync development workflow

## 📋 Prerequisites

Before you begin, ensure you have the following installed:

1. **Roblox Studio** - [Download here](https://www.roblox.com/create)
   - Create a free Roblox account if you don't have one
   - Install and log into Roblox Studio

2. **Rojo Plugin** - Install from Roblox Studio:
   - Open Roblox Studio
   - Go to the "Plugins" tab
   - Click "Manage Plugins"
   - Search for "Rojo" and install the official Rojo plugin
   - Or install from: https://roblox.github.io/rojo/

3. **Rojo CLI** - Version 7.6.1 or higher
   - **Using Aftman (Recommended):**
     ```bash
     # Install Aftman
     cargo install aftman
     
     # Install Rojo via Aftman
     aftman add rojo-rbx/rojo@7.6.1
     aftman install
     ```
   
   - **Using Foreman:**
     ```bash
     # Install Foreman
     cargo install foreman
     
     # Install Rojo via foreman.toml
     foreman install
     ```
   
   - **Direct Download:**
     - Download from [Rojo Releases](https://github.com/rojo-rbx/rojo/releases)
     - Extract to a directory in your PATH
     - Verify installation: `rojo --version`

4. **Git** - [Download here](https://git-scm.com/downloads)
   - Required for cloning the repository and version control

## 🚀 Installation

### 1. Clone the Repository

```bash
git clone https://github.com/pdarleyjr/aetheria-omni-verse.git
cd aetheria-omni-verse
```

### 2. Verify Project Structure

Ensure the following directories and files exist:

```
aetheria-omni-verse/
├── src/
│   ├── Server/          # Server-side scripts and services
│   │   ├── Main.server.lua
│   │   └── Services/
│   │       ├── DataService.lua
│   │       ├── PlayerService.lua
│   │       ├── RealmService.lua
│   │       └── SpiritService.lua
│   ├── Client/          # Client-side scripts and controllers
│   │   ├── Main.client.lua
│   │   └── Controllers/
│   │       ├── UIController.lua
│   │       └── CombatController.lua
│   └── Shared/          # Shared modules (Server & Client)
│       └── Modules/
│           ├── Constants.lua
│           ├── Signal.lua
│           └── Maid.lua
├── plans/
│   └── technical-architecture.md
├── default.project.json  # Rojo configuration
├── .gitignore
└── README.md
```

### 3. Install Node Dependencies (Optional)

If you plan to use the Roblox Experience creation scripts:

```bash
npm install
```

## 🔧 Development Workflow

### Starting the Rojo Server

1. **Open a terminal** in the project directory

2. **Start the Rojo live sync server:**
   ```bash
   rojo serve
   ```

3. **Expected output:**
   ```
   Rojo server listening on port 34872
   Visit http://localhost:34872/ in your browser for more information.
   ```

4. **Keep this terminal running** - The Rojo server must remain active for live sync to work

### Connecting Roblox Studio

1. **Open Roblox Studio**

2. **Create a new place or open an existing one:**
   - File → New → Baseplate (or any template)
   - Or open your existing Aetheria Omni-Verse place

3. **Connect to Rojo:**
   - Click the **Rojo plugin** button in the toolbar
   - In the Rojo panel, you should see: `localhost:34872`
   - Click the **"Connect"** button
   - Status should change to **"Connected"**

4. **Sync the project:**
   - Click **"Sync In"** to sync the initial project structure
   - Confirm the sync when prompted
   - Your Explorer should now show the synced structure

### Live Development

Once connected, any changes you make to `.lua` files in your code editor will automatically sync to Roblox Studio:

1. **Edit code** in your preferred editor (VS Code, etc.)
2. **Save the file** - Changes sync automatically
3. **Test in Roblox Studio** - Press F5 to play and test your changes
4. **Repeat** - The workflow is instant and seamless

**Important Notes:**
- The Rojo server must remain running during development
- Changes sync from **code → Studio**, not Studio → code
- Always edit `.lua` files in your code editor, not in Studio
- Studio changes will be overwritten on next sync

## 📁 Project Structure

### Server (`src/Server/`)
Server-side game logic that runs on Roblox servers:
- **Main.server.lua** - Server initialization and service loading
- **Services/** - Core game services:
  - **DataService** - Player data persistence and management
  - **PlayerService** - Player joining, leaving, and state management
  - **RealmService** - Realm creation, portals, and cross-realm logic
  - **SpiritService** - Spirit collection, upgrades, and inventory

### Client (`src/Client/`)
Client-side code that runs on each player's device:
- **Main.client.lua** - Client initialization and controller loading
- **Controllers/** - Client-side logic:
  - **UIController** - User interface management and updates
  - **CombatController** - Combat input handling and visual feedback

### Shared (`src/Shared/`)
Code accessible by both server and client:
- **Modules/Constants.lua** - Game constants, enums, and configuration
- **Modules/Signal.lua** - Event system for communication
- **Modules/Maid.lua** - Memory management and cleanup utility

### Configuration
- **default.project.json** - Rojo sync configuration
- **roblox-config.json** - Roblox API configuration
- **.gitignore** - Git ignore rules

### Documentation
- **plans/technical-architecture.md** - Detailed technical design document
- **SETUP-ROBLOX-EXPERIENCE.md** - Roblox Cloud setup guide

## 📖 Documentation

### Technical Architecture
For detailed information about the game's architecture, systems, and design decisions, see:
- [Technical Architecture Document](plans/technical-architecture.md)

This document covers:
- Game systems overview
- Spirit system mechanics
- Realm system design
- Combat mechanics
- Data persistence strategy
- Client-server communication

### Roblox Experience Setup
For information on creating and configuring your Roblox Experience:
- [Roblox Experience Setup Guide](SETUP-ROBLOX-EXPERIENCE.md)

## 🔗 Links

- **GitHub Repository:** https://github.com/pdarleyjr/aetheria-omni-verse
- **Rojo Documentation:** https://rojo.space/docs/
- **Roblox Creator Hub:** https://create.roblox.com/docs

## 🎮 Next Steps

After setting up the development environment:

1. **Create your Roblox Experience:**
   - Go to [Roblox Creator Dashboard](https://create.roblox.com/dashboard/creations)
   - Click "Create" → "Experience"
   - Name it "Aetheria Omni-Verse"
   - Configure settings (public/private, age rating, etc.)
   - See [SETUP-ROBLOX-EXPERIENCE.md](SETUP-ROBLOX-EXPERIENCE.md) for details

2. **Build the game world:**
   - Create the starting area/hub
   - Build the 7 elemental realm environments
   - Place portal locations between realms
   - Design combat arenas and testing areas

3. **Configure RemoteEvents:**
   - Add necessary RemoteEvents in ReplicatedStorage
   - Implement client-server communication
   - Test data flow and combat mechanics

4. **Implement UI:**
   - Design spirit inventory interface
   - Create combat HUD
   - Build realm selection screen
   - Add player stats display

5. **Test and iterate:**
   - Test single-player functionality
   - Test multiplayer with friends
   - Balance combat and spirit stats
   - Refine realm mechanics

6. **Prepare for launch:**
   - Set up game passes (if desired)
   - Configure monetization
   - Create promotional materials
   - Set up analytics tracking

## 🤝 Contributing

This is a personal project, but contributions and suggestions are welcome! Feel free to:
- Open issues for bugs or feature requests
- Submit pull requests with improvements
- Share feedback and ideas

## 📄 License

This project is open source and available for learning purposes. Please respect Roblox's Terms of Service when using this code.

## 🎯 Development Status

**Current Phase:** Initial Development
- ✅ Project structure created
- ✅ Core services implemented
- ✅ Client controllers established
- ✅ Constants and shared modules defined
- ⏳ Roblox Experience creation pending
- ⏳ World building pending
- ⏳ UI implementation pending
- ⏳ Testing and balancing pending

---

**Built with ❤️ for the Roblox community**

For questions or support, please open an issue on GitHub.
