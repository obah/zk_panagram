use dep::keccak256::keccak256;

fn main(guess_hash: Field, hashed_answer_hash: pub Field, address: pub Field) {
    //address is added to make each proof unique and avoid collisions

    //to avoid people getting the public answer hash and passing it with a script
    //we hash the answer hash

    let guess_hash_arr: [u8; 32] = guess_hash.to_be_bytes();

    let hashed_guess_hash = keccak256(guess_hash_arr, 32);

    assert(Field::from_be_bytes(hashed_guess_hash) == hashed_answer_hash);
}

// #[test]
// fn test_main() {
//     main(1, 2);

//     // Uncomment to make test fail
//     // main(1, 1);
// }

//to generate verifier.sol contract
//nargo compile -> to get the circuit bytecodes
//bb write_vk --oracle_hash keccak -b ./target/zk_panagram.json -o ./target -> generate verification key
//bb write_solidity_verifier -k ./target/vk -o ./target/Verifier.sol -> generate verifier contract
