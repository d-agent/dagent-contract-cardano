pub type Stake {
  Record {
    client: ByteArray,
    provider: ByteArray,
    amount: Int,
    user_id: ByteArray,
  }
}

pub type StakeDatum {
  stakes: List<Stake>,
  total_stake: Int,
  total_count: Int,
}

pub type StakeActions {
  CreateStake {
    client: ByteArray,
    provider: ByteArray,
    amount: Int,
    user_id: ByteArray,
  }
  TransferStake { from_user_id: ByteArray, to_user_id: ByteArray, amount: Int }
  PullStake { user_id: ByteArray, amount: Int }
  GetAddressStake { address: ByteArray }
  PullAllStake { user_id: ByteArray }
  GetTotalStake
  GetTotalStakeCount
}
