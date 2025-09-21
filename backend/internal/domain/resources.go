package domain

import (
	"time"
)

// ResourceType represents different types of resources in the game
type ResourceType string

const (
	ResourceGold ResourceType = "gold"
	ResourceMana ResourceType = "mana"
)

// Resources holds the current resource values for a player
type Resources struct {
	Gold int `json:"gold"`
	Mana int `json:"mana"`
}

// BuildingType represents different types of buildings
type BuildingType string

const (
	BuildingCommandCenter BuildingType = "command_center"
	// Future building types can be added here
)

// BuildingLevel represents the level of a building
type BuildingLevel int

const (
	Level1 BuildingLevel = 1
	Level2 BuildingLevel = 2
	Level3 BuildingLevel = 3
)

// ResourceGeneration defines how many resources a building generates
type ResourceGeneration struct {
	Gold int `json:"gold"`
	Mana int `json:"mana"`
}

// Building represents a building that can generate resources
type Building struct {
	Type              BuildingType       `json:"type"`
	Level             BuildingLevel      `json:"level"`
	PlayerIndex       int                `json:"playerIndex"`
	TopLeftRow        int                `json:"topLeftRow"`
	TopLeftCol        int                `json:"topLeftCol"`
	TurnsSinceUpgrade int                `json:"turnsSinceUpgrade"`
	LastUpgradeTime   time.Time          `json:"lastUpgradeTime"`
	ResourceGen       ResourceGeneration `json:"resourceGeneration"`
}

// GetResourceGeneration returns the resource generation for a building based on its type and level
func (b *Building) GetResourceGeneration() ResourceGeneration {
	switch b.Type {
	case BuildingCommandCenter:
		switch b.Level {
		case Level1:
			return ResourceGeneration{Gold: 3, Mana: 2}
		case Level2:
			return ResourceGeneration{Gold: 6, Mana: 4}
		case Level3:
			return ResourceGeneration{Gold: 10, Mana: 6}
		default:
			return ResourceGeneration{Gold: 3, Mana: 2}
		}
	default:
		return ResourceGeneration{Gold: 0, Mana: 0}
	}
}

// ShouldUpgrade checks if the building should upgrade based on turns passed
func (b *Building) ShouldUpgrade() bool {
	if b.Type != BuildingCommandCenter {
		return false
	}
	
	// Command centers upgrade every 3 turns
	if b.Level < Level3 && b.TurnsSinceUpgrade >= 3 {
		return true
	}
	
	return false
}

// Upgrade upgrades the building to the next level
func (b *Building) Upgrade() bool {
	if b.Level >= Level3 {
		return false
	}
	
	b.Level++
	b.TurnsSinceUpgrade = 0
	b.LastUpgradeTime = time.Now()
	b.ResourceGen = b.GetResourceGeneration()
	
	return true
}

// IncrementTurnCounter increments the turns since last upgrade
func (b *Building) IncrementTurnCounter() {
	b.TurnsSinceUpgrade++
}

// NewBuilding creates a new building
func NewBuilding(buildingType BuildingType, playerIndex, row, col int) *Building {
	b := &Building{
		Type:              buildingType,
		Level:             Level1,
		PlayerIndex:       playerIndex,
		TopLeftRow:        row,
		TopLeftCol:        col,
		TurnsSinceUpgrade: 0,
		LastUpgradeTime:   time.Now(),
	}
	b.ResourceGen = b.GetResourceGeneration()
	return b
}

// CommandCenterBuilding extends CommandCenter with building functionality
type CommandCenterBuilding struct {
	*CommandCenter
	*Building
}

// NewCommandCenterBuilding creates a command center with building functionality
func NewCommandCenterBuilding(playerIndex, topLeftRow, topLeftCol int) *CommandCenterBuilding {
	return &CommandCenterBuilding{
		CommandCenter: NewCommandCenter(playerIndex, topLeftRow, topLeftCol),
		Building:      NewBuilding(BuildingCommandCenter, playerIndex, topLeftRow, topLeftCol),
	}
}