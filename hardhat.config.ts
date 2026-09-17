import hardhatToolboxMochaEthersPlugin from "@nomicfoundation/hardhat-toolbox-mocha-ethers";
import { defineConfig } from "hardhat/config";

export default defineConfig({
  plugins: [hardhatToolboxMochaEthersPlugin],
  solidity: {
    version: "0.8.37",
    settings: {
      optimizer: {
        enabled: true,
        runs: 200,
      },
    },
  },
  test: {
    mocha: {
      timeout: 40_000,
    },
  },
});
