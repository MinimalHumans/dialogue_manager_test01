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
var topic_ui_active: bool = false  # Track if topic UI is active

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
	
	# Connect to DialogueManager signals (FIXED - use autoload directly)
	_setup_dialogue_manager_connection()
	
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

func _setup_dialogue_manager_connection():
	# Connect to the DialogueManager autoload signals directly (FIXED)
	if DialogueManager.has_signal("dialogue_ended"):
		if not DialogueManager.dialogue_ended.is_connected(_on_dialogue_ended):
			DialogueManager.dialogue_ended.connect(_on_dialogue_ended)
			print("Connected to DialogueManager.dialogue_ended signal")
	else:
		print("DialogueManager autoload doesn't have dialogue_ended signal")

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
	# Don't process input if topic UI is active
	if topic_ui_active:
		return
		
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
	
	# Show dialogue using the DialogueManager singleton correctly (FIXED)
	if dialogue_manager_singleton:
		dialogue_manager_singleton.show_dialogue_balloon(current_dialogue_resource)
	else:
		print("ERROR: DialogueManager singleton not available")
	
	# Update info display
	update_info_label()

func start_topic_conversation():
	print("Starting topic-based conversation with %s" % npc_name)
	
	# Reset conversation state if it's stuck
	if conversation_manager.conversation_active:
		print("WARNING: Conversation was still marked as active - resetting state")
		conversation_manager.conversation_active = false
		conversation_manager.current_turn = 0
		conversation_manager.advance_turn = false
		conversation_manager.player_choice = -1
	
	conversation_manager.start_conversation(npc_name, archetype)

func _on_topic_selection_required(available_topics: Array):
	print("Topic selection required for %s:" % npc_name)
	show_topic_selection_ui(available_topics)

func show_topic_selection_ui(available_topics: Array):
	# Remove existing topic UI if present
	if topic_selection_ui:
		topic_selection_ui.queue_free()
	
	# Set flag to disable Area2D input while UI is active
	topic_ui_active = true
	
	# Create a CanvasLayer to ensure UI is on top
	var canvas_layer = CanvasLayer.new()
	canvas_layer.layer = 100  # High layer to ensure it's on top
	
	# Create topic selection UI
	topic_selection_ui = Control.new()
	topic_selection_ui.name = "TopicSelectionUI"
	topic_selection_ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	topic_selection_ui.mouse_filter = Control.MOUSE_FILTER_STOP  # Ensure it captures mouse events
	
	# Create semi-transparent background that covers the whole screen
	var background = ColorRect.new()
	background.color = Color(0, 0, 0, 0.5)  # Semi-transparent black
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.mouse_filter = Control.MOUSE_FILTER_STOP  # Block clicks to elements below
	topic_selection_ui.add_child(background)
	
	# Create main panel
	var panel = Panel.new()
	panel.size = Vector2(450, 350)  # Made it a bit larger
	# Position panel at the center of the screen
	panel.position = Vector2(
		(get_viewport().size.x - panel.size.x) * 0.5,
		(get_viewport().size.y - panel.size.y) * 0.5
	)
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	topic_selection_ui.add_child(panel)
	
	# Create VBox for layout with margins
	var margin_container = MarginContainer.new()
	margin_container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin_container.add_theme_constant_override("margin_left", 15)
	margin_container.add_theme_constant_override("margin_right", 15)
	margin_container.add_theme_constant_override("margin_top", 15)
	margin_container.add_theme_constant_override("margin_bottom", 15)
	panel.add_child(margin_container)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	margin_container.add_child(vbox)
	
	# Title label
	var title_label = Label.new()
	title_label.text = "Conversation Topics - %s" % npc_name
	title_label.add_theme_font_size_override("font_size", 16)
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title_label)
	
	# Add separator
	var separator = HSeparator.new()
	vbox.add_child(separator)
	
	# Add topic buttons
	var button_count = 0
	for topic in available_topics:
		var button = Button.new()
		var status_indicator = "●" if topic.is_new else ("!" if topic.has_failed else "○")
		var status_text = " [New]" if topic.is_new else (" [Failed - Retry]" if topic.has_failed else " [Discussed]")
		
		button.text = "%s %s%s" % [status_indicator, topic.name, status_text]
		button.custom_minimum_size.y = 40  # Taller buttons
		button.mouse_filter = Control.MOUSE_FILTER_STOP
		
		# Store topic_id in button metadata for reliable access
		button.set_meta("topic_id", topic.id)
		button.pressed.connect(_on_topic_button_pressed.bind(button))
		
		vbox.add_child(button)
		button_count += 1
		
		print("Added topic button %d: %s (topic_id: %s)" % [button_count, topic.name, topic.id])
	
	# Add separator before cancel
	var separator2 = HSeparator.new()
	vbox.add_child(separator2)
	
	# Cancel button
	var cancel_button = Button.new()
	cancel_button.text = "Cancel"
	cancel_button.custom_minimum_size.y = 40
	cancel_button.mouse_filter = Control.MOUSE_FILTER_STOP
	cancel_button.pressed.connect(_on_topic_selection_cancelled)
	vbox.add_child(cancel_button)
	
	# Add the UI to the canvas layer, then add canvas layer to scene
	canvas_layer.add_child(topic_selection_ui)
	get_tree().current_scene.add_child(canvas_layer)
	
	# Store reference to canvas layer so we can clean it up
	topic_selection_ui.set_meta("canvas_layer", canvas_layer)
	
	print("Showing topic selection UI with %d topics on CanvasLayer %d" % [available_topics.size(), canvas_layer.layer])
	print("UI created with mouse_filter STOP on all interactive elements")

