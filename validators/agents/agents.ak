use agents/types.{AgentActions, AgentDatum, GetTotalAgentCount, RegisterAgent}

validator agents {
  spend(
    datum: Option<AgentDatum>,
    r: AgentActions,
    _oref,
    _tx,
  ) {
    expect Some(old) = datum

    when r is {
      RegisterAgent { .. } -> {
        // Simple validation - just check we have a datum
        old.total_count >= 0
      }

      GetTotalAgentCount -> old.total_count >= 0
    }
  }

  else(_) {
    fail
  }
}