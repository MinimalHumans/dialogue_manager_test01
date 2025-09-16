extends Node2D

@onready var player_stats_label = $CanvasLayer/VBoxContainer/PlayerStatsLabel
@onready var profile_dropdown = $CanvasLayer/VBoxContainer/ProfileDropdown
@onready var phase_toggle_button = $CanvasLayer/VBoxContainer/PhaseToggleButton
@onready var progression_label = $CanvasLayer/VBoxContainer/ProgressionLabel
@onready var instructions_label = $CanvasLayer/VBoxContainer/InstructionsLabel
@onready var relationships_label = $CanvasLayer/VBoxContainer/RelationshipsLabel

# Define test profiles
var test_profiles = {
	"Phase 2 Starting Profile": {
		SocialDNAManager.SocialType.AGGRESSIVE: 10,
		SocialDNAManager.SocialType.DIPLOMATIC: 10,
		SocialDNAManager.SocialType.CHARMING: 10,
		SocialDNAManager.SocialType.DIRECT: 10,
		SocialDNAManager.SocialType.EMPATHETIC: 10
	},
	"Default (Phase 1)": {
		SocialDNAManager.SocialType.AGGRESSIVE: 20,
		SocialDNAManager.SocialType.DIPLOMATIC: 60,
		SocialDNAManager.SocialType.CHARMING: 10,
		SocialDNAManager.SocialType.DIRECT: 80,
		SocialDNAManager.SocialType.EMPATHETIC: 30
	},
	"Authority Friendly": {
		SocialDNAManager.SocialType.AGGRESSIVE: 80,
		SocialDNAManager.SocialType.DIPLOMATIC: 10,
		SocialDNAManager.SocialType.CHARMING: 5,
		SocialDNAManager.SocialType.DIRECT: 95,
		SocialDNAManager.SocialType.EMPATHETIC: 10
	},
	"Intellectual Friendly": {
		SocialDNAManager.SocialType.AGGRESSIVE: 5,
		SocialDNAManager.SocialType.DIPLOMATIC: 95,
		SocialDNAManager.SocialType.CHARMING: 10,
		SocialDNAManager.SocialType.DIRECT: 70,
		SocialDNAManager.SocialType.EMPATHETIC: 85
	},
	"Low Compatibility": {
		SocialDNAManager.SocialType.AGGRESSIVE: 10,
		SocialDNAManager.SocialType.DIPLOMATIC: 10,
		SocialDNAManager.SocialType.CHARMING: 90,
		SocialDNAManager.SocialType.DIRECT: 5,
		SocialDNAManager.SocialType.EMPATHETIC: 15
	}
}

var current_profile_name = "Phase 2 Starting Profile"
var is_phase2_mode = true

func _ready():
	# Ensure SocialDNAManager is available to Dialogue Manager
	if not DialogueManager.game_states.has(SocialDNAManager):
		DialogueManager.game_states.append(SocialDNAManager)
	
	# Apply default Phase 2 profile
	apply_social_dna_profile(current_profile_name)
	
	setup_profile_dropdown()
	setup_phase_toggle()
	update_all_displays()
	
	# Connect to Social DNA changes for live updates
	SocialDNAManager.social_dna_changed.connect(_on_social_dna_changed)
	
	# Connect to dialogue manager signals for debugging
	DialogueManager.dialogue_started.connect(_on_dialogue_started)
	DialogueManager.dialogue_ended.connect(_on_dialogue_ended)

func setup_profile_dropdown():
	# Clear existing items
	profile_dropdown.clear()
	
	# Add all test profiles to dropdown
	for profile_name in test_profiles.keys():
		profile_dropdown.add_item(profile_name)
	
	# Set default selection
	var default_index = test_profiles.keys().find(current_profile_name)
	profile_dropdown.selected = default_index if default_index >= 0 else 0
	
	# Connect selection signal
	profile_dropdown.item_selected.connect(_on_profile_selected)

func setup_phase_toggle():
	phase_toggle_button.text = "Switch to Phase 1 Mode"
	phase_toggle_button.pressed.connect(_on_phase_toggle_pressed)
	
	# Set all NPCs to Phase 2 mode initially
	set_npc_dialogue_mode(true)

func _on_profile_selected(index: int):
	var profile_name = profile_dropdown.get_item_text(index)
	apply_social_dna_profile(profile_name)

func _on_phase_toggle_pressed():
	is_phase2_mode = !is_phase2_mode
	
	if is_phase2_mode:
		phase_toggle_button.text = "Switch to Phase 1 Mode"
		print("\n=== Switched to Phase 2 Mode (Progressive Dialogue) ===")
	else:
		phase_toggle_button.text = "Switch to Phase 2 Mode"  
		print("\n=== Switched to Phase 1 Mode (Simple Dialogue) ===")
	
	set_npc_dialogue_mode(is_phase2_mode)
	update_all_displays()

func set_npc_dialogue_mode(use_progressive: bool):
	# Update all NPCs to use the selected dialogue mode
	for child in get_children():
		if child is SocialDialogueNPC:
			child.use_progressive_dialogue = use_progressive

