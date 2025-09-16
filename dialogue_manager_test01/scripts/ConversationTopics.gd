class_name ConversationTopics
extends RefCounted

# All conversation topics data
var topics_data: Dictionary = {}

func _init():
	_initialize_topics()

func _initialize_topics():
	topics_data = {
		"security_incident": _create_security_incident_topic(),
		"research_data": _create_research_data_topic()
	}

# Get topic data for a specific topic and archetype
func get_topic_data(topic_id: String, archetype: SocialDNAManager.NPCArchetype) -> Dictionary:
	if not topics_data.has(topic_id):
		print("Topic not found: %s" % topic_id)
		return {}
	
	var topic = topics_data[topic_id]
	
	# Return archetype-specific version if it exists
	if topic.has(archetype):
		return topic[archetype]
	else:
		print("Archetype %s not found for topic %s" % [archetype, topic_id])
		return {}

# AUTHORITY TOPIC: Security Incident Investigation
func _create_security_incident_topic() -> Dictionary:
	return {
		SocialDNAManager.NPCArchetype.AUTHORITY: {
			"topic_name": "Security Incident Investigation",
			"description": "Commander Steel needs help investigating suspicious activities",
			"turns": [
				{
					"turn": 1,
					"npc_openings": {
						"trusted_high_compat": "I'm glad you're here. We've got a serious situation and I could use someone I trust completely on this.",
						"professional_good_compat": "Good timing. I've got a security matter that requires discretion and competence.",
						"default": "I don't usually discuss operational security with outsiders, but circumstances are unusual.",
						"low_compat": "I'm not sure I should be talking to you about this, but I'm running out of options."
					}
				},
				{
					"turn": 2,
					"player_responses": [
						{
							"social_type": SocialDNAManager.SocialType.AGGRESSIVE,
							"label": "AGGRESSIVE",
							"text": "Who do we need to eliminate? I'm ready to handle this threat directly."
						},
						{
							"social_type": SocialDNAManager.SocialType.DIPLOMATIC,
							"label": "DIPLOMATIC", 
							"text": "What kind of cooperation are you looking for? I'm here to help resolve this professionally."
						},
						{
							"social_type": SocialDNAManager.SocialType.DIRECT,
							"label": "DIRECT",
							"text": "Give me the facts. What exactly happened and when?"
						},
						{
							"social_type": SocialDNAManager.SocialType.EMPATHETIC,
							"label": "EMPATHETIC",
							"text": "You seem concerned about your people's safety. What's threatening them?"
						},
						{
							"social_type": SocialDNAManager.SocialType.CHARMING,
							"label": "CHARMING",
							"text": "I'm sure someone with your experience has this under control. How can I assist?"
						}
					]
				},
				{
					"turn": 3,
					"compatibility_fail_response": "Actually, I think this is something I should handle through official channels. Thanks anyway.",
					"npc_reactions": {
						"aggressive": "That's exactly the kind of decisive thinking we need. No hesitation, no bureaucracy.",
						"diplomatic": "Professional approach. I appreciate someone who understands proper protocols.",
						"direct": "Straight to the point. I respect that. Here are the facts...",
						"empathetic": "Yes, I am worried about my people. It's good to know someone else cares about their welfare.",
						"charming": "Flattery won't change the facts, but I suppose you mean well.",
						"default": "I see. Well, here's what we're dealing with..."
					},
					"high_compat_info": "Three of our patrol ships have gone missing in sector 7-G over the past week. No distress calls, no debris. Their transponders went dark simultaneously. Intel suggests organized pirates with inside knowledge.",
					"medium_compat_info": "We've lost contact with several patrol ships in the outer sectors. It's more than equipment failure - someone's targeting our operations.",
					"low_compat_info": "Some patrol ships have gone missing recently. Could be pirates, could be equipment failures."
				},
				{
					"turn": 4,
					"critical_responses": {
						"high": [
							{
								"social_type": SocialDNAManager.SocialType.AGGRESSIVE,
								"label": "AGGRESSIVE",
								"text": "Let's organize a strike force and hit their base in sector 7-G before they expect it."
							},
							{
								"social_type": SocialDNAManager.SocialType.DIPLOMATIC,
								"label": "DIPLOMATIC",
								"text": "We should investigate the inside source first. Can't win if they know our every move."
							},
							{
								"social_type": SocialDNAManager.SocialType.DIRECT,
								"label": "DIRECT",
								"text": "Send me to sector 7-G with a reconnaissance team. I'll get you actionable intelligence."
							}
						],
						"medium": [
							{
								"social_type": SocialDNAManager.SocialType.AGGRESSIVE,
								"label": "AGGRESSIVE", 
								"text": "We should patrol those sectors in force. Show these pirates we mean business."
							},
							{
								"social_type": SocialDNAManager.SocialType.DIPLOMATIC,
								"label": "DIPLOMATIC",
								"text": "Perhaps we could coordinate with other local authorities to share patrol duties?"
							},
							{
								"social_type": SocialDNAManager.SocialType.DIRECT,
								"label": "DIRECT",
								"text": "I'll investigate the missing ships personally. Give me their last known positions."
							}
						],
						"default": [
							{
								"social_type": SocialDNAManager.SocialType.DIRECT,
								"label": "DIRECT",
								"text": "I'll look into this situation if you want."
							},
							{
								"social_type": SocialDNAManager.SocialType.DIPLOMATIC,
								"label": "DIPLOMATIC",
								"text": "Maybe we could work together on this problem."
							}
						]
					}
				},
				{
					"turn": 5,
					"conclusions": {
						"success": "Excellent. I'm authorizing you to lead this investigation. Here are the coordinates and access codes.",
						"failure": "I appreciate the offer, but I think this requires someone with more... specialized experience."
					},
					"rewards": {
						"success": [
							"Hidden pirate base coordinates added to your navigation system",
							"Commander Steel will provide tactical support for operations",
							"Access granted to restricted military supply routes"
						],
						"failure": []
					}
				}
			]
		}
	}

