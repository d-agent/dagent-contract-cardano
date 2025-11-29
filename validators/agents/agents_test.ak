use agents/types.{Agent, AgentDatum, GetTotalAgentCount, RegisterAgent}

test basic_agent_datum() {
  let agent = Agent {
    agent_address: "test_address",
    provider: "test_provider", 
    is_active: True,
  }
  
  let datum = AgentDatum {
    agents: [agent],
    total_count: 1,
  }
  
  datum.total_count == 1
}

test register_agent_action() {
  let action = RegisterAgent {
    agent_address: "new_agent",
  }
  
  // Simple test - action should be created successfully
  when action is {
    RegisterAgent { .. } -> True
    _ -> False
  }
}