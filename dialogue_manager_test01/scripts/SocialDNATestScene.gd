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
