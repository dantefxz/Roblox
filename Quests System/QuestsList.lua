local quests = {
	Limited = {
		
	},
	Normal = {
		["KillGremlings"] = {Title = "Gremling Extermination", Description = "Kill 5 Gremlings", Progress = 5, Type = "Kill", Mob = "Gremling", Rewards = {Tokens = 450, Packages = {}, Masks = {}, Boosts = {}}},
		["Spend70"] = {Title = "We are rich", Description = "Spend $70", Progress = 70, Rewards = {Tokens = 250, Packages = {}, Masks = {}, Boosts = {}}},
		["Burn20"] = {Title = "Fuel, fuel, fuel!", Description = "Burn 20 Items", Progress = 20, Rewards = {Tokens = 250, Packages = {}, Masks = {}, Boosts = {}}},
		["Sell20"] = {Title = "Salesman", Description = "Sell 20 Items", Progress = 20, Rewards = {Tokens = 250, Packages = {}, Masks = {}, Boosts = {}}},
		["Reach800"] = {Title = "Experienced Adventurer", Description = "Reach 800 meters", Progress = 1, Rewards = {Tokens = 450, Packages = {}, Masks = {}, Boosts = {}}},
		["10Fireflies"] = {Title = "Firefly enjoyer", Description = "Catch 10 Fireflies", Progress = 10, Rewards = {Tokens = 250, Packages = {}, Masks = {}, Boosts = {}}},
		["5Potions"] = {Title = "Magic drinks", Description = "Drink 5 potions", Progress = 5, Rewards = {Tokens = 450, Packages = {}, Masks = {}, Boosts = {}}},
		["1Stalker"] = {Title = "Stalker killer", Description = "Kill 1 Stalker", Progress = 1, Type = "Kill", Mob = "Stalker", Rewards = {Tokens = 600, Packages = {}, Masks = {}, Boosts = {}}},
		["1FleshHunter"] = {Title = "Flesh Hunter (or not)", Description = "Kill 1 Flesh Hunter", Progress = 1, Type = "Kill", Mob = "FleshHunter", Rewards = {Tokens = 600, Packages = {}, Masks = {}, Boosts = {}}},
		["Playtime"] = {Title = "I like playing Exiled", Description = "Play the game", Progress = {15, 30}, Rewards = {Tokens = 250, Packages = {}, Masks = {}, Boosts = {}}},
	},
	Premium = {
		["PlaytimePremium"] = {Title = "Exiled, Exiled, Exiled", Description = "Play the game", Progress = {30, 45, 60}, Rewards = {Tokens = 250, Packages = {}, Masks = {}, Boosts = {}}},
	}
}

return quests