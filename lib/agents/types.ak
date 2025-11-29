pub type Agent {
  agent_address: ByteArray,
  provider: ByteArray,
  is_active: Bool,
}

pub type AgentDatum {
  agents: List<Agent>,
  total_count: Int,
}

pub type AgentActions {
  RegisterAgent {
    agent_address: ByteArray,
  }
  GetTotalAgentCount
}