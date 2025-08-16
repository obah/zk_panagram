fn main(guess_hash: Field, answer_hash: pub Field, address: pub Field) {
    //address is added to make each proof unique and avoid collisions

    assert(guess_hash == answer_hash);
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
