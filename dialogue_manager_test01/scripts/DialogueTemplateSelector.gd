class_name DialogueTemplateSelector
extends RefCounted

# Template data structure with clear compatibility indicators
var dialogue_templates = {
	SocialDNAManager.NPCArchetype.AUTHORITY: [
		"[INCOMPATIBLE] What do you want? Make it quick - I don't have time for people like you in my {LOCATION_TYPE}.",
		"[INCOMPATIBLE] You're interrupting important work. State your business and leave.",
		"[NEUTRAL] State your business in my {LOCATION_TYPE}. I have responsibilities to attend to.",
		"[COMPATIBLE] You look like someone who gets things done. What brings you to my {LOCATION_TYPE}?",
		"[COMPATIBLE] I respect efficiency. How can I assist someone of your caliber today?"
	],
	SocialDNAManager.NPCArchetype.INTELLECTUAL: [
		"[INCOMPATIBLE] I'm far too busy with important research to deal with interruptions in my {LOCATION_TYPE}.",
		"[INCOMPATIBLE] Unless you have something intellectually stimulating to discuss, please move along.",
		"[NEUTRAL] I'm curious about your perspective on the recent developments in {LOCATION_TYPE}.",
		"[COMPATIBLE] Fascinating! Someone with your social approach must have interesting insights to share.",
		"[COMPATIBLE] Excellent timing! I've been hoping to discuss current events with someone of your intellectual bearing."
	]
}

# Response templates for different social approaches
var response_templates = {
	SocialDNAManager.SocialType.AGGRESSIVE: [
		"Look, I need information and I need it now.",
		"Don't waste my time - just tell me what I want to know.",
		"I'm not here to play games. Answer my questions."
	],
	SocialDNAManager.SocialType.DIPLOMATIC: [
		"I was hoping we could discuss this matter professionally.",
		"Perhaps we could find a mutually beneficial arrangement?",
		"I believe we can work together on this issue."
	],
	SocialDNAManager.SocialType.CHARMING: [
		"I'm sure someone as experienced as you has interesting stories.",
		"You seem like exactly the right person to help me out.",
		"I'd love to hear your thoughts on the situation."
	],
	SocialDNAManager.SocialType.DIRECT: [
		"I need to know about the current situation here.",
		"Can you give me the facts about what's happening?",
		"What's the most important thing I should know?"
	],
	SocialDNAManager.SocialType.EMPATHETIC: [
		"I understand this must be a difficult situation for everyone.",
		"How are you and your people handling the recent changes?",
		"I'm here to help if there's anything you need."
	]
}

# NPC responses to player choices (based on compatibility)
var npc_reactions = {
	"positive": [
		"Exactly what I wanted to hear. You understand the situation.",
		"Now that's the kind of approach I can respect.",
		"I'm glad to be talking with someone who gets it.",
		"Finally, someone who speaks my language."
	],
	"neutral": [
		"I see. Well, I suppose that's one way to look at it.",
		"Hmm, an interesting perspective I suppose.",
		"Right. Well, moving on then."
	],
	"negative": [
		"That's... not quite what I was expecting to hear.",
		"I'm not sure that approach is going to work here.",
		"We clearly have different ways of handling things.",
		"I think this conversation is over."
	]
}

# Location type options for variable substitution
var location_types = ["sector", "station", "system"]

# Select a template based on archetype and compatibility
func select_template(archetype: SocialDNAManager.NPCArchetype, compatibility: float) -> String:
	var templates = dialogue_templates[archetype]
	var template_index: int
	
	# Use compatibility to influence template selection
	if compatibility >= 0.8:
		template_index = 4
	elif compatibility >= 0.3:
		template_index = randi_range(3, 4)
	elif compatibility >= -0.3:
		template_index = 2
	elif compatibility >= -0.8:
		template_index = randi_range(0, 1)
	else:
		template_index = 0
	
	var selected_template = templates[template_index]
	print("Selected template %d for %s (compatibility: %.2f): %s" % [template_index, SocialDNAManager.get_archetype_name(archetype), compatibility, selected_template])
	
	return selected_template

# Substitute variables in template
func substitute_variables(template: String) -> String:
	var result = template
	
	# Replace {LOCATION_TYPE} with random location
	if "{LOCATION_TYPE}" in result:
		var location = location_types[randi() % location_types.size()]
		result = result.replace("{LOCATION_TYPE}", location)
	
	return result

