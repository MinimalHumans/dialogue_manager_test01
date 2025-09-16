extends Node2D

@onready var player_stats_label = $CanvasLayer/VBoxContainer/PlayerStatsLabel

func _ready():
	update_player_stats_display()
	
	# Connect to dialogue manager signals for debugging
	DialogueManager.dialogue_started.connect(_on_dialogue_started)
	DialogueManager.dialogue_ended.connect(_on_dialogue_ended)

func update_player_stats_display():
	var stats_text = "Player Social DNA:\n"
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

# Helper function to quickly test different Social DNA profiles
func test_social_dna_profile(profile_name: String, new_profile: Dictionary):
	print("\n=== Testing %s Profile ===" % profile_name)
	
	# Backup original
	var original_profile = SocialDNAManager.player_social_dna.duplicate()
	
	# Apply new profile
	SocialDNAManager.player_social_dna = new_profile
	
	# Update display
	update_player_stats_display()
	
	# Recalculate NPC compatibility
	for child in get_children():
		if child is SocialDialogueNPC:
			child.update_compatibility()
	
	print("New compatibility scores:")
	var auth_compat = SocialDNAManager.calculate_compatibility(SocialDNAManager.NPCArchetype.AUTHORITY)
	var intel_compat = SocialDNAManager.calculate_compatibility(SocialDNAManager.NPCArchetype.INTELLECTUAL)
	print("  Authority: %.2f, Intellectual: %.2f" % [auth_compat, intel_compat])

# Call these from the console or add buttons to test different profiles
func test_authority_friendly():
	test_social_dna_profile("Authority Friendly", {
		SocialDNAManager.SocialType.AGGRESSIVE: 80,
		SocialDNAManager.SocialType.DIPLOMATIC: 10,
		SocialDNAManager.SocialType.CHARMING: 5,
		SocialDNAManager.SocialType.DIRECT: 95,
		SocialDNAManager.SocialType.EMPATHETIC: 10
	})

func test_intellectual_friendly():
	test_social_dna_profile("Intellectual Friendly", {
		SocialDNAManager.SocialType.AGGRESSIVE: 5,
		SocialDNAManager.SocialType.DIPLOMATIC: 95,
		SocialDNAManager.SocialType.CHARMING: 10,
		SocialDNAManager.SocialType.DIRECT: 70,
		SocialDNAManager.SocialType.EMPATHETIC: 85
	})

func test_low_compatibility():
	test_social_dna_profile("Low Compatibility", {
		SocialDNAManager.SocialType.AGGRESSIVE: 10,
		SocialDNAManager.SocialType.DIPLOMATIC: 10,
		SocialDNAManager.SocialType.CHARMING: 90,
		SocialDNAManager.SocialType.DIRECT: 5,
		SocialDNAManager.SocialType.EMPATHETIC: 15
	})