func _on_topic_button_pressed(button: Button):
	var topic_id = button.get_meta("topic_id")
	print("Topic button pressed: %s (topic_id: %s)" % [button.text, topic_id])
	
	# Remove topic selection UI and re-enable Area2D input
	_close_topic_ui()
	
	# Set this conversation manager as the active one in SocialDNAManager
	# This allows the dialogue system to call methods on it through SocialDNAManager
	SocialDNAManager.set_active_conversation_manager(conversation_manager)
	
	# Also add conversation manager to DialogueManager game_states for direct access (FIXED)
	# Clear any previous conversation managers first
	if dialogue_manager_singleton and dialogue_manager_singleton.has_method("get"):
		var game_states_array = dialogue_manager_singleton.get("game_states")
		if game_states_array:
			# Remove old conversation managers
			for i in range(game_states_array.size() - 1, -1, -1):
				var state = game_states_array[i]
				if state is ConversationManager:
					game_states_array.remove_at(i)
					print("Removed old conversation manager from game_states")
			
			# Add the current conversation manager
			game_states_array.append(conversation_manager)
			print("Added current conversation_manager to DialogueManager game_states")
			print("Set active conversation_manager in SocialDNAManager")
	
	# Start the conversation with selected topic
	var dialogue_resource = conversation_manager.select_topic(topic_id)
	if dialogue_resource:
		current_dialogue_resource = dialogue_resource
		if dialogue_manager_singleton:
			dialogue_manager_singleton.show_dialogue_balloon(current_dialogue_resource)
		else:
			print("ERROR: DialogueManager singleton not available")

func _on_topic_selection_cancelled():
	print("Topic selection cancelled - Cancel button was clicked")
	_close_topic_ui()

func _close_topic_ui():
	# Remove topic selection UI and its canvas layer, then re-enable Area2D input
	if topic_selection_ui:
		var canvas_layer = topic_selection_ui.get_meta("canvas_layer", null)
		if canvas_layer:
			canvas_layer.queue_free()  # This will free the canvas layer and all its children
		else:
			topic_selection_ui.queue_free()  # Fallback if no canvas layer
		topic_selection_ui = null
	
	topic_ui_active = false
	print("Topic UI closed and Area2D input re-enabled")

func _on_conversation_started(topic: String):
	print("Phase 3 conversation started: %s with %s" % [topic, npc_name])

func _on_conversation_ended(outcome: String, rewards: Array):
	print("Phase 3 conversation ended: %s (Rewards: %d)" % [outcome, rewards.size()])
	
	# Clear the active conversation manager when conversation ends
	SocialDNAManager.clear_active_conversation_manager()
	print("Cleared active conversation manager from SocialDNAManager")
	
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
	print("Dialogue ended for %s" % npc_name)
	
	# Process any choice that was made during dialogue
	if use_progressive_dialogue:
		# Check if we're in a Phase 3 conversation
		if conversation_manager.conversation_active:
			print("Phase 3 conversation active, processing conversation state...")
			# Handle Phase 3 conversation advancement
			var next_dialogue = conversation_manager.process_conversation_state()
			if next_dialogue:
				print("Generated next dialogue, showing after brief delay...")
				current_dialogue_resource = next_dialogue
				# Small delay before showing next turn
				await get_tree().create_timer(0.5).timeout
				if dialogue_manager_singleton:
					dialogue_manager_singleton.show_dialogue_balloon(current_dialogue_resource)
				else:
					print("ERROR: DialogueManager singleton not available")
			else:
				print("No more dialogue - conversation completed or error occurred")
				# Update relationship display after conversation ends
				update_info_label()
		else:
			# Handle Phase 2 simple conversation
			print("Phase 2 simple dialogue ended, processing last choice...")
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
