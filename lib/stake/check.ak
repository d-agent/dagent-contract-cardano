use aiken/collection/list
use cardano/transaction.{Transaction, OutputReference, InlineDatum, Output}
use stake/types.{StakeDatum, Stake}

pub fn get_own_input(oref: OutputReference, tx: Transaction) {
  expect Some(input) =
    list.find(tx.inputs, fn(i) { i.output_reference == oref })

  input
}

pub fn get_continuing_output(oref: OutputReference, tx: Transaction) {
  let own_input = get_own_input(oref, tx)
  let addr = own_input.output.address

  expect Some(out) =
    list.find(tx.outputs, fn(o) { o.address == addr })

  out
}

pub fn read_datum_from_output(out: Output) -> StakeDatum {
  expect InlineDatum(raw) = out.datum
  expect datum: StakeDatum = raw
  datum
}

pub fn enforce_invariants(d: StakeDatum) {
  let total =
    list.foldr(d.stakes, 0, fn(s: Stake, acc) { acc + s.amount })

  let count =
    list.length(d.stakes)

  expect True = (d.total_stake == total)
  expect True = (d.total_count == count)
}
