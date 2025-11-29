import { Lucid } from "lucid-cardano";

async function generateWallet() {
	console.log("🔐 Generating new Cardano wallet...\n");

	const lucid = await Lucid.new(undefined, "Preview");

	const seedPhrase = lucid.utils.generateSeedPhrase();
	console.log("📝 Seed Phrase (24 words):");
	console.log("━".repeat(60));
	console.log(seedPhrase);
	console.log("━".repeat(60));
	console.log("⚠️  SAVE THIS SEED PHRASE SECURELY!\n");

	lucid.selectWalletFromSeed(seedPhrase);

	const address = await lucid.wallet.address();
	console.log("📍 Wallet Address:");
	console.log(address);
	console.log("");


	console.log("💡 To use this wallet in the deploy script:");
	console.log("━".repeat(60));
	console.log("Option 1 (Recommended): Modify index.ts to use seed phrase");
	console.log("  lucid.selectWalletFromSeed(Bun.env.SEED_PHRASE);");
	console.log("");
	console.log(
		"Option 2: Extract private key using cardano-cli or another tool"
	);
	console.log("━".repeat(60));
	console.log("");

	console.log("🪙 Fund this wallet with testnet ADA:");
	console.log("   https://docs.cardano.org/cardano-testnet/tools/faucet/");
	console.log("");
	console.log("✅ Wallet generation complete!");
}

generateWallet().catch(console.error);
