use aiken/collection/list
use aiken/crypto.{VerificationKeyHash}
use aiken/interval.{Finite}
use aiken/primitive/bytearray
use cardano/script_context.{ScriptContext, ScriptInfo}
use cardano/transaction.{InlineDatum, Output, Transaction, ValidityRange}

// Agent data structure
pub type Agent {
  agent_address: VerificationKeyHash,
  provider: VerificationKeyHash,
  agent_id_hash: ByteArray,
  owner: ByteArray,
  is_active: Bool,
  created_at: Int,
  updated_at: Int,
  metadata_uri: ByteArray,
}

// Contract datum - stores all agents
pub type AgentDatum {
  contract_owner: VerificationKeyHash,
  agents: List<Agent>,
}

// Redeemer actions
pub type AgentRedeemer {
  RegisterAgent {
    agent_address: VerificationKeyHash,
    agent_id_hash: ByteArray,
    owner: ByteArray,
    metadata_uri: ByteArray,
  }
  UpdateAgent {
    agent_address: VerificationKeyHash,
    is_active: Bool,
    metadata_uri: ByteArray,
  }
  GetAgent { agent_address: VerificationKeyHash }
}

// Helper function to find agent in list
fn find_agent(
  agents: List<Agent>,
  target_address: VerificationKeyHash,
) -> Option<Agent> {
  list.find(agents, fn(agent) { agent.agent_address == target_address })
}

// Helper function to check if agent exists
fn agent_exists(
  agents: List<Agent>,
  target_address: VerificationKeyHash,
) -> Bool {
  when find_agent(agents, target_address) is {
    Some(_) -> True
    None -> False
  }
}

// Helper function to remove agent from list
fn remove_agent(
  agents: List<Agent>,
  target_address: VerificationKeyHash,
) -> List<Agent> {
  list.filter(agents, fn(agent) { agent.agent_address != target_address })
}

// Helper function to get current time from transaction
fn get_current_time(validity_range: ValidityRange) -> Int {
  when validity_range.upper_bound.bound_type is {
    Finite(time) -> time
    _ -> 0
  }
}

// Helper function to verify provider signature
fn is_signed_by(
  transaction: Transaction,
  vk: VerificationKeyHash,
) -> Bool {
  list.has(transaction.extra_signatories, vk)
}

// Main validator function
validator agent_contract {
  spend(
    datum_opt: Option<AgentDatum>,
    redeemer: AgentRedeemer,
    _own_ref: Data,
    ctx: ScriptContext,
  ) {
    // Extract datum
    expect Some(datum) = datum_opt

    let ScriptContext { transaction, redeemer: _ctx_redeemer, info } = ctx

    // Ensure we're spending from this contract
    expect ScriptInfo.Spending { .. } = info

    // Get the output datum (new state)
    expect Some(output) = list.head(transaction.outputs)
    expect InlineDatum(output_datum_data) = output.datum
    expect new_datum: AgentDatum = output_datum_data

    when redeemer is {
      // Register a new agent
      RegisterAgent { agent_address, agent_id_hash, owner, metadata_uri } -> {
        // Check that provider is signing the transaction
        let provider = list.head(transaction.extra_signatories)
        expect Some(provider_vk) = provider

        // Verify agent doesn't already exist
        let agent_not_exists = !agent_exists(datum.agents, agent_address)

        // Get current timestamp
        let current_time = get_current_time(transaction.validity_range)

        // Create new agent
        let new_agent =
          Agent {
            agent_address,
            provider: provider_vk,
            agent_id_hash,
            owner,
            is_active: True,
            created_at: current_time,
            updated_at: current_time,
            metadata_uri,
          }

        // Verify new datum has the agent added
        let expected_agents = list.push(datum.agents, new_agent)
        let datum_updated = new_datum.agents == expected_agents

        // All conditions must be true
        and {
          agent_not_exists?,
          datum_updated?,
          new_datum.contract_owner == datum.contract_owner,
        }
      }

      // Update an existing agent
      UpdateAgent { agent_address, is_active, metadata_uri } -> {
        // Find the agent to update
        expect Some(existing_agent) = find_agent(datum.agents, agent_address)

        // Check that provider is signing the transaction
        let is_provider = is_signed_by(transaction, existing_agent.provider)

        // Get current timestamp
        let current_time = get_current_time(transaction.validity_range)

        // Create updated agent
        let updated_metadata =
          if bytearray.length(metadata_uri) == 0 {
            existing_agent.metadata_uri
          } else {
            metadata_uri
          }

        let updated_agent =
          Agent {
            agent_address: existing_agent.agent_address,
            provider: existing_agent.provider,
            agent_id_hash: existing_agent.agent_id_hash,
            owner: existing_agent.owner,
            is_active,
            created_at: existing_agent.created_at,
            updated_at: current_time,
            metadata_uri: updated_metadata,
          }

        // Remove old agent and add updated one
        let agents_without_old = remove_agent(datum.agents, agent_address)
        let expected_agents = list.push(agents_without_old, updated_agent)

        // Verify new datum is correct
        let datum_updated = new_datum.agents == expected_agents

        // All conditions must be true
        and {
          is_provider?,
          datum_updated?,
          new_datum.contract_owner == datum.contract_owner,
        }
      }

      // Query agent (read-only, always succeeds if agent exists)
      GetAgent { agent_address } ->
        // Simply verify agent exists
        agent_exists(datum.agents, agent_address)
    }
  }

  else(_) {
    fail
  }
}

