class_name ConversationManager
extends RefCounted

# Signals for conversation events
signal conversation_started(topic: String)
signal conversation_ended(outcome: String, rewards: Array)
signal topic_selection_required(available_topics: Array)
signal compatibility_check_failed(npc_name: String)

# Current conversation state
var current_npc_name: String = ""
var current_npc_archetype: SocialDNAManager.NPCArchetype
var current_topic: String = ""
var current_turn: int = 0
var conversation_active: bool = false
var social_choices_made: Array[SocialDNAManager.SocialType] = []
var conversation_context: Dictionary = {}  # Stores info revealed during conversation

# Systems
var relationship_tracker: RelationshipTracker
var conversation_topics: ConversationTopics

# Variables that the dialogue system will set
var advance_turn: bool = false
var player_choice: int = -1

func _init():
	relationship_tracker = RelationshipTracker.new()
	conversation_topics = ConversationTopics.new()

# Start a conversation with an NPC
func start_conversation(npc_name: String, archetype: SocialDNAManager.NPCArchetype):
	if conversation_active:
		print("Conversation already active!")
		return
	
	current_npc_name = npc_name
	current_npc_archetype = archetype
	
	# Get available topics for this NPC
	var available_topics = relationship_tracker.get_available_topics(npc_name, archetype)
	
	if available_topics.size() == 0:
		print("No topics available for %s" % npc_name)
		return
	
	# Emit signal for UI to show topic selection
	topic_selection_required.emit(available_topics)
	print("Conversation initiated with %s. Choose a topic:" % npc_name)

# Player selects a topic to discuss
func select_topic(topic_id: String):
	if not conversation_active and current_npc_name != "":
		current_topic = topic_id
		conversation_active = true
		current_turn = 1
		social_choices_made.clear()
		conversation_context.clear()
		
		# Reset dialogue variables
		advance_turn = false
		player_choice = -1
		
		conversation_started.emit(topic_id)
		
		# Generate first turn
		var dialogue_resource = _generate_turn_dialogue()
		return dialogue_resource
	
	return null

# Generate dialogue for current turn
func _generate_turn_dialogue() -> DialogueResource:
	print("=== GENERATING TURN %d DIALOGUE ===" % current_turn)
	
	var topic_data = conversation_topics.get_topic_data(current_topic, current_npc_archetype)
	var relationship = relationship_tracker.get_relationship(current_npc_name)
	
	if not topic_data:
		print("ERROR: Topic data not found for: %s" % current_topic)
		return null
	
	# Get current turn data
	var turn_data = topic_data.turns[current_turn - 1] if current_turn <= topic_data.turns.size() else null
	if not turn_data:
		print("ERROR: Turn %d not found for topic %s" % [current_turn, current_topic])
		return null
	
	var dialogue_text = ""
	
	print("Generating turn %d for topic %s with NPC %s" % [current_turn, current_topic, current_npc_name])
	
	match current_turn:
		1:
			# Turn 1: NPC opening based on compatibility/relationship
			dialogue_text = _generate_turn_1_dialogue(turn_data, relationship)
		2:
			# Turn 2: Player response options (Social DNA tracked)
			dialogue_text = _generate_turn_2_dialogue(turn_data)
		3:
			# Turn 3: NPC reaction + compatibility check
			dialogue_text = _generate_turn_3_dialogue(turn_data, relationship)
		4:
			# Turn 4: Player's critical choice (Social DNA tracked)
			dialogue_text = _generate_turn_4_dialogue(turn_data)
		5:
			# Turn 5: Conclusion with outcome
			dialogue_text = _generate_turn_5_dialogue(turn_data, relationship)
	
	print("Generated turn %d dialogue for %s - %s" % [current_turn, current_npc_name, current_topic])
	print("Dialogue length: %d characters" % dialogue_text.length())
	print("========================================")
	return DialogueManager.create_resource_from_text(dialogue_text)

