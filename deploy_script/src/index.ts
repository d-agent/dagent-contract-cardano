import {
  Blockfrost,
  Data,
  Lucid,
} from "lucid-cardano";
import plutus from "../../plutus.json" with { type: "json" };

async function deployContract() {
  try {
    const blockfrostProjectID = Bun.env.BLOCKFROST_PROJECT_ID;
    const privateKey = Bun.env.PRIVATE_KEY;
    const seedPhrase = Bun.env.SEED_PHRASE;

    if (!blockfrostProjectID) {
      throw new Error("BLOCKFROST_PROJECT_ID environment variable is required");
    }

    if (!privateKey && !seedPhrase) {
      throw new Error(
        "Either PRIVATE_KEY or SEED_PHRASE environment variable is required.\n" +
        "Run 'bun run generate-wallet.ts' to create a new wallet."
      );
    }

    console.log("🚀 Initializing Lucid on Cardano Preview...");
    
    const lucid = await Lucid.new(
      new Blockfrost(
        "https://cardano-preview.blockfrost.io/api/v0/",
        blockfrostProjectID,
      ),
      "Preview",
    );

    console.log("✅ Lucid initialized successfully");

    console.log("🔑 Selecting wallet...");

    if (seedPhrase) {
      console.log("   Using seed phrase...");
      lucid.selectWalletFromSeed(seedPhrase);
    } else if (privateKey) {
      console.log("   Using private key...");
      
      if (privateKey.length === 450 || privateKey.startsWith('xprv')) {
        throw new Error(
          `❌ Your PRIVATE_KEY appears to be in Bech32 format (xprv...).\n\n` +
          `Lucid doesn't support this format directly. Please use one of these options:\n\n` +
          `Option 1 (RECOMMENDED): Use your seed phrase instead:\n` +
          `  - Remove PRIVATE_KEY from .env\n` +
          `  - Add: SEED_PHRASE=your 24 word mnemonic phrase\n\n` +
          `Option 2: Generate a new wallet:\n` +
          `  - Run: bun run generate-wallet.ts\n` +
          `  - Copy the seed phrase to your .env file\n\n` +
          `Option 3: If you don't have the seed phrase, you'll need to:\n` +
          `  - Export your seed phrase from your wallet (Nami, Eternl, etc.)\n` +
          `  - OR create a new wallet using generate-wallet.ts`
        );
      }
      
      if (privateKey.length !== 64 && privateKey.length !== 128) {
        throw new Error(
          `❌ Invalid private key format.\n\n` +
          `Expected: Hex string (64 or 128 characters)\n` +
          `Received: ${privateKey.length} characters\n\n` +
          `Your key format is not supported. Please use SEED_PHRASE instead:\n` +
          `  1. Remove PRIVATE_KEY from .env\n` +
          `  2. Add your 24-word seed phrase:\n` +
          `     SEED_PHRASE=word1 word2 word3 ... word24\n\n` +
          `Need a new wallet? Run: bun run generate-wallet.ts`
        );
      }
      
      try {
        lucid.selectWalletFromPrivateKey(privateKey);
      } catch (error) {
        throw new Error(
          `❌ Failed to load private key.\n\n` +
          `The private key format is invalid or corrupted.\n\n` +
          `RECOMMENDED SOLUTION: Use SEED_PHRASE instead of PRIVATE_KEY\n` +
          `  1. Edit your .env file\n` +
          `  2. Remove or comment out PRIVATE_KEY\n` +
          `  3. Add: SEED_PHRASE=your 24 word mnemonic phrase\n\n` +
          `Original error: ${error instanceof Error ? error.message : String(error)}`
        );
      }
    }
    
    const walletAddress = await lucid.wallet.address();
    console.log("📍 Wallet Address:", walletAddress);

    console.log("� Checking wallet balance...");
    
    const utxos = await lucid.wallet.getUtxos();
    
    let totalLovelace = 0n;
    for (const utxo of utxos) {
      const lovelaceValue = utxo.assets.lovelace;
      if (lovelaceValue !== undefined && lovelaceValue !== null) {
        totalLovelace += typeof lovelaceValue === 'bigint' ? lovelaceValue : BigInt(lovelaceValue);
      }
    }
    
    console.log(`   Balance: ${Number(totalLovelace) / 1_000_000} ADA`);

    if (totalLovelace < 3_000_000n) {
      throw new Error("Insufficient funds. You need at least 3 ADA (2 ADA + fees)");
    }

    const validator = plutus.validators[0];
    if (!validator) {
      throw new Error("No validator found in plutus.json");
    }

    console.log("📜 Validator loaded:", validator.title);

    const contractAddress = lucid.utils.validatorToAddress({
      type: "PlutusV2",
      script: validator.compiledCode,
    });

    console.log("📍 Contract Address:", contractAddress);

    const datum = Data.void();

    console.log("🔨 Building transaction...");

    const tx = await lucid
      .newTx()
      .payToContract(
        contractAddress,
        { inline: datum },
        { lovelace: BigInt(2_000_000) }
      )
      .complete();

    console.log("✍️  Signing transaction...");
    const signedTx = await tx.sign().complete();

    console.log("📤 Submitting transaction...");
    const txHash = await signedTx.submit();

    console.log("✅ Transaction submitted successfully!");
    console.log("🔗 Transaction Hash:", txHash);
    console.log(`🔍 View on Cardano Explorer: https://preprod.cardanoscan.io/transaction/${txHash}`);

    console.log("⏳ Waiting for confirmation...");
    await lucid.awaitTx(txHash);
    
    console.log("✨ Transaction confirmed!");
    console.log("🎉 Contract deployment successful!");

  } catch (error) {
    console.error("❌ Error deploying contract:");
    if (error instanceof Error) {
      console.error(error.message);
      if (error.stack) {
        console.error("\nStack trace:");
        console.error(error.stack);
      }
    } else {
      console.error(error);
    }
    process.exit(1);
  }
}

deployContract();