# Get a complete dialogue line for an NPC
func get_dialogue_line(archetype: SocialDNAManager.NPCArchetype, compatibility: float) -> String:
	var template = select_template(archetype, compatibility)
	return substitute_variables(template)

# Create dialogue resource with player response options for Phase 2 - SIMPLE WORKING VERSION
func create_progressive_dialogue_resource(npc_name: String, archetype: SocialDNAManager.NPCArchetype, compatibility: float) -> DialogueResource:
	var npc_line = get_dialogue_line(archetype, compatibility)
	
	# Generate player response options
	var aggressive_response = response_templates[SocialDNAManager.SocialType.AGGRESSIVE][randi() % response_templates[SocialDNAManager.SocialType.AGGRESSIVE].size()]
	var diplomatic_response = response_templates[SocialDNAManager.SocialType.DIPLOMATIC][randi() % response_templates[SocialDNAManager.SocialType.DIPLOMATIC].size()]
	var charming_response = response_templates[SocialDNAManager.SocialType.CHARMING][randi() % response_templates[SocialDNAManager.SocialType.CHARMING].size()]
	var direct_response = response_templates[SocialDNAManager.SocialType.DIRECT][randi() % response_templates[SocialDNAManager.SocialType.DIRECT].size()]
	var empathetic_response = response_templates[SocialDNAManager.SocialType.EMPATHETIC][randi() % response_templates[SocialDNAManager.SocialType.EMPATHETIC].size()]
	
	# Create dialogue text using ONLY variable assignment - NO function calls
	var dialogue_text = """
~ start
%s: %s
- [AGGRESSIVE] %s
	set SocialDNAManager.last_dialogue_choice = %d
	%s: %s
	=> END
- [DIPLOMATIC] %s
	set SocialDNAManager.last_dialogue_choice = %d
	%s: %s
	=> END
- [CHARMING] %s
	set SocialDNAManager.last_dialogue_choice = %d
	%s: %s
	=> END
- [DIRECT] %s
	set SocialDNAManager.last_dialogue_choice = %d
	%s: %s
	=> END
- [EMPATHETIC] %s
	set SocialDNAManager.last_dialogue_choice = %d
	%s: %s
	=> END
""" % [
		npc_name, npc_line,
		aggressive_response, SocialDNAManager.SocialType.AGGRESSIVE, npc_name, get_npc_reaction(archetype, SocialDNAManager.SocialType.AGGRESSIVE),
		diplomatic_response, SocialDNAManager.SocialType.DIPLOMATIC, npc_name, get_npc_reaction(archetype, SocialDNAManager.SocialType.DIPLOMATIC),
		charming_response, SocialDNAManager.SocialType.CHARMING, npc_name, get_npc_reaction(archetype, SocialDNAManager.SocialType.CHARMING),
		direct_response, SocialDNAManager.SocialType.DIRECT, npc_name, get_npc_reaction(archetype, SocialDNAManager.SocialType.DIRECT),
		empathetic_response, SocialDNAManager.SocialType.EMPATHETIC, npc_name, get_npc_reaction(archetype, SocialDNAManager.SocialType.EMPATHETIC)
	]
	
	print("Generated progressive dialogue for %s using ONLY variables - no function calls" % npc_name)
	# Use DialogueManager autoload directly (FIXED)
	return DialogueManager.create_resource_from_text(dialogue_text)

# Generate a simple dialogue resource for Phase 1 compatibility testing
func create_dialogue_resource(npc_name: String, archetype: SocialDNAManager.NPCArchetype, compatibility: float) -> DialogueResource:
	var dialogue_line = get_dialogue_line(archetype, compatibility)
	
	# Create simple dialogue text that Dialogue Manager can use
	var dialogue_text = """
~ start
%s: %s
=> END
""" % [npc_name, dialogue_line]
	
	# Use DialogueManager autoload directly (FIXED)
	return DialogueManager.create_resource_from_text(dialogue_text)

# Get NPC reaction based on archetype and player choice compatibility
func get_npc_reaction(archetype: SocialDNAManager.NPCArchetype, player_choice: SocialDNAManager.SocialType) -> String:
	var compatibility_matrix = SocialDNAManager.npc_compatibility[archetype]
	var preference = compatibility_matrix.get(player_choice, 0)
	
	var reaction_category: String
	if preference >= 1:
		reaction_category = "positive"
	elif preference >= 0:
		reaction_category = "neutral"
	else:
		reaction_category = "negative"
	
	var reactions = npc_reactions[reaction_category]
	return reactions[randi() % reactions.size()]
