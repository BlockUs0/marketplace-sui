import { Ed25519Keypair } from "@mysten/sui/keypairs/ed25519";
import { Transaction } from "@mysten/sui/transactions";
import { getFullnodeUrl, SuiClient } from "@mysten/sui/client";

// Wallet already funded and with NFTs.
// 0x68d4e9ea2352309880fc304bdd4ac67b71f9d96b85c86f530b5f9f0c1d0a2036
const MNEMONIC =
  "badge join typical clap match try depend sudden obtain eager faint inform";

const PACKAGE =
  "0x5301a9c959e102f01dfb75c2f82f077a7a12ae93ceb59b64e8e053593484af08";

const MARKETPLACE =
  "0x0350957be489a5fd37c9247dc10000d94de020c6bce04956ad57020810329b83";

const POLICY =
  "0x07d071d7d44341991ce93d2737552251c8fb6a988dbbbf910a3d2b6ac2430c4a";

const ITEM =
  "0x8fd0b79e30468495f5a2d5869402e395dd894f16e15a281908731fea3bc3bf1f";

const KIOSK = ""; // This should be obtained in the list digest.

const KIOSK_CAP = ""; // This should be obtained in the list digest.

if (!MNEMONIC) throw new Error("No mnemonic phrase found.");

const keyPair = Ed25519Keypair.deriveKeypair(MNEMONIC);

console.log(keyPair.toSuiAddress());

const rpcUrl = getFullnodeUrl("testnet");
const client = new SuiClient({ url: rpcUrl });

const getItemType = async (itemId: string) => {
  const rsp = await client.getObject({
    id: itemId,
    options: { showType: true },
  });
  const type = rsp.data?.type;

  if (!type) throw new Error("Type not found.");

  return type;
};

const list = async (itemId: string, price: bigint) => {
  const itemType = await getItemType(itemId);
  const tx = new Transaction();
  tx.moveCall({
    package: PACKAGE,
    module: "marketplace_fixed_trade",
    function: "list",
    typeArguments: [itemType],
    arguments: [tx.object(itemId), tx.pure.u64(price)],
  });

  const execution = await client.signAndExecuteTransaction({
    transaction: tx,
    signer: keyPair,
    options: { showEffects: true, showObjectChanges: true, showEvents: true },
  });

  console.log(execution);

  return execution;
};

const delist = async (
  kioskId: string,
  kioskOwnerCapId: string,
  itemId: string
) => {
  const itemType = await getItemType(itemId);
  const tx = new Transaction();
  tx.moveCall({
    package: PACKAGE,
    module: "marketplace_fixed_trade",
    function: "delist",
    typeArguments: [itemType],
    arguments: [
      tx.object(kioskId),
      tx.object(kioskOwnerCapId),
      tx.pure.id(itemId),
    ],
  });

  const execution = await client.signAndExecuteTransaction({
    transaction: tx,
    signer: keyPair,
    options: { showEffects: true, showObjectChanges: true, showEvents: true },
  });

  console.log(execution);

  return execution;
};

const purchase = async (kioskId: string, itemId: string) => {
  const itemType = await getItemType(itemId);
  const tx = new Transaction();

  const [, , totalPrice] = tx.moveCall({
    package: PACKAGE,
    module: "marketplace_fixed_trade",
    function: "calculate_fee",
    typeArguments: [itemType],
    arguments: [tx.object(kioskId), tx.object(MARKETPLACE), tx.pure.id(itemId)],
  });

  const [coin] = tx.splitCoins(tx.gas, [totalPrice]);

  const [item, request] = tx.moveCall({
    package: PACKAGE,
    module: "marketplace_fixed_trade",
    function: "purchase",
    typeArguments: [itemType],
    arguments: [
      tx.object(kioskId),
      tx.pure.id(itemId),
      coin,
      tx.object(MARKETPLACE),
      tx.pure.address(keyPair.toSuiAddress()),
    ],
  });

  tx.moveCall({
    package: "0x2",
    module: "transfer_policy",
    function: "confirm_request",
    typeArguments: [itemType],
    arguments: [tx.object(POLICY), request],
  });

  tx.transferObjects([item], keyPair.toSuiAddress());

  const execution = await client.signAndExecuteTransaction({
    transaction: tx,
    signer: keyPair,
    options: { showEffects: true, showObjectChanges: true, showEvents: true },
  });

  console.log(execution);

  return execution;
};

// list(ITEM, 20000000n);

// delist(KIOSK, KIOSK_CAP, ITEM);

// purchase(KIOSK, ITEM);
