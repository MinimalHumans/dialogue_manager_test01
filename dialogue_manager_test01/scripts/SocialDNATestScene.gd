extends Node2D

@onready var player_stats_label = $CanvasLayer/VBoxContainer/PlayerStatsLabel
@onready var profile_dropdown = $CanvasLayer/VBoxContainer/ProfileDropdown

# Define test profiles
var test_profiles = {
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
	},
	"Extreme Aggressive": {
		SocialDNAManager.SocialType.AGGRESSIVE: 100,
		SocialDNAManager.SocialType.DIPLOMATIC: 0,
		SocialDNAManager.SocialType.CHARMING: 0,
		SocialDNAManager.SocialType.DIRECT: 100,
		SocialDNAManager.SocialType.EMPATHETIC: 0
	},
	"Extreme Diplomatic": {
		SocialDNAManager.SocialType.AGGRESSIVE: 0,
		SocialDNAManager.SocialType.DIPLOMATIC: 100,
		SocialDNAManager.SocialType.CHARMING: 20,
		SocialDNAManager.SocialType.DIRECT: 50,
		SocialDNAManager.SocialType.EMPATHETIC: 100
	}
}

var current_profile_name = "Default (Phase 1)"

func _ready():
	setup_profile_dropdown()
	update_player_stats_display()
	
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
	profile_dropdown.selected = 0
	
	# Connect selection signal
	profile_dropdown.item_selected.connect(_on_profile_selected)

func _on_profile_selected(index: int):
	var profile_name = profile_dropdown.get_item_text(index)
	apply_social_dna_profile(profile_name)

func apply_social_dna_profile(profile_name: String):
	if not test_profiles.has(profile_name):
		print("Profile not found: %s" % profile_name)
		return
		
	print("\n=== Applying %s Profile ===" % profile_name)
	current_profile_name = profile_name
	
	# Apply new profile
	SocialDNAManager.player_social_dna = test_profiles[profile_name].duplicate()
	
	# Update display
	update_player_stats_display()
	
	# Recalculate NPC compatibility
	for child in get_children():
		if child is SocialDialogueNPC:
			child.update_compatibility()
	
	# Print new compatibility scores
	var auth_compat = SocialDNAManager.calculate_compatibility(SocialDNAManager.NPCArchetype.AUTHORITY)
	var intel_compat = SocialDNAManager.calculate_compatibility(SocialDNAManager.NPCArchetype.INTELLECTUAL)
	print("New compatibility scores:")
	print("  Authority: %.2f (%s)" % [auth_compat, SocialDNAManager.get_compatibility_description(auth_compat)])
	print("  Intellectual: %.2f (%s)" % [intel_compat, SocialDNAManager.get_compatibility_description(intel_compat)])

func update_player_stats_display():
	var stats_text = "Current Profile: %s\n\n" % current_profile_name
	stats_text += "Player Social DNA:\n"
	for social_type in SocialDNAManager.player_social_dna:
		var type_name = SocialDNAManager.get_social_type_name(social_type)
		var value = SocialDNAManager.player_social_dna[social_type]
		stats_text += "  %s: %d\n" % [type_name, value]
	
	# Add compatibility info
	stats_text += "\nNPC Compatibility:\n"
	var authority_compat = SocialDNAManager.calculate_compatibility(SocialDNAManager.NPCArchetype.AUTHORITY)
	var intellectual_compat = SocialDNAManager.calculate_compatibility(SocialDNAManager.NPCArchetype.INTELLECTUAL)
	
	stats_text += "  Authority: %.2f (%s)\n" % [authority_compat, SocialDNAManager.get_compatibility_description(authority_compat)]
	stats_text += "  Intellectual: %.2f (%s)\n" % [intellectual_compat, SocialDNAManager.get_compatibility_description(intellectual_compat)]
	
	player_stats_label.text = stats_text

func _on_dialogue_started(resource):
	print("Dialogue started with resource: ", resource)

func _on_dialogue_ended(resource):
	print("Dialogue ended with resource: ", resource)
