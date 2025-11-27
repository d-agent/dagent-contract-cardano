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

pub fn create_stake(old: StakeDatum, act: StakeActions) -> StakeDatum {
  expect CreateStake { client, provider, amount, userId } = act
  expect amount > 0

  let new_stake = Stake.Record { client, provider, amount, userId }

  let new_stakes = [new_stake, ..old.stakes]

  recalc_state(new_stakes)
}

pub fn transfer_stake(old: StakeDatum, act: StakeActions) -> StakeDatum {
  expect TransferStake { from_userId, to_userId, amount } = act
  expect amount > 0

  expect Some(from_stake) =
    list.find(old.stakes, fn(s) { s.userId == from_userId })

  expect from_stake.amount >= amount

  let to_opt = list.find(old.stakes, fn(s) { s.userId == to_userId })

  let base =
    list.filter(
      old.stakes,
      fn(s) { s.userId != from_userId && s.userId != to_userId },
    )

  let updated_from =
    Stake.Record {
      client: from_stake.client,
      provider: from_stake.provider,
      amount: from_stake.amount - amount,
      userId: from_stake.userId,
    }

  let new_stakes =
    when to_opt is {
      Some(to_stake) ->
        if updated_from.amount > 0 {
          [
            updated_from,
            Stake.Record {
              client: to_stake.client,
              provider: to_stake.provider,
              amount: to_stake.amount + amount,
              userId: to_stake.userId,
            },
            ..base
          ]
        } else {
          [
            Stake.Record {
              client: to_stake.client,
              provider: to_stake.provider,
              amount: to_stake.amount + amount,
              userId: to_stake.userId,
            },
            ..base
          ]
        }

      None ->
        if updated_from.amount > 0 {
          [
            updated_from,
            Stake.Record {
              client: from_stake.client,
              provider: from_stake.provider,
              amount,
              userId: to_userId,
            },
            ..base
          ]
        } else {
          [
            Stake.Record {
              client: from_stake.client,
              provider: from_stake.provider,
              amount,
              userId: to_userId,
            },
            ..base
          ]
        }
    }

  recalc_state(new_stakes)
}

pub fn pull_stake(old: StakeDatum, act: StakeActions) -> StakeDatum {
  expect PullStake { userId, amount } = act
  expect amount > 0

  expect Some(stake) = list.find(old.stakes, fn(s) { s.userId == userId })

  expect amount <= stake.amount

  let updated =
    Stake.Record {
      client: stake.client,
      provider: stake.provider,
      amount: stake.amount - amount,
      userId: stake.userId,
    }

  let without = list.filter(old.stakes, fn(s) { s.userId != userId })

  let new_stakes =
    if updated.amount > 0 {
      [updated, ..without]
    } else {
      without
    }

  recalc_state(new_stakes)
}

pub fn pull_all_stake(old: StakeDatum, act: StakeActions) -> StakeDatum {
  expect PullAllStake { userId } = act

  expect Some(_stake) = list.find(old.stakes, fn(s) { s.userId == userId })

  let new_stakes = list.filter(old.stakes, fn(s) { s.userId != userId })

  recalc_state(new_stakes)
}
