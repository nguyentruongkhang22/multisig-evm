import { ethers } from "hardhat";
import { MultiSigWallet, MultiSigWallet__factory } from "../typechain-types";

describe("Wallet", function () {
  // We define a fixture to reuse the same setup in every test.
  // We use loadFixture to run this setup once, snapshot that state,
  // and reset Hardhat Network to that snapshot in every test.
  let WalletFactory: MultiSigWallet__factory;
  let wallet: MultiSigWallet;
  let defaultAccount: any;
  this.beforeAll(async function () {
    [defaultAccount] = await ethers.getSigners();
    WalletFactory = await ethers.getContractFactory("MultiSigWallet");
    wallet = await WalletFactory.deploy(
      10,
      [ethers.constants.AddressZero],
      1000000
    );
  });

  it("Should deploy", async function () {
    wallet
      .connect(defaultAccount)
      .createTransaction(1, ethers.constants.HashZero);
  });
});
