use aiken/collection/list
use stake/transition
use stake/types.{
  CreateStake, PullAllStake, PullStake, Stake, StakeDatum, TransferStake,
}

test create_stake_updates_total() {
  let before = StakeDatum { stakes: [], total_stake: 0, total_count: 0 }

  let act =
    CreateStake {
      client: "abcd",
      provider: "efgh",
      amount: 50,
      user_id: "user1",
    }

  let after = transition.create_stake(before, act)

  expect after.total_stake == 50
  expect after.total_count == 1
}

test create_stake_adds_new_stake() {
  let before = StakeDatum { stakes: [], total_stake: 0, total_count: 0 }

  let act =
    CreateStake {
      client: "client1",
      provider: "provider1",
      amount: 100,
      user_id: "user1",
    }

  let after = transition.create_stake(before, act)

  expect list.length(after.stakes) == 1
  expect Some(stake) = list.head(after.stakes)
  expect stake.client == "client1"
  expect stake.provider == "provider1"
  expect stake.amount == 100
  expect stake.user_id == "user1"
}

test create_stake_multiple_users() {
  let state1 = StakeDatum { stakes: [], total_stake: 0, total_count: 0 }

  let act1 =
    CreateStake {
      client: "client1",
      provider: "provider1",
      amount: 50,
      user_id: "user1",
    }

  let state2 = transition.create_stake(state1, act1)

  let act2 =
    CreateStake {
      client: "client2",
      provider: "provider2",
      amount: 75,
      user_id: "user2",
    }

  let state3 = transition.create_stake(state2, act2)

  expect state3.total_stake == 125
  expect state3.total_count == 2
  expect list.length(state3.stakes) == 2
}

test transfer_stake_partial_amount() {
  let initial_stake =
    Stake.Record {
      client: "client1",
      provider: "provider1",
      amount: 100,
      user_id: "user1",
    }

  let before =
    StakeDatum { stakes: [initial_stake], total_stake: 100, total_count: 1 }

  let act =
    TransferStake { from_user_id: "user1", to_user_id: "user2", amount: 30 }

  let after = transition.transfer_stake(before, act)

  expect after.total_stake == 100
  expect after.total_count == 2

  expect Some(from_stake) =
    list.find(after.stakes, fn(s) { s.user_id == "user1" })
  expect Some(to_stake) =
    list.find(after.stakes, fn(s) { s.user_id == "user2" })

  expect from_stake.amount == 70
  expect to_stake.amount == 30
}

test transfer_stake_full_amount() {
  let initial_stake =
    Stake.Record {
      client: "client1",
      provider: "provider1",
      amount: 100,
      user_id: "user1",
    }

  let before =
    StakeDatum { stakes: [initial_stake], total_stake: 100, total_count: 1 }

  let act =
    TransferStake { from_user_id: "user1", to_user_id: "user2", amount: 100 }

  let after = transition.transfer_stake(before, act)

  expect after.total_stake == 100
  expect after.total_count == 1

  expect Some(to_stake) =
    list.find(after.stakes, fn(s) { s.user_id == "user2" })
  expect to_stake.amount == 100

  expect None = list.find(after.stakes, fn(s) { s.user_id == "user1" })
}

test transfer_stake_to_existing_user() {
  let stake1 =
    Stake.Record {
      client: "client1",
      provider: "provider1",
      amount: 100,
      user_id: "user1",
    }

  let stake2 =
    Stake.Record {
      client: "client2",
      provider: "provider2",
      amount: 50,
      user_id: "user2",
    }

  let before =
    StakeDatum { stakes: [stake1, stake2], total_stake: 150, total_count: 2 }

  let act =
    TransferStake { from_user_id: "user1", to_user_id: "user2", amount: 40 }

  let after = transition.transfer_stake(before, act)

  expect after.total_stake == 150
  expect after.total_count == 2

  expect Some(from_stake) =
    list.find(after.stakes, fn(s) { s.user_id == "user1" })
  expect Some(to_stake) =
    list.find(after.stakes, fn(s) { s.user_id == "user2" })

  expect from_stake.amount == 60
  expect to_stake.amount == 90
}

test pull_stake_partial_amount() {
  let initial_stake =
    Stake.Record {
      client: "client1",
      provider: "provider1",
      amount: 100,
      user_id: "user1",
    }

  let before =
    StakeDatum { stakes: [initial_stake], total_stake: 100, total_count: 1 }

  let act = PullStake { user_id: "user1", amount: 30 }

  let after = transition.pull_stake(before, act)

  expect after.total_stake == 70
  expect after.total_count == 1

  expect Some(stake) = list.find(after.stakes, fn(s) { s.user_id == "user1" })
  expect stake.amount == 70
}

