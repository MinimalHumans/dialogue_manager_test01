extends Area2D
class_name SocialDialogueNPC

@export var npc_name: String = "Unknown NPC"
@export var archetype: SocialDNAManager.NPCArchetype = SocialDNAManager.NPCArchetype.AUTHORITY

var template_selector: DialogueTemplateSelector
var compatibility: float
var current_dialogue_resource: DialogueResource

# UI elements for testing
var info_label: Label

func _ready():
	template_selector = DialogueTemplateSelector.new()
	
	# Fix ColorRect blocking input (if it exists)
	if has_node("ColorRect"):
		$ColorRect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	# Connect input event signal for Area2D
	input_event.connect(_on_input_event)
	
	# Calculate compatibility with player
	compatibility = SocialDNAManager.calculate_compatibility(archetype)
	
	# Create info label for testing
	create_info_display()
	
	print("%s (%s) - Compatibility: %.2f (%s)" % [
		npc_name,
		SocialDNAManager.get_archetype_name(archetype),
		compatibility,
		SocialDNAManager.get_compatibility_description(compatibility)
	])

func create_info_display():
	# Create a label to show NPC info
	info_label = Label.new()
	info_label.text = "%s\n%s\nCompatibility: %.2f" % [
		npc_name,
		SocialDNAManager.get_archetype_name(archetype),
		compatibility
	]
	info_label.add_theme_font_size_override("font_size", 12)
	info_label.position = Vector2(0, -80)
	info_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(info_label)

func _on_input_event(viewport, event, shape_idx):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		print("Clicked on %s!" % npc_name)
		start_dialogue()

func start_dialogue():
	print("Starting dialogue with %s..." % npc_name)
	
	# Generate dialogue resource based on current compatibility
	current_dialogue_resource = template_selector.create_dialogue_resource(npc_name, archetype, compatibility)
	
	# Show dialogue using Dialogue Manager
	DialogueManager.show_dialogue_balloon(current_dialogue_resource)

# Method to recalculate compatibility if player Social DNA changes
func update_compatibility():
	compatibility = SocialDNAManager.calculate_compatibility(archetype)
	if info_label:
		info_label.text = "%s\n%s\nCompatibility: %.2f" % [
			npc_name,
			SocialDNAManager.get_archetype_name(archetype),
			compatibility
		]
