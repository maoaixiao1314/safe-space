import "@nomiclabs/hardhat-ethers";
import type { HardhatUserConfig, HttpNetworkUserConfig } from "hardhat/types";
import "@nomiclabs/hardhat-etherscan";
import "@nomiclabs/hardhat-waffle";
import "solidity-coverage";
import "hardhat-deploy";
import dotenv from "dotenv";
import yargs from "yargs";
import { getSingletonFactoryInfo } from "@gnosis.pm/safe-singleton-factory";

const argv = yargs
    .option("network", {
        type: "string",
        default: "hardhat",
    })
    .help(false)
    .version(false).argv;

// Load environment variables.
dotenv.config();
const { NODE_URL, INFURA_KEY, MNEMONIC, ETHERSCAN_API_KEY, PK, SOLIDITY_VERSION, SOLIDITY_SETTINGS } = process.env;

const DEFAULT_MNEMONIC = "candy maple cake sugar pudding cream honey rich smooth crumble sweet treat";

const sharedNetworkConfig: HttpNetworkUserConfig = {};
if (PK) {
    sharedNetworkConfig.accounts = [PK];
} else {
    sharedNetworkConfig.accounts = {
        mnemonic: MNEMONIC || DEFAULT_MNEMONIC,
    };
}

if (["mainnet", "rinkeby", "kovan", "goerli", "ropsten", "mumbai", "polygon"].includes(argv.network) && INFURA_KEY === undefined) {
    throw new Error(`Could not find Infura key in env, unable to connect to network ${argv.network}`);
}

import "./src/tasks/local_verify";
import "./src/tasks/deploy_contracts";
import "./src/tasks/show_codesize";
import { BigNumber } from "@ethersproject/bignumber";
import { DeterministicDeploymentInfo } from "hardhat-deploy/dist/types";

const primarySolidityVersion = SOLIDITY_VERSION || "0.7.6";
const soliditySettings = SOLIDITY_SETTINGS ? JSON.parse(SOLIDITY_SETTINGS) : undefined;

const deterministicDeployment = (network: string): DeterministicDeploymentInfo | undefined => {
    const info = getSingletonFactoryInfo(parseInt(network));
    if (!info) {
        // Return undefined to skip deterministic deployment for networks without factory
        // This is expected for custom chains like Hetu
        console.log(`Note: Deterministic deployment not available for network ${network}. Using standard deployment.`);
        return undefined;
    }
    return {
        factory: info.address,
        deployer: info.signerAddress,
        funding: BigNumber.from(info.gasLimit).mul(BigNumber.from(info.gasPrice)).toString(),
        signedTx: info.transaction,
    };
};

const userConfig: HardhatUserConfig = {
    paths: {
        artifacts: "build/artifacts",
        cache: "build/cache",
        deploy: "src/deploy",
        sources: "contracts",
    },
    solidity: {
        compilers: [{ version: primarySolidityVersion, settings: soliditySettings }, { version: "0.6.12" }, { version: "0.5.17" }],
    },
    networks: {
        hardhat: {
            allowUnlimitedContractSize: true,
            blockGasLimit: 100000000,
            gas: 100000000,
        },
        mainnet: {
            ...sharedNetworkConfig,
            url: `https://mainnet.infura.io/v3/${INFURA_KEY}`,
        },
        gnosis: {
            ...sharedNetworkConfig,
            url: "https://rpc.gnosischain.com",
        },
        ewc: {
            ...sharedNetworkConfig,
            url: `https://rpc.energyweb.org`,
        },
        goerli: {
            ...sharedNetworkConfig,
            url: `https://goerli.infura.io/v3/${INFURA_KEY}`,
        },
        mumbai: {
            ...sharedNetworkConfig,
            url: `https://polygon-mumbai.infura.io/v3/${INFURA_KEY}`,
        },
        polygon: {
            ...sharedNetworkConfig,
            url: `https://polygon-mainnet.infura.io/v3/${INFURA_KEY}`,
        },
        volta: {
            ...sharedNetworkConfig,
            url: `https://volta-rpc.energyweb.org`,
        },
        bsc: {
            ...sharedNetworkConfig,
            url: `https://bsc-dataseed.binance.org/`,
        },
        arbitrum: {
            ...sharedNetworkConfig,
            url: `https://arb1.arbitrum.io/rpc`,
        },
        fantomTestnet: {
            ...sharedNetworkConfig,
            url: `https://rpc.testnet.fantom.network/`,
        },
        avalanche: {
            ...sharedNetworkConfig,
            url: `https://api.avax.network/ext/bc/C/rpc`,
        },
        "hetu-mainnet": {
            ...sharedNetworkConfig,
            url: `https://rpc.v1.hetu.org`,
            chainId: 560000,
        },
        "hetu-testnet": {
            ...sharedNetworkConfig,
            url: `http://161.97.161.133:18545`,
            chainId: 565000,
        },
        // Deprecated: keep for backward compatibility
        hetu: {
            ...sharedNetworkConfig,
            url: `http://161.97.161.133:18545`,
            chainId: 565000,
        },
    },
    // Disable deterministic deployment for custom networks that don't support legacy transactions
    deterministicDeployment: (network: string) => {
        // Only use deterministic deployment for known networks
        if (["mainnet", "goerli", "polygon", "mumbai", "gnosis", "bsc", "arbitrum", "avalanche"].includes(network)) {
            return deterministicDeployment(network);
        }
        // For custom networks like Hetu, return undefined to skip deterministic deployment
        return undefined;
    },
    namedAccounts: {
        deployer: 0,
    },
    mocha: {
        timeout: 2000000,
    },
    etherscan: {
        apiKey: ETHERSCAN_API_KEY,
    },
};
if (NODE_URL) {
    userConfig.networks!.custom = {
        ...sharedNetworkConfig,
        url: NODE_URL,
    };
}

// Override deterministicDeployment to always return undefined for custom network
const originalDeterministicDeployment = userConfig.deterministicDeployment;
userConfig.deterministicDeployment = (network: string) => {
    if (network === "custom" || network === "hetu" || network === "hetu-mainnet" || network === "hetu-testnet" || network === "560000" || network === "565000") {
        // Always skip deterministic deployment for Hetu chains
        return undefined;
    }
    if (typeof originalDeterministicDeployment === "function") {
        return originalDeterministicDeployment(network);
    }
    return undefined;
};

export default userConfig;
