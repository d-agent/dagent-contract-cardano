use stake/types.{StakeDatum, StakeActions, CreateStake, TransferStake, PullStake, PullAllStake, GetAddressStake, GetTotalStake, GetTotalStakeCount}
use cardano/transaction.{Transaction, OutputReference}
use stake/transition
use stake/check

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
        CreateStake { client, provider, amount, userId } ->
          transition.create_stake(old, CreateStake { client: client, provider: provider, amount: amount, userId: userId })

        // transfer stake between users
        TransferStake { from_userId, to_userId, amount } ->
          transition.transfer_stake(old, TransferStake { from_userId: from_userId, to_userId: to_userId, amount: amount })

        // pull stake from a user
        PullStake { userId, amount } ->
          transition.pull_stake(old, PullStake { userId: userId, amount: amount })

        // pull all stake from a user
        PullAllStake { userId } ->
          transition.pull_all_stake(old, PullAllStake { userId: userId })

        // query total stake for an address
        GetAddressStake { address: _address } ->
          // - import aiken/list
          // - add an expect that some stake matches the address
          old

        // query total stake amount
        GetTotalStake ->
          old

        // query total stake count
        GetTotalStakeCount ->
          old
      }

  check.enforce_invariants(expected)

    expect True = (new == expected)

    True
  }
}
