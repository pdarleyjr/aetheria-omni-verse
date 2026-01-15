/**
 * Roblox Experience Creator
 * This script automates the creation of a Roblox experience via browser automation
 * 
 * Run with: node create-roblox-experience.js <username> <password>
 */

const puppeteer = require('puppeteer');
const fs = require('fs');

async function createRobloxExperience(username, password) {
    const browser = await puppeteer.launch({ 
        headless: false,
        defaultViewport: { width: 1280, height: 800 }
    });
    
    try {
        const page = await browser.newPage();
        
        // Navigate to Roblox login
        console.log('Navigating to Roblox login...');
        await page.goto('https://www.roblox.com/login', { waitUntil: 'networkidle2' });
        
        // Fill in credentials
        console.log('Entering credentials...');
        await page.type('#login-username', username);
        await page.type('#login-password', password);
        await page.click('#login-button');
        
        // Wait for login to complete
        await page.waitForNavigation({ waitUntil: 'networkidle2', timeout: 30000 });
        console.log('Logged in successfully');
        
        // Navigate to Creator Hub
        console.log('Navigating to Creator Hub...');
        await page.goto('https://create.roblox.com/dashboard/creations', { waitUntil: 'networkidle2' });
        
        // Wait a bit for the page to load fully
        await page.waitForTimeout(3000);
        
        // Look for "Create New" or similar button
        await page.click('button:has-text("Create"), button:has-text("New")');
        await page.waitForTimeout(1000);
        
        // Click on "Experience" option
        await page.click('text=Experience');
        await page.waitForTimeout(2000);
        
        // Fill in experience details
        await page.fill('input[placeholder*="name"], input[name="name"]', 'Aetheria: The Omni-Verse');
        await page.fill('textarea[placeholder*="description"], textarea[name="description"]', 
            'Explore infinite realms, collect and breed spirits, engage in action combat, and build your own realm in this multiplayer adventure.');
        
        // Click create/submit button
        await page.click('button[type="submit"], button:has-text("Create")');
        
        // Wait for the experience to be created
        await page.waitForTimeout(5000);
        
        // Try to extract Universe ID and Place ID from the URL or page
        const url = page.url();
        console.log('Current URL:', url);
        
        // Extract IDs from URL (typical format: /dashboard/creations/experiences/{universeId}/places/{placeId})
        const universeMatch = url.match(/experiences\/(\d+)/);
        const placeMatch = url.match(/places\/(\d+)/);
        
        const universeId = universeMatch ? universeMatch[1] : null;
        const placeId = placeMatch ? placeMatch[1] : null;
        
        if (universeId && placeId) {
            console.log('\n=== Experience Created Successfully ===');
            console.log('Universe ID:', universeId);
            console.log('Place ID:', placeId);
            
            // Save to config file
            const config = {
                universeId: universeId,
                placeId: placeId,
                experienceName: 'Aetheria: The Omni-Verse',
                createdAt: new Date().toISOString(),
                experienceUrl: `https://www.roblox.com/games/${placeId}/`
            };
            
            fs.writeFileSync('roblox-config.json', JSON.stringify(config, null, 2));
            console.log('\nConfiguration saved to roblox-config.json');
            
            // Update Rojo configuration
            const rojoConfig = JSON.parse(fs.readFileSync('default.project.json', 'utf8'));
            rojoConfig.servePlaceIds = [parseInt(placeId)];
            fs.writeFileSync('default.project.json', JSON.stringify(rojoConfig, null, 2));
            console.log('Updated default.project.json with Place ID');
            
            return { universeId, placeId };
        } else {
            console.error('Could not extract Universe ID and Place ID from the page');
            console.log('Please manually check the Creator Hub and provide the IDs');
        }
        
    } catch (error) {
        console.error('Error creating experience:', error.message);
        console.log('\nPlease create the experience manually in Roblox Studio:');
        console.log('1. Open Roblox Studio');
        console.log('2. Click File > Publish to Roblox As...');
        console.log('3. Create new experience: "Aetheria: The Omni-Verse"');
        console.log('4. Note the Universe ID and Place ID from the Home tab');
    } finally {
        await browser.close();
    }
}

// Main execution
if (require.main === module) {
    const args = process.argv.slice(2);
    
    if (args.length < 2) {
        console.log('Usage: node create-roblox-experience.js <username> <password>');
        process.exit(1);
    }
    
    const [username, password] = args;
    createRobloxExperience(username, password);
}

module.exports = { createRobloxExperience };