test pull_stake_full_amount() {
  let initial_stake =
    Stake.Record {
      client: "client1",
      provider: "provider1",
      amount: 100,
      user_id: "user1",
    }

  let before =
    StakeDatum { stakes: [initial_stake], total_stake: 100, total_count: 1 }

  let act = PullStake { user_id: "user1", amount: 100 }

  let after = transition.pull_stake(before, act)

  expect after.total_stake == 0
  expect after.total_count == 0
  expect list.is_empty(after.stakes)
}

test pull_stake_leaves_other_stakes() {
  let stake1 =
    Stake.Record {
      client: "client1",
      provider: "provider1",
      amount: 100,
      user_id: "user1",
    }

  let stake2 =
    Stake.Record {
      client: "client2",
      provider: "provider2",
      amount: 50,
      user_id: "user2",
    }

  let before =
    StakeDatum { stakes: [stake1, stake2], total_stake: 150, total_count: 2 }

  let act = PullStake { user_id: "user1", amount: 40 }

  let after = transition.pull_stake(before, act)

  expect after.total_stake == 110
  expect after.total_count == 2

  expect Some(user1_stake) =
    list.find(after.stakes, fn(s) { s.user_id == "user1" })
  expect Some(user2_stake) =
    list.find(after.stakes, fn(s) { s.user_id == "user2" })

  expect user1_stake.amount == 60
  expect user2_stake.amount == 50
}

test pull_all_stake_single_user() {
  let initial_stake =
    Stake.Record {
      client: "client1",
      provider: "provider1",
      amount: 100,
      user_id: "user1",
    }

  let before =
    StakeDatum { stakes: [initial_stake], total_stake: 100, total_count: 1 }

  let act = PullAllStake { user_id: "user1" }

  let after = transition.pull_all_stake(before, act)

  expect after.total_stake == 0
  expect after.total_count == 0
  expect list.is_empty(after.stakes)
}

test pull_all_stake_multiple_users() {
  let stake1 =
    Stake.Record {
      client: "client1",
      provider: "provider1",
      amount: 100,
      user_id: "user1",
    }

  let stake2 =
    Stake.Record {
      client: "client2",
      provider: "provider2",
      amount: 50,
      user_id: "user2",
    }

  let stake3 =
    Stake.Record {
      client: "client3",
      provider: "provider3",
      amount: 75,
      user_id: "user3",
    }

  let before =
    StakeDatum {
      stakes: [stake1, stake2, stake3],
      total_stake: 225,
      total_count: 3,
    }

  let act = PullAllStake { user_id: "user2" }

  let after = transition.pull_all_stake(before, act)

  expect after.total_stake == 175
  expect after.total_count == 2

  expect None = list.find(after.stakes, fn(s) { s.user_id == "user2" })
  expect Some(user1_stake) =
    list.find(after.stakes, fn(s) { s.user_id == "user1" })
  expect Some(user3_stake) =
    list.find(after.stakes, fn(s) { s.user_id == "user3" })

  expect user1_stake.amount == 100
  expect user3_stake.amount == 75
}

test complex_workflow_scenario() {
  let state0 = StakeDatum { stakes: [], total_stake: 0, total_count: 0 }

  let state1 =
    transition.create_stake(
      state0,
      CreateStake {
        client: "client1",
        provider: "provider1",
        amount: 1000,
        user_id: "user1",
      },
    )
  expect state1.total_stake == 1000
  expect state1.total_count == 1

  let state2 =
    transition.create_stake(
      state1,
      CreateStake {
        client: "client2",
        provider: "provider2",
        amount: 500,
        user_id: "user2",
      },
    )
  expect state2.total_stake == 1500
  expect state2.total_count == 2

  let state3 =
    transition.transfer_stake(
      state2,
      TransferStake { from_user_id: "user1", to_user_id: "user3", amount: 200 },
    )
  expect state3.total_stake == 1500
  expect state3.total_count == 3

  let state4 =
    transition.pull_stake(state3, PullStake { user_id: "user2", amount: 100 })
  expect state4.total_stake == 1400
  expect state4.total_count == 3

  let state5 =
    transition.pull_all_stake(state4, PullAllStake { user_id: "user3" })
  expect state5.total_stake == 1200
  expect state5.total_count == 2

  expect Some(user1_final) =
    list.find(state5.stakes, fn(s) { s.user_id == "user1" })
  expect Some(user2_final) =
    list.find(state5.stakes, fn(s) { s.user_id == "user2" })
  expect None = list.find(state5.stakes, fn(s) { s.user_id == "user3" })

  expect user1_final.amount == 800
  expect user2_final.amount == 400
}
