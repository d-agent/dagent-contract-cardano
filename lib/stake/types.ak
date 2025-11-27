pub type Stake {
  Record {
    client: ByteArray,
    provider: ByteArray,
    amount: Int,
    userId: ByteArray
  }
}

pub type StakeDatum {
  stakes: List<Stake>,
  total_stake: Int,
  total_count: Int,
}

pub type StakeActions {
  CreateStake { client: ByteArray, provider: ByteArray, amount: Int, userId: ByteArray }
  TransferStake { from_userId: ByteArray, to_userId: ByteArray, amount: Int }
  PullStake { userId: ByteArray, amount: Int }
  GetAddressStake { address: ByteArray }
  PullAllStake { userId: ByteArray }
  GetTotalStake
  GetTotalStakeCount
}