// Tests
test find_agent_and_exists() {
  let provider_vk = #"efef5678"
  let agent_vk = #"aabb9012"

  let existing_agent =
    Agent {
      agent_address: agent_vk,
      provider: provider_vk,
      agent_id_hash: #"a1b2c3d4",
      owner: #"0a0b0c0d",
      is_active: True,
      created_at: 1000,
      updated_at: 1000,
      metadata_uri: #"01020304",
    }

  let agents_list = [existing_agent]

  expect Some(a) = find_agent(agents_list, agent_vk)
  expect agent_exists(agents_list, agent_vk)
  expect a.provider == provider_vk
}

test remove_agent_removes_existing() {
  let provider_vk = #"efef5678"
  let agent_a = #"abcd0001"
  let agent_b = #"abcd0002"

  let agent1 =
    Agent {
      agent_address: agent_a,
      provider: provider_vk,
      agent_id_hash: #"11112222",
      owner: #"aaaa1111",
      is_active: True,
      created_at: 1,
      updated_at: 1,
      metadata_uri: #"10101010",
    }

  let agent2 =
    Agent {
      agent_address: agent_b,
      provider: provider_vk,
      agent_id_hash: #"22223333",
      owner: #"bbbb2222",
      is_active: True,
      created_at: 2,
      updated_at: 2,
      metadata_uri: #"20202020",
    }

  let agents_list = [agent1, agent2]

  let removed = remove_agent(agents_list, agent_a)

  expect list.length(removed) == 1
  expect None = find_agent(removed, agent_a)
  expect Some(a) = find_agent(removed, agent_b)
  expect a.agent_address == agent_b
}

test register_agent_pushes_new_agent() {
  let owner_vk = #"abcd1234"
  let provider_vk = #"efef5678"
  let agent_vk = #"beef0001"

  let initial_datum = AgentDatum { contract_owner: owner_vk, agents: [] }

  let current_time = 1234

  let new_agent =
    Agent {
      agent_address: agent_vk,
      provider: provider_vk,
      agent_id_hash: #"a1b2c3d4",
      owner: #"0a0b0c0d",
      is_active: True,
      created_at: current_time,
      updated_at: current_time,
      metadata_uri: #"01020304",
    }

  let expected_agents = list.push(initial_datum.agents, new_agent)

  expect list.length(expected_agents) == 1
  expect Some(a) = list.head(expected_agents)
  expect a.agent_address == agent_vk
  expect a.provider == provider_vk
}

test update_agent_replaces_old_agent() {
  let provider_vk = #"efef5678"
  let agent_vk = #"beef0001"

  let existing_agent =
    Agent {
      agent_address: agent_vk,
      provider: provider_vk,
      agent_id_hash: #"a1b2c3d4",
      owner: #"0a0b0c0d",
      is_active: True,
      created_at: 1000,
      updated_at: 1000,
      metadata_uri: #"01020304",
    }

  let initial_datum = AgentDatum { contract_owner: #"abcd1234", agents: [existing_agent] }

  let current_time = 2000

  let updated_agent =
    Agent {
      agent_address: existing_agent.agent_address,
      provider: existing_agent.provider,
      agent_id_hash: existing_agent.agent_id_hash,
      owner: existing_agent.owner,
      is_active: False,
      created_at: existing_agent.created_at,
      updated_at: current_time,
      metadata_uri: #"0f0e0d0c",
    }

  let agents_without_old = remove_agent(initial_datum.agents, agent_vk)
  let expected_agents = list.push(agents_without_old, updated_agent)

  expect list.length(expected_agents) == 1
  expect Some(a) = list.head(expected_agents)
  expect a.is_active == False
  expect a.metadata_uri == #"0f0e0d0c"
}