# INTELLECTUAL TOPIC: Anomalous Research Data
func _create_research_data_topic() -> Dictionary:
	return {
		SocialDNAManager.NPCArchetype.INTELLECTUAL: {
			"topic_name": "Anomalous Research Data", 
			"description": "Dr. Vega has discovered unusual readings that don't match known phenomena",
			"turns": [
				{
					"turn": 1,
					"npc_openings": {
						"trusted_high_compat": "Perfect timing! I've been hoping to discuss this with someone who appreciates the implications of unusual data.",
						"professional_good_compat": "I'm glad you're here. I could use a fresh perspective on some... interesting findings.",
						"default": "I've been analyzing some unusual sensor readings. Perhaps you'd find them intriguing.",
						"low_compat": "I'm not sure you'd understand the significance, but I suppose I could explain the basics."
					}
				},
				{
					"turn": 2,
					"player_responses": [
						{
							"social_type": SocialDNAManager.SocialType.DIPLOMATIC,
							"label": "DIPLOMATIC",
							"text": "I'd be honored to collaborate on your research. What can I contribute to the investigation?"
						},
						{
							"social_type": SocialDNAManager.SocialType.DIRECT,
							"label": "DIRECT",
							"text": "What exactly did you find? Give me the data and your analysis."
						},
						{
							"social_type": SocialDNAManager.SocialType.EMPATHETIC,
							"label": "EMPATHETIC",
							"text": "You seem excited about this discovery. It must be something significant to you."
						},
						{
							"social_type": SocialDNAManager.SocialType.CHARMING,
							"label": "CHARMING",
							"text": "Your research always fascinates me. I'm sure this discovery will be groundbreaking."
						},
						{
							"social_type": SocialDNAManager.SocialType.AGGRESSIVE,
							"label": "AGGRESSIVE",
							"text": "Is this data valuable? Could it give us an advantage over our competitors?"
						}
					]
				},
				{
					"turn": 3,
					"compatibility_fail_response": "On second thought, this research is quite technical. I should probably focus on finding more qualified collaborators.",
					"npc_reactions": {
						"diplomatic": "Collaboration is exactly what this discovery needs. Multiple perspectives will be crucial.",
						"direct": "Your direct approach is refreshing. Too many people get lost in theoretical discussions.",
						"empathetic": "Yes, this could revolutionize our understanding! It's wonderful to share this excitement with someone.",
						"charming": "You're kind to say so. Though I must say, the data speaks for itself regardless of flattery.",
						"aggressive": "Competitive advantage? That's... not exactly how I think about scientific discovery, but I suppose there are practical implications.",
						"default": "Well, let me show you what I've found..."
					},
					"high_compat_info": "The quantum resonance patterns suggest a previously unknown type of exotic matter near the Helix Nebula. It's emitting energy signatures that violate three different conservation laws. If this is real, it could revolutionize propulsion technology and our understanding of physics.",
					"medium_compat_info": "I've detected unusual energy patterns near the Helix Nebula that don't match any known phenomena. The readings suggest something that could have significant scientific implications.",
					"low_compat_info": "There are some strange readings from the outer systems. Probably just instrument calibration issues, but worth investigating."
				},
				{
					"turn": 4,
					"critical_responses": {
						"high": [
							{
								"social_type": SocialDNAManager.SocialType.DIPLOMATIC,
								"label": "DIPLOMATIC",
								"text": "We should coordinate with other research institutions to verify these findings before publishing."
							},
							{
								"social_type": SocialDNAManager.SocialType.DIRECT,
								"label": "DIRECT", 
								"text": "I'll mount an expedition to the Helix Nebula to collect direct samples and readings."
							},
							{
								"social_type": SocialDNAManager.SocialType.EMPATHETIC,
								"label": "EMPATHETIC",
								"text": "This discovery could benefit all of humanity. How can we ensure the knowledge is shared responsibly?"
							}
						],
						"medium": [
							{
								"social_type": SocialDNAManager.SocialType.DIPLOMATIC,
								"label": "DIPLOMATIC",
								"text": "Maybe we should get a second opinion from other researchers before drawing conclusions?"
							},
							{
								"social_type": SocialDNAManager.SocialType.DIRECT,
								"label": "DIRECT",
								"text": "I could help you investigate these readings if you want a research partner."
							},
							{
								"social_type": SocialDNAManager.SocialType.EMPATHETIC,
								"label": "EMPATHETIC",
								"text": "You seem passionate about this. How can I help you pursue the research?"
							}
						],
						"default": [
							{
								"social_type": SocialDNAManager.SocialType.DIRECT,
								"label": "DIRECT",
								"text": "I could look into this if you think it's worth investigating."
							},
							{
								"social_type": SocialDNAManager.SocialType.DIPLOMATIC,
								"label": "DIPLOMATIC",
								"text": "Perhaps we could work together on understanding this data."
							}
						]
					}
				},
				{
					"turn": 5,
					"conclusions": {
						"success": "Wonderful! I'm transmitting the full dataset to your systems. Welcome to potentially the most important discovery of our generation.",
						"failure": "I think this research requires someone with more specialized background. But thank you for your interest."
					},
					"rewards": {
						"success": [
							"Dr. Vega will share her complete research database with you",
							"Exotic matter sample location added to your star charts",
							"Priority access to Dr. Vega's future discoveries and research"
						],
						"failure": []
					}
				}
			]
		}
	}

# Helper function to get all available topics for an archetype
func get_topics_for_archetype(archetype: SocialDNAManager.NPCArchetype) -> Array:
	var topics = []
	for topic_id in topics_data:
		if topics_data[topic_id].has(archetype):
			topics.append({
				"id": topic_id,
				"name": topics_data[topic_id][archetype].topic_name,
				"description": topics_data[topic_id][archetype].description
			})
	return topics
