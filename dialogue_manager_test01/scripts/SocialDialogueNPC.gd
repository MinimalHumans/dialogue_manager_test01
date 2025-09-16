extends Area2D
class_name SocialDialogueNPC

@export var npc_name: String = "Unknown NPC"
@export var archetype: SocialDNAManager.NPCArchetype = SocialDNAManager.NPCArchetype.AUTHORITY
@export var use_progressive_dialogue: bool = true  # Phase 2 toggle

var template_selector: DialogueTemplateSelector
var compatibility: float
var current_dialogue_resource: DialogueResource
var interactions_count: int = 0

# UI elements for testing
var info_label: Label

func _ready():
	template_selector = DialogueTemplateSelector.new()
	
	# Fix ColorRect blocking input (if it exists)
	if has_node("ColorRect"):
		$ColorRect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	# Connect input event signal for Area2D
	input_event.connect(_on_input_event)
	
	# Connect to Social DNA changes for real-time compatibility updates
	SocialDNAManager.social_dna_changed.connect(_on_social_dna_changed)
	
	# Connect to dialogue events to track player choices
	if not DialogueManager.dialogue_ended.is_connected(_on_dialogue_ended):
		DialogueManager.dialogue_ended.connect(_on_dialogue_ended)
	
	# Calculate initial compatibility
	compatibility = SocialDNAManager.calculate_compatibility(archetype)
	
	# Create info label for testing
	create_info_display()
	
	print("%s (%s) - Initial Compatibility: %.2f (%s)" % [
		npc_name,
		SocialDNAManager.get_archetype_name(archetype),
		compatibility,
		SocialDNAManager.get_compatibility_description(compatibility)
	])

func _on_dialogue_ended(resource):
	# Process any choice that was made during dialogue
	if use_progressive_dialogue:
		SocialDNAManager.process_last_choice()
		print("Dialogue ended, processed last choice")

func create_info_display():
	# Create a label to show NPC info
	info_label = Label.new()
	update_info_label()
	info_label.add_theme_font_size_override("font_size", 12)
	info_label.position = Vector2(0, -100)
	info_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(info_label)

func update_info_label():
	if info_label:
		info_label.text = "%s\n%s\nCompatibility: %.2f\nInteractions: %d" % [
			npc_name,
			SocialDNAManager.get_archetype_name(archetype),
			compatibility,
			interactions_count
		]

func _on_input_event(viewport, event, shape_idx):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		print("Clicked on %s!" % npc_name)
		start_dialogue()

func start_dialogue():
	interactions_count += 1
	print("Starting dialogue #%d with %s (compatibility: %.2f)..." % [interactions_count, npc_name, compatibility])
	
	# Generate dialogue resource based on current compatibility
	if use_progressive_dialogue:
		current_dialogue_resource = template_selector.create_progressive_dialogue_resource(npc_name, archetype, compatibility)
	else:
		current_dialogue_resource = template_selector.create_dialogue_resource(npc_name, archetype, compatibility)
	
	# Show dialogue using Dialogue Manager
	DialogueManager.show_dialogue_balloon(current_dialogue_resource)
	
	# Update info display
	update_info_label()

func _on_social_dna_changed(old_profile: Dictionary, new_profile: Dictionary):
	var old_compatibility = compatibility
	compatibility = SocialDNAManager.calculate_compatibility(archetype)
	
	print("%s: Compatibility changed %.2f → %.2f" % [npc_name, old_compatibility, compatibility])
	
	# Update info display with new compatibility
	update_info_label()
	
	# Visual feedback for compatibility changes
	if compatibility > old_compatibility + 0.1:
		# Compatibility increased - flash green
		flash_color(Color.GREEN)
	elif compatibility < old_compatibility - 0.1:
		# Compatibility decreased - flash red  
		flash_color(Color.RED)

func flash_color(color: Color):
	# Simple visual feedback when compatibility changes
	var original_modulate = modulate
	modulate = color
	var tween = create_tween()
	tween.tween_property(self, "modulate", original_modulate, 0.5)

# Method for manual compatibility updates (Phase 1 compatibility)
func update_compatibility():
	var old_compatibility = compatibility
	compatibility = SocialDNAManager.calculate_compatibility(archetype)
	update_info_label()
	
	if abs(compatibility - old_compatibility) > 0.01:
		print("%s: Manual compatibility update %.2f → %.2f" % [npc_name, old_compatibility, compatibility])
