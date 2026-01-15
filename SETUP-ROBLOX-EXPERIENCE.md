# Roblox Experience Setup Instructions

## Current Status

The Rojo configuration has been prepared with placeholder values. The Roblox Open Cloud API does not support creating new experiences programmatically - they must be created through Roblox Studio or the Creator Hub website.

## Two Options to Create the Experience

### Option 1: Automated Browser Creation (Recommended if you have Node.js)

Run the automated script:

```bash
node create-roblox-experience.js YOUR_ROBLOX_USERNAME YOUR_ROBLOX_PASSWORD
```

This will:
- Open a browser window
- Log into Roblox
- Create the experience "Aetheria: The Omni-Verse"
- Automatically update [`roblox-config.json`](roblox-config.json) and [`default.project.json`](default.project.json)

### Option 2: Manual Creation in Roblox Studio (Fastest - 2 minutes)

1. **Open Roblox Studio**
2. **Create New Experience:**
   - Click `File` > `Publish to Roblox As...`
   - Name: `Aetheria: The Omni-Verse`
   - Description: `Explore infinite realms, collect and breed spirits, engage in action combat, and build your own realm in this multiplayer adventure.`
   - Click `Create`

3. **Get the IDs:**
   - After publishing, go to `Home` tab in Studio
   - Note the **Universe ID** and **Place ID** (or find them in Game Settings > Security)

4. **Update Configuration:**
   ```bash
   node update-rojo-config.js YOUR_UNIVERSE_ID YOUR_PLACE_ID
   ```
   
   Example:
   ```bash
   node update-rojo-config.js 5477225588 15845655888
   ```

## Find Your IDs

You can find your Universe ID and Place ID in multiple ways:

1. **In Roblox Studio:**
   - `File` > `Game Settings` > `Security`
   - Both IDs are displayed there

2. **In Creator Hub:**
   - Go to https://create.roblox.com/dashboard/creations
   - Open your experience
   - The URL will be: `.../experiences/{UNIVERSE_ID}/places/{PLACE_ID}`

3. **From your Experience URL:**
   - Your game URL: `https://www.roblox.com/games/{PLACE_ID}/game-name`
   - The Place ID is in the URL

##  Files Created

- [`roblox-config.json`](roblox-config.json) - Stores Universe ID, Place ID, and experience metadata
- [`default.project.json`](default.project.json) - Rojo configuration (updated with `servePlaceIds`)
- [`create-roblox-experience.js`](create-roblox-experience.js) - Automated browser creation script
- [`update-rojo-config.js`](update-rojo-config.js) - Helper to update config with your IDs

## Next Steps After Configuration

Once your configuration files have the actual IDs:

1. **Start Rojo Server:**
   ```bash
   rojo serve
   ```

2. **Connect from Studio:**
   - Open your experience in Roblox Studio
   - Open the Rojo plugin (View > Plugins > Rojo)
   - Click `Connect` (should show localhost:34872)
   - Your code will sync!

## Need Help?

- Can't find IDs? Check [Roblox Creator Documentation](https://create.roblox.com/docs/cloud/open-cloud)
- Rojo not connecting? Ensure the Place ID in [`default.project.json`](default.project.json:3) matches your Studio place
- API Key issues? Verify at https://create.roblox.com/credentials

## Configuration Files

Currently configured for:
- **Experience Name:** Aetheria: The Omni-Verse
- **Description:** Explore infinite realms, collect and breed spirits, engage in action combat, and build your own realm in this multiplayer adventure.
- **Universe ID:** `PLACEHOLDER_UNIVERSE_ID` ⚠️ Update required
- **Place ID:** `PLACEHOLDER_PLACE_ID` ⚠️ Update required
