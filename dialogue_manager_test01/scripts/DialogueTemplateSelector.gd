class_name DialogueTemplateSelector
extends RefCounted

# Template data structure
var dialogue_templates = {
	SocialDNAManager.NPCArchetype.AUTHORITY: [
		"State your business in my {LOCATION_TYPE}.",
		"I don't have time for pleasantries. What do you need?",
		"You'd better have a good reason for interrupting me.",
		"Make it quick - I have responsibilities to attend to.",
		"I hope you're not here to waste my time."
	],
	SocialDNAManager.NPCArchetype.INTELLECTUAL: [
		"Interesting ship configuration you have there.",
		"I'm curious about your perspective on the recent developments in {LOCATION_TYPE}.",
		"Have you given any thought to the implications of current events?",
		"I find it fascinating how different people approach the same problems.",
		"Your arrival timing is quite fortuitous for my research."
	]
}

# Location type options for variable substitution
var location_types = ["sector", "station", "system"]

# Select a template based on archetype and compatibility
func select_template(archetype: SocialDNAManager.NPCArchetype, compatibility: float) -> String:
	var templates = dialogue_templates[archetype]
	var template_index: int
	
	# Use compatibility to influence template selection
	if compatibility >= 0.5:
		# High compatibility - use more welcoming templates (later in array)
		template_index = randi_range(2, templates.size() - 1)
	elif compatibility >= -0.5:
		# Neutral compatibility - use middle templates
		template_index = randi_range(1, 3)
	else:
		# Low compatibility - use more hostile templates (earlier in array)
		template_index = randi_range(0, 2)
	
	return templates[template_index]

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
