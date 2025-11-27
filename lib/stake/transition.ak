use aiken/collection/list
use stake/types.{
  CreateStake, PullAllStake, PullStake, Stake, StakeActions, StakeDatum,
  TransferStake,
}

fn sum_amounts(stakes: List<Stake>) -> Int {
  list.foldr(stakes, 0, fn(s: Stake, acc) { acc + s.amount })
}

fn recalc_state(stakes: List<Stake>) -> StakeDatum {
  let total = sum_amounts(stakes)
  let count = list.length(stakes)

  StakeDatum { stakes, total_stake: total, total_count: count }
}

// Helper type for single-pass list traversal in transfer_stake
type TransferAccumulator {
  from_stake: Option<Stake>,
  to_stake: Option<Stake>,
  base: List<Stake>,
}

pub fn create_stake(old: StakeDatum, act: StakeActions) -> StakeDatum {
  expect CreateStake { client, provider, amount, user_id } = act
  expect amount > 0

  let new_stake = Stake.Record { client, provider, amount, user_id }

  let new_stakes = [new_stake, ..old.stakes]

  recalc_state(new_stakes)
}

pub fn transfer_stake(old: StakeDatum, act: StakeActions) -> StakeDatum {
  expect TransferStake { from_user_id, to_user_id, amount } = act
  expect amount > 0

  // Single-pass optimization: find both stakes and build base list in one traversal
  let acc =
    list.foldr(
      old.stakes,
      TransferAccumulator { from_stake: None, to_stake: None, base: [] },
      fn(s: Stake, acc: TransferAccumulator) {
        if s.user_id == from_user_id {
          TransferAccumulator { ..acc, from_stake: Some(s) }
        } else if s.user_id == to_user_id {
          TransferAccumulator { ..acc, to_stake: Some(s) }
        } else {
          TransferAccumulator { ..acc, base: [s, ..acc.base] }
        }
      },
    )

  expect Some(from_stake) = acc.from_stake
  expect from_stake.amount >= amount

  let updated_from =
    Stake.Record {
      client: from_stake.client,
      provider: from_stake.provider,
      amount: from_stake.amount - amount,
      user_id: from_stake.user_id,
    }

  // Build the updated_to stake - either updating existing or creating new
  let updated_to =
    when acc.to_stake is {
      Some(to_stake) ->
        Stake.Record {
          client: to_stake.client,
          provider: to_stake.provider,
          amount: to_stake.amount + amount,
          user_id: to_stake.user_id,
        }
      None ->
        Stake.Record {
          client: from_stake.client,
          provider: from_stake.provider,
          amount,
          user_id: to_user_id,
        }
    }

  // Build final stakes list based on whether from_stake has remaining balance
  let new_stakes =
    if updated_from.amount > 0 {
      [updated_from, updated_to, ..acc.base]
    } else {
      [updated_to, ..acc.base]
    }

  recalc_state(new_stakes)
}

pub fn pull_stake(old: StakeDatum, act: StakeActions) -> StakeDatum {
  expect PullStake { user_id, amount } = act
  expect amount > 0

  expect Some(stake) = list.find(old.stakes, fn(s) { s.user_id == user_id })

  expect amount <= stake.amount

  let updated =
    Stake.Record {
      client: stake.client,
      provider: stake.provider,
      amount: stake.amount - amount,
      user_id: stake.user_id,
    }

  let without = list.filter(old.stakes, fn(s) { s.user_id != user_id })

  let new_stakes =
    if updated.amount > 0 {
      [updated, ..without]
    } else {
      without
    }

  recalc_state(new_stakes)
}

pub fn pull_all_stake(old: StakeDatum, act: StakeActions) -> StakeDatum {
  expect PullAllStake { user_id } = act

  expect Some(_stake) = list.find(old.stakes, fn(s) { s.user_id == user_id })

  let new_stakes = list.filter(old.stakes, fn(s) { s.user_id != user_id })

  recalc_state(new_stakes)
}
