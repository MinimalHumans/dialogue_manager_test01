extends Area2D
class_name SocialDialogueNPC

@export var npc_name: String = "Unknown NPC"
@export var archetype: SocialDNAManager.NPCArchetype = SocialDNAManager.NPCArchetype.AUTHORITY
@export var use_progressive_dialogue: bool = true  # Phase 2 toggle

var template_selector: DialogueTemplateSelector
var conversation_manager: ConversationManager
var compatibility: float
var current_dialogue_resource: DialogueResource
var interactions_count: int = 0

# UI elements for testing
var info_label: Label
var topic_selection_ui: Control

func _ready():
	template_selector = DialogueTemplateSelector.new()
	conversation_manager = ConversationManager.new()
	
	# Connect to conversation manager signals
	conversation_manager.topic_selection_required.connect(_on_topic_selection_required)
	conversation_manager.conversation_started.connect(_on_conversation_started)
	conversation_manager.conversation_ended.connect(_on_conversation_ended)
	conversation_manager.compatibility_check_failed.connect(_on_compatibility_failed)
	
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

func create_info_display():
	# Create a label to show NPC info with relationship status
	info_label = Label.new()
	update_info_label()
	info_label.add_theme_font_size_override("font_size", 10)
	info_label.position = Vector2(0, -120)
	info_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(info_label)

func update_info_label():
	if info_label:
		var relationship = conversation_manager.relationship_tracker.get_relationship(npc_name)
		var trust_visual = conversation_manager.relationship_tracker.get_trust_visual(relationship.trust_level)
		var trust_name = conversation_manager.relationship_tracker.get_trust_level_name(relationship.trust_level)
		var trust_color = conversation_manager.relationship_tracker.get_trust_color(relationship.trust_level)
		
		info_label.text = "%s\n%s\nCompatibility: %.2f\nRelationship: %s %s\nInteractions: %d\n[Click: Talk] [Right-click: Topics]" % [
			npc_name,
			SocialDNAManager.get_archetype_name(archetype),
			compatibility,
			trust_visual,
			trust_name,
			interactions_count
		]
		
		# Color the label based on trust level
		info_label.modulate = trust_color

func _on_input_event(viewport, event, shape_idx):
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			# Left click: Start simple conversation or continue existing conversation system
			print("Clicked on %s!" % npc_name)
			start_dialogue()
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			# Right click: Show topic selection for Phase 3 conversations
			print("Right-clicked on %s - showing topic selection" % npc_name)
			start_topic_conversation()

func start_dialogue():
	interactions_count += 1
	print("Starting simple dialogue #%d with %s (compatibility: %.2f)..." % [interactions_count, npc_name, compatibility])
	
	# Generate simple dialogue resource based on current compatibility (Phase 1/2 style)
	if use_progressive_dialogue:
		current_dialogue_resource = template_selector.create_progressive_dialogue_resource(npc_name, archetype, compatibility)
	else:
		current_dialogue_resource = template_selector.create_dialogue_resource(npc_name, archetype, compatibility)
	
	# Show dialogue using Dialogue Manager
	DialogueManager.show_dialogue_balloon(current_dialogue_resource)
	
	# Update info display
	update_info_label()

func start_topic_conversation():
	print("Starting topic-based conversation with %s" % npc_name)
	conversation_manager.start_conversation(npc_name, archetype)

func _on_topic_selection_required(available_topics: Array):
	print("Topic selection required for %s:" % npc_name)
	show_topic_selection_ui(available_topics)

func show_topic_selection_ui(available_topics: Array):
	# Remove existing topic UI if present
	if topic_selection_ui:
		topic_selection_ui.queue_free()
	
	# Create topic selection UI
	topic_selection_ui = Control.new()
	topic_selection_ui.name = "TopicSelectionUI"
	
	# Create background panel
	var panel = Panel.new()
	panel.size = Vector2(400, 300)
	panel.position = Vector2(-200, -150)  # Center on NPC
	topic_selection_ui.add_child(panel)
	
	# Create VBox for layout
	var vbox = VBoxContainer.new()
	vbox.position = Vector2(10, 10)
	vbox.size = Vector2(380, 280)
	panel.add_child(vbox)
	
	# Title label
	var title_label = Label.new()
	title_label.text = "Conversation Topics - %s" % npc_name
	title_label.add_theme_font_size_override("font_size", 14)
	vbox.add_child(title_label)
	
	# Add topic buttons
	for topic in available_topics:
		var button = Button.new()
		var status_indicator = "●" if topic.is_new else ("!" if topic.has_failed else "○")
		var status_text = " [New]" if topic.is_new else (" [Failed - Retry]" if topic.has_failed else " [Discussed]")
		
		button.text = "%s %s%s" % [status_indicator, topic.name, status_text]
		button.pressed.connect(_on_topic_selected.bind(topic.id))
		vbox.add_child(button)
	
	# Cancel button
	var cancel_button = Button.new()
	cancel_button.text = "Cancel"
	cancel_button.pressed.connect(_on_topic_selection_cancelled)
	vbox.add_child(cancel_button)
	
	# Add to scene
	add_child(topic_selection_ui)
	
	print("Showing topic selection UI with %d topics" % available_topics.size())

func _on_topic_selected(topic_id: String):
	print("Topic selected: %s" % topic_id)
	
	# Remove topic selection UI
	if topic_selection_ui:
		topic_selection_ui.queue_free()
		topic_selection_ui = null
	
	# Start the conversation with selected topic
	var dialogue_resource = conversation_manager.select_topic(topic_id)
	if dialogue_resource:
		current_dialogue_resource = dialogue_resource
		DialogueManager.show_dialogue_balloon(current_dialogue_resource)

func _on_topic_selection_cancelled():
	print("Topic selection cancelled")
	
	# Remove topic selection UI
	if topic_selection_ui:
		topic_selection_ui.queue_free()
		topic_selection_ui = null

func _on_conversation_started(topic: String):
	print("Phase 3 conversation started: %s with %s" % [topic, npc_name])

func _on_conversation_ended(outcome: String, rewards: Array):
	print("Phase 3 conversation ended: %s (Rewards: %d)" % [outcome, rewards.size()])
	
	# Update relationship display
	update_info_label()
	
	# Show rewards to player
	if rewards.size() > 0:
		print("Rewards gained:")
		for reward in rewards:
			print("  - %s" % reward)

func _on_compatibility_failed(failed_npc_name: String):
	if failed_npc_name == npc_name:
		print("Compatibility check failed with %s" % npc_name)
		# Flash red to indicate failure
		flash_color(Color.RED)

func _on_dialogue_ended(resource):
	# Process any choice that was made during dialogue
	if use_progressive_dialogue:
		# Check if we're in a Phase 3 conversation
		if conversation_manager.conversation_active:
			# Handle Phase 3 conversation advancement
			var next_dialogue = conversation_manager.process_conversation_state()
			if next_dialogue:
				current_dialogue_resource = next_dialogue
				# Small delay before showing next turn
				await get_tree().create_timer(0.5).timeout
				DialogueManager.show_dialogue_balloon(current_dialogue_resource)
		else:
			# Handle Phase 2 simple conversation
			SocialDNAManager.process_last_choice()
			print("Simple dialogue ended, processed last choice")

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
