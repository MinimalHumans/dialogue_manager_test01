extends Node

# Social DNA categories
enum SocialType {
	AGGRESSIVE,
	DIPLOMATIC,
	CHARMING,
	DIRECT,
	EMPATHETIC
}

# NPC Archetypes
enum NPCArchetype {
	AUTHORITY,
	INTELLECTUAL
}

# Hard-coded player Social DNA for Phase 1
var player_social_dna = {
	SocialType.AGGRESSIVE: 20,
	SocialType.DIPLOMATIC: 60,
	SocialType.CHARMING: 10,
	SocialType.DIRECT: 80,
	SocialType.EMPATHETIC: 30
}

# NPC compatibility matrices
var npc_compatibility = {
	NPCArchetype.AUTHORITY: {
		SocialType.DIRECT: 2,        # ++
		SocialType.AGGRESSIVE: 1,    # +
		SocialType.DIPLOMATIC: 0,    # neutral
		SocialType.EMPATHETIC: -1,   # -
		SocialType.CHARMING: -2      # --
	},
	NPCArchetype.INTELLECTUAL: {
		SocialType.DIPLOMATIC: 2,    # ++
		SocialType.DIRECT: 1,        # +
		SocialType.EMPATHETIC: 1,    # +
		SocialType.CHARMING: 0,      # neutral
		SocialType.AGGRESSIVE: -2    # --
	}
}

# Calculate compatibility between player and NPC
func calculate_compatibility(npc_archetype: NPCArchetype) -> float:
	var total_compatibility = 0.0
	var compatibility_matrix = npc_compatibility[npc_archetype]
	
	for social_type in player_social_dna:
		var player_strength = player_social_dna[social_type]
		var npc_preference = compatibility_matrix.get(social_type, 0)
		
		# Weight by player's strength in this social type
		total_compatibility += (player_strength / 100.0) * npc_preference
	
	return total_compatibility

# Get compatibility description for UI
func get_compatibility_description(compatibility: float) -> String:
	if compatibility >= 1.0:
		return "Very Compatible"
	elif compatibility >= 0.5:
		return "Compatible" 
	elif compatibility >= -0.5:
		return "Neutral"
	elif compatibility >= -1.0:
		return "Incompatible"
	else:
		return "Very Incompatible"

# Get social type name as string
func get_social_type_name(type: SocialType) -> String:
	match type:
		SocialType.AGGRESSIVE: return "Aggressive"
		SocialType.DIPLOMATIC: return "Diplomatic"
		SocialType.CHARMING: return "Charming"
		SocialType.DIRECT: return "Direct"
		SocialType.EMPATHETIC: return "Empathetic"
		_: return "Unknown"

# Get archetype name as string
func get_archetype_name(archetype: NPCArchetype) -> String:
	match archetype:
		NPCArchetype.AUTHORITY: return "Authority"
		NPCArchetype.INTELLECTUAL: return "Intellectual"
		_: return "Unknown"