func apply_social_dna_profile(profile_name: String):
	if not test_profiles.has(profile_name):
		print("Profile not found: %s" % profile_name)
		return
		
	print("\n=== Applying %s Profile ===" % profile_name)
	current_profile_name = profile_name
	
	# Apply new profile
	SocialDNAManager.player_social_dna = test_profiles[profile_name].duplicate()
	SocialDNAManager._calculate_total_social_power()
	
	# Update displays
	update_all_displays()
	
	# Manually update NPC compatibility for immediate feedback
	for child in get_children():
		if child is SocialDialogueNPC:
			child.update_compatibility()
	
	# Print new compatibility scores
	var auth_compat = SocialDNAManager.calculate_compatibility(SocialDNAManager.NPCArchetype.AUTHORITY)
	var intel_compat = SocialDNAManager.calculate_compatibility(SocialDNAManager.NPCArchetype.INTELLECTUAL)
	print("New compatibility scores:")
	print("  Authority: %.2f (%s)" % [auth_compat, SocialDNAManager.get_compatibility_description(auth_compat)])
	print("  Intellectual: %.2f (%s)" % [intel_compat, SocialDNAManager.get_compatibility_description(intel_compat)])

func update_all_displays():
	update_player_stats_display()
	update_progression_display()
	update_relationships_display()
	update_instructions_display()

func update_instructions_display():
	var instructions_text = ""
	
	if is_phase2_mode:
		instructions_text = """Phase 2 & 3 Mode Instructions:
• Left-click NPCs: Simple progressive dialogue (Social DNA tracked)
• Right-click NPCs: Topic-based conversations (3-5 turns, relationship building)
• Build relationships to unlock advanced topics
• Multiple conversation types available!"""
	else:
		instructions_text = """Phase 1 Mode Instructions:
• Left-click NPCs: Simple dialogue testing (compatibility-based responses)
• Use profile dropdown to test different Social DNA builds
• Right-click still available but uses static personalities"""
	
	if instructions_label:
		instructions_label.text = instructions_text

func update_relationships_display():
	if not relationships_label:
		return
		
	var relationships_text = "NPC Relationships:\n"
	
	# Get relationship info for each NPC
	for child in get_children():
		if child is SocialDialogueNPC:
			var npc = child as SocialDialogueNPC
			var relationship = npc.conversation_manager.relationship_tracker.get_relationship(npc.npc_name)
			var trust_visual = npc.conversation_manager.relationship_tracker.get_trust_visual(relationship.trust_level)
			var trust_name = npc.conversation_manager.relationship_tracker.get_trust_level_name(relationship.trust_level)
			
			relationships_text += "  %s: %s %s (%d interactions)\n" % [
				npc.npc_name,
				trust_visual,
				trust_name,
				relationship.interactions_count
			]
			
			# Show discussed topics
			if relationship.topics_discussed.size() > 0:
				relationships_text += "    Topics: %s\n" % ", ".join(relationship.topics_discussed)
			
			# Show failed topics that can be retried
			if relationship.failed_topics.size() > 0:
				relationships_text += "    Failed (retry available): %s\n" % ", ".join(relationship.failed_topics)
	
	relationships_label.text = relationships_text

func update_player_stats_display():
	var stats_text = "Current Profile: %s\n" % current_profile_name
	stats_text += "Mode: %s\n\n" % ("Phase 2 (Progressive)" if is_phase2_mode else "Phase 1 (Simple)")
	stats_text += "Player Social DNA:\n"
	
	# Show both raw values and percentages
	var percentages = SocialDNAManager.get_social_percentages()
	for social_type in SocialDNAManager.player_social_dna:
		var type_name = SocialDNAManager.get_social_type_name(social_type)
		var value = SocialDNAManager.player_social_dna[social_type]
		var percentage = percentages[social_type]
		stats_text += "  %s: %d (%.1f%%)\n" % [type_name, value, percentage]
	
	stats_text += "\nTotal Social Power: %d\n" % SocialDNAManager.total_social_power
	
	# Add compatibility info
	stats_text += "\nNPC Compatibility:\n"
	var authority_compat = SocialDNAManager.calculate_compatibility(SocialDNAManager.NPCArchetype.AUTHORITY)
	var intellectual_compat = SocialDNAManager.calculate_compatibility(SocialDNAManager.NPCArchetype.INTELLECTUAL)
	
	stats_text += "  Authority: %.2f (%s)\n" % [authority_compat, SocialDNAManager.get_compatibility_description(authority_compat)]
	stats_text += "  Intellectual: %.2f (%s)\n" % [intellectual_compat, SocialDNAManager.get_compatibility_description(intellectual_compat)]
	
	player_stats_label.text = stats_text

func update_progression_display():
	if is_phase2_mode:
		var dominant_traits = SocialDNAManager.get_dominant_traits(2)
		var progression_text = "Social DNA Progression:\n"
		progression_text += "Dominant Traits:\n"
		for i in range(dominant_traits.size()):
			var trait_data = dominant_traits[i]
			progression_text += "  %d. %s (%d)\n" % [i+1, trait_data["name"], trait_data["value"]]
		
		progression_text += "\nPhase 3 Features:\n• Multi-turn conversations\n• Relationship building\n• Information rewards\n• Topic unlocking"
		progression_label.text = progression_text
	else:
		progression_label.text = "Phase 1 Mode: Static Social DNA\nClick NPCs to test compatibility\nPhase 3 features disabled"

func _on_social_dna_changed(old_profile: Dictionary, new_profile: Dictionary):
	print("\n=== Social DNA Progression Detected ===")
	
	# Show what changed
	for social_type in new_profile:
		var old_val = old_profile[social_type]
		var new_val = new_profile[social_type]
		if new_val != old_val:
			var type_name = SocialDNAManager.get_social_type_name(social_type)
			print("  %s: %d → %d (+%d)" % [type_name, old_val, new_val, new_val - old_val])
	
	# Update displays with new values
	update_all_displays()  # This now includes relationship display
	
	print("New Social Power Total: %d" % SocialDNAManager.total_social_power)

func _on_dialogue_started(resource):
	print("Dialogue started with resource: ", resource)

func _on_dialogue_ended(resource):
	print("Dialogue ended with resource: ", resource)
