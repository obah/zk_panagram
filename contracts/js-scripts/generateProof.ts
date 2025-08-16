// import { Noir } from "@noir-lang/noir_js";
// import { ethers } from "ethers";
// import { UltraHonkBackend } from "@aztec/bb.js";
// import path from "path";
// import fs from "fs";

// //get the circuit file
// const circuitPath = path.resolve(
//   __dirname,
//   "../../circuits/target/zk_panagram.json"
// );
// const circuit = JSON.parse(fs.readFileSync(circuitPath, "utf-8"));

// export default async function generateProof() {
//   const inputsArray = process.argv.slice(2);

//   try {
//     //init noir with circuit
//     const noir = new Noir(circuit);

//     //init backend with circuit bytecode
//     const bb = new UltraHonkBackend(circuit.bytecode, { threads: 1 });

//     //create input
//     const inputs = {
//       //private inputs
//       guess_hash: inputsArray[0],
//       //public inputs
//       answer_hash: inputsArray[1],
//     };

//     //execute the circuit with inputs to create witness
//     const { witness } = await noir.execute(inputs);

//     //generate the proof with the backend using witness
//     const originalLog = console.log;
//     console.log = () => {}; // Suppress output from the backend
//     const { proof } = await bb.generateProof(witness, { keccak: true });
//     console.log = originalLog; // Restore the original console.log

//     //ABI encode the proof to return it in a format compatible with smart contracts
//     const proofEncoded = ethers.AbiCoder.defaultAbiCoder().encode(
//       ["bytes"],
//       [proof]
//     );

//     //return the proof
//     return proofEncoded;
//   } catch (error) {
//     console.error("Error generating proof:", error);
//     throw error;
//   }
// }

// (async () => {
//   generateProof()
//     .then((proof) => {
//       process.stdout.write(proof);
//       process.exit(0);
//     })
//     .catch((error) => {
//       console.error("Error:", error);
//       process.exit(1);
//     });
// })();

//generateProof.ts with debug logs

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
      answer_hash: inputsArray[1],
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
