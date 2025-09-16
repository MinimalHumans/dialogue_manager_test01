class_name RelationshipTracker
extends RefCounted

# Relationship levels
enum TrustLevel {
	CAUTIOUS,      # 0 - Just met, low trust
	PROFESSIONAL,  # 1 - Basic working relationship  
	TRUSTED,       # 2 - Reliable, shares sensitive info
	CLOSE          # 3 - Personal connection, full access
}

# Individual NPC relationship data
class NPCRelationship:
	var npc_name: String
	var trust_level: TrustLevel = TrustLevel.CAUTIOUS
	var interactions_count: int = 0
	var topics_discussed: Array[String] = []
	var last_conversation_outcome: String = ""
	var failed_topics: Array[String] = []  # Topics that failed, can be retried
	var unlocked_rewards: Array[String] = []
	var player_social_tendencies: Dictionary = {}
	
	func _init(name: String):
		npc_name = name
		_calculate_social_tendencies()
	
	func _calculate_social_tendencies():
		# Track which social approaches this player uses most with this NPC
		var social_counts = {}
		for social_type in SocialDNAManager.SocialType.values():
			social_counts[social_type] = 0
		player_social_tendencies = social_counts

# Global relationship storage
var npc_relationships: Dictionary = {}

# Get or create relationship for an NPC
func get_relationship(npc_name: String) -> NPCRelationship:
	if not npc_relationships.has(npc_name):
		npc_relationships[npc_name] = NPCRelationship.new(npc_name)
	return npc_relationships[npc_name]

# Update relationship after a conversation
func update_relationship(npc_name: String, outcome: String, topic: String = "", social_choices: Array = []):
	var relationship = get_relationship(npc_name)
	relationship.interactions_count += 1
	relationship.last_conversation_outcome = outcome
	
	# Track topic
	if topic != "" and not relationship.topics_discussed.has(topic):
		relationship.topics_discussed.append(topic)
	
	# Track social choices made in this conversation
	for choice in social_choices:
		if choice is SocialDNAManager.SocialType:
			relationship.player_social_tendencies[choice] += 1
	
	# Update trust level based on outcome and Social DNA compatibility
	_update_trust_level(relationship, outcome)
	
	print("Updated relationship with %s: %s (Trust: %s, Interactions: %d)" % [
		npc_name, 
		outcome,
		get_trust_level_name(relationship.trust_level),
		relationship.interactions_count
	])

# Update trust level based on conversation outcomes and compatibility
func _update_trust_level(relationship: NPCRelationship, outcome: String):
	var trust_change = 0
	
	# Determine trust change based on outcome
	match outcome:
		"successful_cooperation":
			trust_change = 1
		"partial_success":
			trust_change = 0  # No change
		"conversation_failed":
			trust_change = 0  # No change, but can retry
		"relationship_damaged":
			trust_change = -1
	
	# Modify based on current compatibility (higher compatibility = easier trust gain)
	# This will be passed from the conversation system
	
	# Apply trust change
	var new_trust = relationship.trust_level + trust_change
	relationship.trust_level = clamp(new_trust, TrustLevel.CAUTIOUS, TrustLevel.CLOSE) as TrustLevel

# Check if a topic is available for this NPC based on relationship level
func is_topic_available(npc_name: String, topic: String, required_trust: TrustLevel) -> bool:
	var relationship = get_relationship(npc_name)
	return relationship.trust_level >= required_trust

# Mark a topic as failed (can be retried)
func mark_topic_failed(npc_name: String, topic: String):
	var relationship = get_relationship(npc_name)
	if not relationship.failed_topics.has(topic):
		relationship.failed_topics.append(topic)

# Check if a topic has been failed before
func has_topic_failed(npc_name: String, topic: String) -> bool:
	var relationship = get_relationship(npc_name)
	return relationship.failed_topics.has(topic)

# Add a reward to relationship tracking
func add_reward(npc_name: String, reward: String):
	var relationship = get_relationship(npc_name)
	if not relationship.unlocked_rewards.has(reward):
		relationship.unlocked_rewards.append(reward)

# Get trust level as string
func get_trust_level_name(level: TrustLevel) -> String:
	match level:
		TrustLevel.CAUTIOUS: return "Cautious"
		TrustLevel.PROFESSIONAL: return "Professional"
		TrustLevel.TRUSTED: return "Trusted"
		TrustLevel.CLOSE: return "Close"
		_: return "Unknown"

# Get trust level as visual indicator (●●○○ style)
func get_trust_visual(level: TrustLevel) -> String:
	match level:
		TrustLevel.CAUTIOUS: return "●○○○"
		TrustLevel.PROFESSIONAL: return "●●○○" 
		TrustLevel.TRUSTED: return "●●●○"
		TrustLevel.CLOSE: return "●●●●"
		_: return "○○○○"

# Get relationship color for UI
func get_trust_color(level: TrustLevel) -> Color:
	match level:
		TrustLevel.CAUTIOUS: return Color.GRAY
		TrustLevel.PROFESSIONAL: return Color.YELLOW
		TrustLevel.TRUSTED: return Color.CYAN
		TrustLevel.CLOSE: return Color.GREEN
		_: return Color.WHITE

# Get available topics for an NPC (will be populated by ConversationTopics)
func get_available_topics(npc_name: String, npc_archetype: SocialDNAManager.NPCArchetype) -> Array:
	var relationship = get_relationship(npc_name)
	var available = []
	
	# This will be expanded when we add ConversationTopics
	# For now, just basic topics based on archetype and trust level
	
	if npc_archetype == SocialDNAManager.NPCArchetype.AUTHORITY:
		available.append({
			"id": "security_incident",
			"name": "Security Incident Investigation", 
			"required_trust": TrustLevel.CAUTIOUS,
			"is_new": not relationship.topics_discussed.has("security_incident"),
			"has_failed": has_topic_failed(npc_name, "security_incident")
		})
		
		# Higher level topics locked behind trust
		if relationship.trust_level >= TrustLevel.TRUSTED:
			available.append({
				"id": "classified_operations",
				"name": "Classified Operations",
				"required_trust": TrustLevel.TRUSTED,
				"is_new": not relationship.topics_discussed.has("classified_operations"),
				"has_failed": has_topic_failed(npc_name, "classified_operations")
			})
	
	elif npc_archetype == SocialDNAManager.NPCArchetype.INTELLECTUAL:
		available.append({
			"id": "research_data",
			"name": "Anomalous Research Data",
			"required_trust": TrustLevel.CAUTIOUS,
			"is_new": not relationship.topics_discussed.has("research_data"),
			"has_failed": has_topic_failed(npc_name, "research_data")
		})
		
		# Higher level topics
		if relationship.trust_level >= TrustLevel.TRUSTED:
			available.append({
				"id": "secret_research",
				"name": "Secret Research Project",
				"required_trust": TrustLevel.TRUSTED,
				"is_new": not relationship.topics_discussed.has("secret_research"),
				"has_failed": has_topic_failed(npc_name, "secret_research")
			})
	
	return available
