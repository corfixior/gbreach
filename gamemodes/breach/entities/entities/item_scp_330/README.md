# SCP-330 Implementation for Breach Gamemode

## Overview
SCP-330 "A Bag of Tricks" is a fully functional anomalous entity implementation for the Breach gamemode. It's based on the original SCP-330 addon but adapted for full compatibility with the Breach framework.

## Features

### Core Functionality
- **Candy Bowl**: Interactive entity that dispenses anomalous candies
- **Two Candy Limit**: Players can safely take up to 2 candies
- **Hand Severance**: Taking a 3rd candy results in permanent hand loss
- **Bleeding Effect**: Hand loss causes severe bleeding for 15 minutes
- **Weapon Restriction**: Players with severed hands cannot pick up weapons

### Visual Effects
- **Proximity Warning**: Text warning appears when approaching SCP-330
- **Blood Overlay**: Visual bleeding effects with screen overlay
- **Motion Blur**: Disorienting effects during hand loss
- **Sound Effects**: Full sound package including warnings and effects

### Breach Integration
- **Logging System**: All interactions logged through Breach framework
- **Admin Commands**: Full set of admin controls
- **Player Tracking**: Persistent player state across rounds
- **Team Compatibility**: Works with all Breach teams and roles

## File Structure

```
gamemodes/breach/entities/entities/item_scp_330/
├── shared.lua          # Entity definition and shared properties
├── init.lua           # Server-side entity logic
├── cl_init.lua        # Client-side entity effects
└── README.md          # This documentation

gamemodes/breach/entities/weapons/
└── weapon_scp330_candy.lua    # Candy consumption weapon

gamemodes/breach/gamemode/modules/
├── sv_scp330.lua      # Server module with global functions
└── cl_scp330.lua      # Client module with effects
```

## Configuration

Edit `SCP330.Config` in `sv_scp330.lua`:

```lua
SCP330.Config = {
    MaxCandies = 2,           -- Maximum safe candies (default: 2)
    BleedDamage = 5,          -- Damage per bleed tick (default: 5)
    BleedInterval = 10,       -- Seconds between damage (default: 10)
    BleedDuration = 900,      -- Total bleeding time in seconds (default: 15 min)
    ProximityRadius = 150,    -- Warning trigger distance (default: 150)
    HandRemovalTime = 300     -- Hand prop cleanup time (default: 5 min)
}
```

## Admin Commands

### Spawning
```
scp330_spawn
```
Spawns SCP-330 at crosshair position (admin only)

### Player Management
```
scp330_reset_player <player_name>
```
Resets SCP-330 effects for specified player (admin only)

### Information
```
scp330_info
```
Displays SCP-330 statistics and active effects (admin only)

## Global Functions

### Server Functions (SCP330)
- `SCP330:InitPlayer(ply)` - Initialize player data
- `SCP330:ResetPlayer(ply)` - Reset all player effects
- `SCP330:CanTakeCandy(ply)` - Check if player can take candy
- `SCP330:GetCandyCount(ply)` - Get player's candy count
- `SCP330:GetRandomFlavor()` - Get random candy flavor
- `SCP330:Log(message, category)` - Log events

### Client Functions (SCP330.Client)
- `SCP330.Client:PlaySound(soundPath)` - Play sound effect
- `SCP330.Client:CreateBloodOverlay()` - Show blood effect
- `SCP330.Client:CreateProximityWarning(entity)` - Show warning text

## Network Messages

- `SCP330_PlaySound` - Play sound on client
- `SCP330_BloodEffect` - Trigger blood overlay
- `SCP330_ProximityWarning` - Show proximity warning

## Player Data Structure

```lua
SCP330.PlayerData[steamID] = {
    candyTaken = 0,      -- Number of candies taken
    handsCut = false,    -- Whether hands are severed
    bleeding = false,    -- Currently bleeding status
    lastInteraction = 0  -- Last interaction timestamp
}
```

## Candy Flavors

Available candy flavors:
- Strawberry, Apple, Cherry, Orange, Lemon, Banana
- Raspberry, Blueberry, Pineapple, Melon, Watermelon
- Peach, Pear, Apricot, Plum, Mango, Kiwi, Fig, Grape, Hazelnut

## Sound Requirements

The following sounds should be present in `sound/scp_330/`:
- `pick_candy.mp3` - Taking candy sound
- `consume_candy.mp3` - Eating candy sound
- `cut_hands.mp3` - Hand severance sound
- `you_got_what_you_deserve.mp3` - Punishment sound
- `on_first_contact.mp3` - Proximity warning sound
- `heavy_breath_1.mp3`, `heavy_breath_2.mp3`, `heavy_breath_3.mp3` - Bleeding sounds

## Model Requirements

Required models:
- `models/scp_330/scp_330.mdl` - Main SCP-330 bowl
- `models/scp_330/scp_330_hand.mdl` - Severed hand prop
- `models/weapons/scp_330/v_scp_330.mdl` - Candy viewmodel
- `models/weapons/scp_330/w_scp_330.mdl` - Candy worldmodel

## Compatibility

- Fully compatible with Breach gamemode framework
- Uses Breach logging system
- Integrates with team system
- Respects admin permissions
- Compatible with other SCP entities

## Notes

- Player data persists across map changes
- Effects are automatically cleaned up on player death/respawn
- Hand severance effect is permanent until manual reset
- All interactions are logged for admin monitoring
- Client-side effects are optimized for performance

## Troubleshooting

### Common Issues
1. **Sounds not playing**: Ensure sound files are in correct directory
2. **Models not loading**: Verify model files are present
3. **Effects not showing**: Check client module is loaded
4. **Admin commands not working**: Verify admin permissions

### Debug Commands (Admin Only)
```
scp330_test_blood    # Test blood overlay effect
scp330_test_warning  # Test proximity warning
```

## Credits

Based on the original SCP-330 addon by MrMarrant, adapted for Breach gamemode compatibility by the Breach development team. 