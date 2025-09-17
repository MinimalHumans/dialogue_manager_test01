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

# Starting player Social DNA for Phase 2 (lower values to see progression)
var player_social_dna = {
	SocialType.AGGRESSIVE: 20,
	SocialType.DIPLOMATIC: 60,
	SocialType.CHARMING: 10,
	SocialType.DIRECT: 80,
	SocialType.EMPATHETIC: 30
}

# Track total social power (for progression display)
var total_social_power: int = 0

# Global variable to track the last choice made in dialogue
var last_dialogue_choice: int = -1

# Phase 3 conversation system variables
var advance_turn: bool = false
var player_choice: int = -1

# Conversation manager instance (will be set by conversation system)
var conversation_manager: ConversationManager = null

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

# Signal for when Social DNA changes
signal social_dna_changed(old_profile: Dictionary, new_profile: Dictionary)

func _ready():
	_calculate_total_social_power()

func _calculate_total_social_power():
	total_social_power = 0
	for social_type in player_social_dna:
		total_social_power += player_social_dna[social_type]

# CONVERSATION MANAGER WRAPPER METHODS (for Dialogue Manager)
# These methods delegate to the active conversation manager

func set_advance_turn():
	print("SocialDNAManager.set_advance_turn() called")
	if conversation_manager:
		conversation_manager.set_advance_turn()
		print("  -> Delegated to conversation_manager.set_advance_turn()")
	else:
		print("  ERROR: No conversation_manager set in SocialDNAManager")
		# Fallback for Phase 2 compatibility
		advance_turn = true

func set_player_choice_and_advance(choice: int):
	print("SocialDNAManager.set_player_choice_and_advance(%d) called" % choice)
	if conversation_manager:
		conversation_manager.set_player_choice_and_advance(choice)
		print("  -> Delegated to conversation_manager")
	else:
		print("  ERROR: No conversation_manager set - using fallback")
		# Fallback for Phase 2 compatibility
		last_dialogue_choice = choice
		advance_turn = true

# Set the active conversation manager (called by NPCs)
func set_active_conversation_manager(manager: ConversationManager):
	conversation_manager = manager
	print("SocialDNAManager: Active conversation manager set")

# Clear the active conversation manager
func clear_active_conversation_manager():
	conversation_manager = null
	print("SocialDNAManager: Active conversation manager cleared")

# Process a player dialogue choice and update Social DNA
func process_dialogue_choice(choice_type: SocialType):
	print("Processing choice: %s" % get_social_type_name(choice_type))
	
	# Store old profile for comparison
	var old_profile = player_social_dna.duplicate()
	
	# Add +1 to all categories (general social development)
	for social_type in player_social_dna:
		player_social_dna[social_type] += 1
	
	# Add +2 bonus to the specific choice category
	player_social_dna[choice_type] += 2
	
	# Recalculate total power
	var old_total = total_social_power
	_calculate_total_social_power()
	
	print("Social DNA updated: %s +3, others +1 (Total: %d → %d)" % [
		get_social_type_name(choice_type), 
		old_total, 
		total_social_power
	])
	
	# Emit signal for UI updates
	social_dna_changed.emit(old_profile, player_social_dna.duplicate())

# Process the last dialogue choice (called after dialogue ends)
func process_last_choice():
	if last_dialogue_choice >= 0:
		print("Processing last dialogue choice: %d" % last_dialogue_choice)
		var social_type = last_dialogue_choice as SocialType
		process_dialogue_choice(social_type)
		last_dialogue_choice = -1  # Reset
	else:
		print("No dialogue choice to process")

# Legacy function for backward compatibility (in case dialogue still calls it)
func process_choice(social_type_value: int):
	print("Legacy process_choice called with value: %d" % social_type_value)
	var social_type = social_type_value as SocialType
	process_dialogue_choice(social_type)

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

# Get the player's dominant social traits (for personality analysis)
func get_dominant_traits(top_n: int = 2) -> Array:
	var sorted_traits = []
	for social_type in player_social_dna:
		sorted_traits.append({
			"type": social_type,
			"value": player_social_dna[social_type],
			"name": get_social_type_name(social_type)
		})
	
	sorted_traits.sort_custom(func(a, b): return a.value > b.value)
	return sorted_traits.slice(0, top_n)

# Get player social percentages (for progression display)
func get_social_percentages() -> Dictionary:
	var percentages = {}
	for social_type in player_social_dna:
		percentages[social_type] = (player_social_dna[social_type] * 100.0) / total_social_power if total_social_power > 0 else 0
	return percentages

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
