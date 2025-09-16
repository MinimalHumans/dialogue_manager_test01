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

# Location type options for variable substitution
var location_types = ["sector", "station", "system"]

# Select a template based on archetype and compatibility
func select_template(archetype: SocialDNAManager.NPCArchetype, compatibility: float) -> String:
	var templates = dialogue_templates[archetype]
	var template_index: int
	
	# Use compatibility to influence template selection
	if compatibility >= 0.8:
		# Very high compatibility - use most welcoming templates
		template_index = 4
	elif compatibility >= 0.3:
		# Good compatibility - use friendly templates  
		template_index = randi_range(3, 4)
	elif compatibility >= -0.3:
		# Neutral compatibility - use neutral template
		template_index = 2
	elif compatibility >= -0.8:
		# Poor compatibility - use dismissive templates
		template_index = randi_range(0, 1)
	else:
		# Very poor compatibility - use most hostile template
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

# Generate a simple dialogue resource for Dialogue Manager
func create_dialogue_resource(npc_name: String, archetype: SocialDNAManager.NPCArchetype, compatibility: float) -> DialogueResource:
	var dialogue_line = get_dialogue_line(archetype, compatibility)
	
	# Create simple dialogue text that Dialogue Manager can use
	var dialogue_text = """
~ start
%s: %s
=> END
""" % [npc_name, dialogue_line]
	
	# Use Dialogue Manager's built-in method to create resource from text
	return DialogueManager.create_resource_from_text(dialogue_text)
