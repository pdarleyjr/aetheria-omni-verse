/**
 * Update Rojo Configuration with Roblox Experience IDs
 * Run: node update-rojo-config.js <universeId> <placeId>
 */

const fs = require('fs');

function updateConfiguration(universeId, placeId) {
    try {
        // Update roblox-config.json
        const robloxConfig = JSON.parse(fs.readFileSync('roblox-config.json', 'utf8'));
        robloxConfig.universeId = universeId;
        robloxConfig.placeId = placeId;
        robloxConfig.experienceUrl = `https://www.roblox.com/games/${placeId}/`;
        delete robloxConfig.instructions; // Remove instruction field
        fs.writeFileSync('roblox-config.json', JSON.stringify(robloxConfig, null, 2));
        console.log('✓ Updated roblox-config.json');
        
        // Update default.project.json
        const rojoConfig = JSON.parse(fs.readFileSync('default.project.json', 'utf8'));
        rojoConfig.servePlaceIds = [parseInt(placeId)];
        fs.writeFileSync('default.project.json', JSON.stringify(rojoConfig, null, 2));
        console.log('✓ Updated default.project.json');
        
        console.log('\nConfiguration updated successfully!');
        console.log('Universe ID:', universeId);
        console.log('Place ID:', placeId);
        console.log('Experience URL:', `https://www.roblox.com/games/${placeId}/`);
        console.log('\nNext steps:');
        console.log('1. Run: rojo serve');
        console.log('2. In Roblox Studio, open the Rojo plugin');
        console.log('3. Click "Connect" and sync your code');
        
    } catch (error) {
        console.error('Error updating configuration:', error.message);
        process.exit(1);
    }
}

if (require.main === module) {
    const args = process.argv.slice(2);
    
    if (args.length < 2) {
        console.log('Usage: node update-rojo-config.js <universeId> <placeId>');
        console.log('\nExample: node update-rojo-config.js 123456789 987654321');
        console.log('\nTo find these IDs:');
        console.log('1. Open your experience in Roblox Studio');
        console.log('2. Go to File > Game Settings > Security');
        console.log('3. Universe ID and Place ID are shown there');
        console.log('\nOr find them in the Creator Hub URL:');
        console.log('https://create.roblox.com/dashboard/creations/experiences/[UNIVERSE_ID]/places/[PLACE_ID]');
        process.exit(1);
    }
    
    const [universeId, placeId] = args;
    updateConfiguration(universeId, placeId);
}

module.exports = { updateConfiguration };