# Generate Turn 1: NPC Opening
func _generate_turn_1_dialogue(turn_data: Dictionary, relationship: RelationshipTracker.NPCRelationship) -> String:
	var compatibility = SocialDNAManager.calculate_compatibility(current_npc_archetype)
	var trust_level = relationship.trust_level
	
	# Select opening based on relationship and compatibility
	var opening_key = "default"
	if trust_level >= RelationshipTracker.TrustLevel.TRUSTED and compatibility >= 0.8:
		opening_key = "trusted_high_compat"
	elif trust_level >= RelationshipTracker.TrustLevel.PROFESSIONAL and compatibility >= 0.5:
		opening_key = "professional_good_compat"
	elif compatibility < -0.5:
		opening_key = "low_compat"
	
	var opening_text = turn_data.npc_openings.get(opening_key, turn_data.npc_openings["default"])
	
	print("Turn 1: Using opening key '%s' with text: %s" % [opening_key, opening_text])
	
	return """
~ start
%s: %s
- Continue
	do conversation_manager.set_advance_turn()
	=> END
""" % [current_npc_name, opening_text]

# Generate Turn 2: Player Response Options
func _generate_turn_2_dialogue(turn_data: Dictionary) -> String:
	var dialogue_text = """
~ start
%s: Choose your approach:
""" % current_npc_name
	
	# Add player response options
	print("Generating %d response options for turn 2:" % turn_data.player_responses.size())
	for response in turn_data.player_responses:
		var social_type = response.social_type as int
		print("  - %s: %s (social_type: %d)" % [response.label, response.text, social_type])
		dialogue_text += """
- [%s] %s
	do conversation_manager.set_player_choice_and_advance(%d)
	=> END
""" % [response.label, response.text, social_type]
	
	print("Turn 2 dialogue generated with method calls")
	return dialogue_text

# Generate Turn 3: NPC Reaction + Compatibility Check
func _generate_turn_3_dialogue(turn_data: Dictionary, relationship: RelationshipTracker.NPCRelationship) -> String:
	print("=== GENERATING TURN 3 ===")
	print("social_choices_made.size(): %d" % social_choices_made.size())
	print("social_choices_made: %s" % social_choices_made)
	
	if social_choices_made.size() == 0:
		print("ERROR: No social choice recorded for turn 3!")
		return _generate_error_dialogue()
	
	var last_choice = social_choices_made[-1]
	var compatibility = SocialDNAManager.calculate_compatibility(current_npc_archetype)
	
	print("Last choice: %s, Compatibility: %.2f" % [SocialDNAManager.get_social_type_name(last_choice), compatibility])
	
	# Compatibility gate check
	if compatibility < -0.8:  # Very low compatibility
		# Conversation cut short
		_end_conversation_early("compatibility_failed")
		return """
~ start
%s: %s
%s
=> END
""" % [current_npc_name, turn_data.compatibility_fail_response, "[You've failed to build rapport with %s]" % current_npc_name]
	
	# Get NPC reaction based on the player's last choice
	var reaction_key = SocialDNAManager.get_social_type_name(last_choice).to_lower()
	var reaction = turn_data.npc_reactions.get(reaction_key, turn_data.npc_reactions["default"])
	
	# Add revealed information based on compatibility
	var info_reveal = ""
	if compatibility >= 0.5:
		info_reveal = turn_data.high_compat_info
		conversation_context["info_level"] = "high"
	elif compatibility >= 0.0:
		info_reveal = turn_data.medium_compat_info
		conversation_context["info_level"] = "medium"
	else:
		info_reveal = turn_data.low_compat_info
		conversation_context["info_level"] = "low"
	
	print("Reaction key: %s, Info level: %s" % [reaction_key, conversation_context["info_level"]])
	print("========================")
	
	return """
~ start
%s: %s
%s
- Continue
	do conversation_manager.set_advance_turn()
	=> END
""" % [current_npc_name, reaction, info_reveal]

# Generate Turn 4: Player Critical Choice
func _generate_turn_4_dialogue(turn_data: Dictionary) -> String:
	var info_level = conversation_context.get("info_level", "low")
	var available_responses = turn_data.critical_responses.get(info_level, turn_data.critical_responses["default"])
	
	var dialogue_text = """
~ start
%s: How do you want to proceed?
""" % current_npc_name
	
	# Add critical choice options
	for response in available_responses:
		var social_type = response.social_type as int
		dialogue_text += """
- [%s] %s
	do conversation_manager.set_player_choice_and_advance(%d)
	=> END
""" % [response.label, response.text, social_type]
	
	return dialogue_text

