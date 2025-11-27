use cardano/transaction.{OutputReference, Transaction}
use stake/check
use stake/transition
use stake/types.{
  CreateStake, GetAddressStake, GetTotalStake, GetTotalStakeCount, PullAllStake,
  PullStake, StakeActions, StakeDatum, TransferStake,
}

validator stake {
  spend(
    datum: Option<StakeDatum>,
    r: StakeActions,
    oref: OutputReference,
    tx: Transaction,
  ) {
    expect Some(old) = datum

    let out = check.get_continuing_output(oref, tx)
    let new = check.read_datum_from_output(out)

    let expected =
      when r is {
        // add stake to users map
        CreateStake { .. } -> transition.create_stake(old, r)

        // transfer stake between users
        TransferStake { .. } -> transition.transfer_stake(old, r)

        // pull stake from a user
        PullStake { .. } -> transition.pull_stake(old, r)

        // pull all stake from a user
        PullAllStake { .. } -> transition.pull_all_stake(old, r)

        GetAddressStake { address: _ } -> fail

        GetTotalStake -> fail

        GetTotalStakeCount -> fail
      }

    check.enforce_invariants(expected)

    expect new == expected

    True
  }

  else(_) {
    fail
  }
}
