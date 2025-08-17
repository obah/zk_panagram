import { Noir } from "@noir-lang/noir_js";
import { ethers } from "ethers";
import { UltraHonkBackend } from "@aztec/bb.js";
import path from "path";
import fs from "fs";

(async () => {
  try {
    const circuitPath = path.resolve(
      __dirname,
      "../../circuits/target/zk_panagram.json"
    );
    const circuit = JSON.parse(fs.readFileSync(circuitPath, "utf-8"));

    const inputsArray = process.argv.slice(2);

    const noir = new Noir(circuit);

    const bb = new UltraHonkBackend(circuit.bytecode, { threads: 1 });

    const inputs = {
      guess_hash: inputsArray[0],
      hashed_answer_hash: inputsArray[1],
      address: inputsArray[2],
    };

    const { witness } = await noir.execute(inputs);

    const originalLog = console.log;
    console.log = () => {};
    const { proof } = await bb.generateProof(witness, { keccak: true });
    console.log = originalLog;

    const proofEncoded = ethers.AbiCoder.defaultAbiCoder().encode(
      ["bytes"],
      [proof]
    );

    process.stdout.write(proofEncoded);
    process.exit(0);
  } catch (error) {
    console.error("DEBUG: Script failed during execution.", error);
    process.exit(1);
  }
})();
