import { expect } from "chai";
import { network } from "hardhat";

const { ethers } = await network.connect();

async function deployAndWait(name: string, args: unknown[] = [], options?: { value?: bigint }) {
  const contract = await ethers.deployContract(name, args, options ?? {});
  await contract.waitForDeployment();
  return contract;
}

describe("Blockchain Security Lab", function () {
  describe("Reentrancy", function () {
    it("drains the vulnerable bank but cannot drain the secured bank", async function () {
      const [owner, victim, attacker] = await ethers.getSigners();

      const vulnerable = await deployAndWait("VulnerableBank");
      await vulnerable.connect(owner).deposit({ value: ethers.parseEther("5") });
      await vulnerable.connect(victim).deposit({ value: ethers.parseEther("5") });

      const exploit = await deployAndWait("ReentrancyAttacker", [await vulnerable.getAddress()], { value: 0n });
      await expect(exploit.connect(attacker).attack({ value: ethers.parseEther("1") })).to.be.revertedWith("not owner");
      await exploit.connect(owner).attack({ value: ethers.parseEther("1") });
      expect(await ethers.provider.getBalance(await vulnerable.getAddress())).to.equal(0n);

      const secure = await deployAndWait("SecureBank");
      await secure.connect(owner).deposit({ value: ethers.parseEther("5") });
      await secure.connect(victim).deposit({ value: ethers.parseEther("5") });
      const blocked = await deployAndWait("ReentrancyAttacker", [await secure.getAddress()]);

      await expect(blocked.connect(owner).attack({ value: ethers.parseEther("1") })).to.be.reverted;
      expect(await ethers.provider.getBalance(await secure.getAddress())).to.equal(ethers.parseEther("10"));
    });
  });

  describe("Access control", function () {
    it("shows unrestricted treasury sweep vs owner-only sweep", async function () {
      const [owner, attacker] = await ethers.getSigners();

      const vulnerable = await deployAndWait("VulnerableTreasury");
      await owner.sendTransaction({ to: await vulnerable.getAddress(), value: ethers.parseEther("2") });
      await vulnerable.connect(attacker).sweep(attacker.address);
      expect(await ethers.provider.getBalance(await vulnerable.getAddress())).to.equal(0n);

      const secure = await deployAndWait("SecureTreasury", [owner.address]);
      await owner.sendTransaction({ to: await secure.getAddress(), value: ethers.parseEther("2") });
      await expect(secure.connect(attacker).sweep(attacker.address)).to.be.reverted;
      expect(await ethers.provider.getBalance(await secure.getAddress())).to.equal(ethers.parseEther("2"));
    });
  });

  describe("tx.origin authorization", function () {
    it("demonstrates phishing through an intermediate contract", async function () {
      const [owner, attacker] = await ethers.getSigners();
      const vulnerable = await deployAndWait("VulnerableTxOriginVault", [], { value: ethers.parseEther("2") });
      const phisher = await deployAndWait("TxOriginPhisher");

      await phisher.connect(owner).phish(await vulnerable.getAddress());
      expect(await ethers.provider.getBalance(await vulnerable.getAddress())).to.equal(0n);
      expect(await ethers.provider.getBalance(await phisher.getAddress())).to.equal(ethers.parseEther("2"));

      const secure = await deployAndWait("SecureAuthorizationVault", [owner.address], { value: ethers.parseEther("2") });
      await expect(secure.connect(attacker).withdrawAll(attacker.address)).to.be.reverted;
      expect(await ethers.provider.getBalance(await secure.getAddress())).to.equal(ethers.parseEther("2"));
    });
  });

  describe("Signature replay", function () {
    it("replays an unscoped signature but rejects a nonce replay", async function () {
      const [signer, user] = await ethers.getSigners();
      const amount = ethers.parseEther("1");

      const vulnerable = await deployAndWait("VulnerableSignedPayout", [signer.address], { value: ethers.parseEther("3") });
      const rawDigest = ethers.keccak256(
        ethers.AbiCoder.defaultAbiCoder().encode(["address", "uint256"], [user.address, amount]),
      );
      const vulnerableSignature = await signer.signMessage(ethers.getBytes(rawDigest));

      await vulnerable.connect(user).claim(amount, vulnerableSignature);
      await vulnerable.connect(user).claim(amount, vulnerableSignature);
      expect(await ethers.provider.getBalance(await vulnerable.getAddress())).to.equal(ethers.parseEther("1"));

      const secure = await deployAndWait("SecureSignedPayout", [signer.address], { value: ethers.parseEther("3") });
      const nonce = 7n;
      const networkInfo = await ethers.provider.getNetwork();
      const secureDigest = ethers.keccak256(
        ethers.AbiCoder.defaultAbiCoder().encode(
          ["address", "uint256", "address", "uint256", "uint256"],
          [await secure.getAddress(), networkInfo.chainId, user.address, amount, nonce],
        ),
      );
      const secureSignature = await signer.signMessage(ethers.getBytes(secureDigest));

      await secure.connect(user).claim(amount, nonce, secureSignature);
      await expect(secure.connect(user).claim(amount, nonce, secureSignature)).to.be.revertedWith("nonce used");
    });
  });

  describe("Unchecked external calls", function () {
    it("shows false success state when a low-level call is ignored", async function () {
      const [owner] = await ethers.getSigners();
      const rejecting = await deployAndWait("RevertingRecipient");

      const vulnerable = await deployAndWait("VulnerableUncheckedPayout");
      await owner.sendTransaction({ to: await vulnerable.getAddress(), value: ethers.parseEther("1") });
      await vulnerable.pay(await rejecting.getAddress(), ethers.parseEther("0.5"));
      expect(await vulnerable.paid(await rejecting.getAddress())).to.equal(true);
      expect(await ethers.provider.getBalance(await vulnerable.getAddress())).to.equal(ethers.parseEther("1"));

      const secure = await deployAndWait("SecureCheckedPayout");
      await owner.sendTransaction({ to: await secure.getAddress(), value: ethers.parseEther("1") });
      await expect(secure.pay(await rejecting.getAddress(), ethers.parseEther("0.5"))).to.be.revertedWith("payment failed");
      expect(await secure.paid(await rejecting.getAddress())).to.equal(false);
    });
  });
});
