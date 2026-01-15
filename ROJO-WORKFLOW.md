# Rojo Development Workflow

## ✅ Current Status
- **Rojo Server**: Running on `localhost:34872`
- **Studio Connection**: Connected (Rojo plugin v7.6.1)
- **Place ID**: `54992c9727795896097`
- **Experience**: Aetheria: The Omni-Verse

## 🔄 How Syncing Works

```
VSCode Files → Rojo Server → Roblox Studio → Publish → Live Game
```

### Real-Time Sync (Active Now)
1. Edit any `.lua` file in VSCode
2. Save the file (`Ctrl+S`)
3. Changes **automatically sync** to Roblox Studio within 1-2 seconds
4. Check the Studio Output window for sync confirmation

## 🎮 Testing Your Changes

### Local Testing (Recommended)
1. Keep Rojo server running in terminal
2. In Roblox Studio, click **Play** (F5)
3. Test your game locally
4. Make changes in VSCode
5. Stop testing, changes sync, test again

### Publish to Live Game
1. In Studio: **File** > **Publish to Roblox**
2. Or press `Alt+P`
3. Your changes go live immediately
4. Players can access at: https://www.roblox.com/games/54992c9727795896097/

## 📁 File Structure

All your code is in the `src/` folder:
- `src/Server/` → Goes to `ServerScriptService`
- `src/Client/` → Goes to `StarterPlayer.StarterPlayerScripts`
- `src/Shared/` → Goes to `ReplicatedStorage`

## 🔧 Important Commands

### Start Rojo Server
```powershell
# From project directory
"C:\Users\Peter Darley\AppData\Local\Microsoft\WinGet\Packages\Rojo.Rojo_Microsoft.Winget.Source_8wekyb3d8bbwe\rojo.exe" serve
```

### Or use the alias (after restarting terminal)
```powershell
rojo serve
```

### Build .rbxl File (Alternative Workflow)
```powershell
rojo build -o AetheriaOmniVerse.rbxl
```
Then open the .rbxl file directly in Studio

## 🚨 Troubleshooting

### "Session has been terminated"
- Rojo server was stopped or crashed
- Restart the server and click "Connect" again in Studio

### Changes Not Syncing
1. Check Rojo terminal - server must be running
2. Check Studio Output for sync messages
3. Ensure files are saved in VSCode
4. Click "Sync In" button in Rojo plugin if needed

### Port 34872 Already in Use
```powershell
# Kill existing Rojo process
taskkill /F /IM rojo.exe
# Then restart
rojo serve
```

## 💡 Pro Tips

1. **Keep Server Running**: Leave the Rojo terminal open while developing
2. **Watch Output**: Studio's Output window shows sync status
3. **Commit Often**: Your code is in Git - commit changes regularly
4. **Test First**: Always test in Studio before publishing
5. **Hot Reloading**: Most changes sync instantly, but some require stopping/restarting the game

## 📝 Current Project Files

- **Main Server Entry**: [`src/Server/Main.server.lua`](src/Server/Main.server.lua)
- **Main Client Entry**: [`src/Client/Main.client.lua`](src/Client/Main.client.lua)
- **Services**: `src/Server/Services/`
- **Controllers**: `src/Client/Controllers/`
- **Shared Modules**: `src/Shared/Modules/`

## 🎯 Next Steps

1. ✅ Rojo server is running
2. ✅ Studio is connected
3. 🎮 **Test in Studio** - Click Play to test locally
4. 🚀 **Publish** - Make your game live when ready!