# Generate Turn 5: Conclusion
func _generate_turn_5_dialogue(turn_data: Dictionary, relationship: RelationshipTracker.NPCRelationship) -> String:
	if social_choices_made.size() < 2:
		print("Error: Not enough social choices for conclusion")
		return _generate_error_dialogue()
	
	var compatibility = SocialDNAManager.calculate_compatibility(current_npc_archetype)
	var final_choice = social_choices_made[-1]
	var conversation_success = _calculate_conversation_success()
	
	var outcome_key = "success" if conversation_success else "failure"
	var conclusion = turn_data.conclusions[outcome_key]
	
	var rewards_text = ""
	var outcome_message = ""
	
	if conversation_success:
		# Add rewards
		var rewards = turn_data.rewards.get("success", [])
		for reward in rewards:
			rewards_text += "[%s]\n" % reward
			relationship_tracker.add_reward(current_npc_name, reward)
		
		outcome_message = "[Conversation successful! %s trusts you more.]" % current_npc_name
		relationship_tracker.update_relationship(current_npc_name, "successful_cooperation", current_topic, social_choices_made)
	else:
		outcome_message = "[You've failed to get the information]"
		relationship_tracker.mark_topic_failed(current_npc_name, current_topic)
		relationship_tracker.update_relationship(current_npc_name, "conversation_failed", current_topic, social_choices_made)
	
	# End conversation
	_end_conversation(outcome_key, turn_data.rewards.get(outcome_key, []))
	
	return """
~ start
%s: %s
%s
%s
- End Conversation
	=> END
""" % [current_npc_name, conclusion, rewards_text, outcome_message]

# Calculate if conversation was successful based on choices and compatibility
func _calculate_conversation_success() -> bool:
	var compatibility = SocialDNAManager.calculate_compatibility(current_npc_archetype)
	var choice_score = 0
	
	# Score based on how well choices align with NPC preferences
	for choice in social_choices_made:
		var preference = SocialDNAManager.npc_compatibility[current_npc_archetype].get(choice, 0)
		choice_score += preference
	
	# Success threshold based on compatibility and choices
	var success_threshold = -1.0 if compatibility >= 0.5 else 0.0
	return (choice_score + compatibility) >= success_threshold

# End conversation early (compatibility failed)
func _end_conversation_early(reason: String):
	conversation_active = false
	current_turn = 0
	compatibility_check_failed.emit(current_npc_name)
	print("Conversation ended early: %s with %s" % [reason, current_npc_name])

# End conversation normally
func _end_conversation(outcome: String, rewards: Array):
	conversation_active = false
	current_turn = 0
	conversation_ended.emit(outcome, rewards)
	print("Conversation ended: %s with %s (Rewards: %d)" % [outcome, current_npc_name, rewards.size()])

# Generate error dialogue
func _generate_error_dialogue() -> String:
	return """
~ start
System: An error occurred in the conversation system.
- End
	=> END
"""

# Process turn advancement and player choices (called by dialogue system)
func process_conversation_state():
	print("process_conversation_state called - Turn: %d, player_choice: %d, advance_turn: %s" % [current_turn, player_choice, advance_turn])
	
	# Check if a player choice was made and process it
	if player_choice >= 0:
		print("Processing player choice from dialogue: %d" % player_choice)
		record_player_choice(player_choice)
		player_choice = -1  # Reset after processing
	
	# Check if we should advance to the next turn
	if advance_turn:
		print("Advancing turn from %d to %d" % [current_turn, current_turn + 1])
		advance_turn = false  # Reset flag
		
		if conversation_active and current_turn < 5:
			current_turn += 1
			return _generate_turn_dialogue()
		else:
			print("Conversation finished or turn limit reached")
	
	return null

# Methods that can be called from dialogue mutations
func set_advance_turn():
	advance_turn = true
	print("set_advance_turn() called - advance_turn is now true")

func set_player_choice_and_advance(choice: int):
	player_choice = choice
	advance_turn = true
	print("set_player_choice_and_advance(%d) called - player_choice: %d, advance_turn: true" % [choice, choice])

# Handle player choice (called by dialogue system)
func record_player_choice(choice_value: int):
	var social_type = choice_value as SocialDNAManager.SocialType
	social_choices_made.append(social_type)
	
	# Process Social DNA change
	SocialDNAManager.process_dialogue_choice(social_type)
	
	print("=== CHOICE RECORDED ===")
	print("Recorded player choice: %s (value: %d)" % [SocialDNAManager.get_social_type_name(social_type), choice_value])
	print("Total choices made: %d" % social_choices_made.size())
	print("social_choices_made array: %s" % social_choices_made)
	print("=======================")
