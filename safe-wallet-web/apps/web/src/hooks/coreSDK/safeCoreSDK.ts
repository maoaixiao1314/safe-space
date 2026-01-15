import chains from '@safe-global/utils/config/chains'
import { getSafeL2SingletonDeployments, getSafeSingletonDeployments } from '@safe-global/safe-deployments'
import ExternalStore from '@safe-global/utils/services/ExternalStore'
import { Gnosis_safe__factory } from '@safe-global/utils/types/contracts'
import Safe, { type ContractNetworksConfig } from '@safe-global/protocol-kit'
import { isValidMasterCopy } from '@safe-global/utils/services/contracts/safeContracts'
import { isPredictedSafeProps, isReplayedSafeProps } from '@/features/counterfactual/utils'
import { isLegacyVersion } from '@safe-global/utils/services/contracts/utils'
import { isInDeployments } from '@safe-global/utils/hooks/coreSDK/utils'
import type { SafeCoreSDKProps } from '@safe-global/utils/hooks/coreSDK/types'
import { keccak256 } from 'ethers'
import {
  getL2MasterCopyVersionByCodeHash,
  isL2MasterCopyCodeHash,
} from '@safe-global/utils/services/contracts/deployments'
import { logError, Errors } from '@/services/exceptions'
import { isHetuChain, HETU_MAINNET_CHAIN_ID, HETU_TESTNET_CHAIN_ID } from '@/utils/chains'

// Safe Core SDK
export const initSafeSDK = async ({
  provider,
  chainId,
  address,
  version,
  implementationVersionState,
  implementation,
  undeployedSafe,
}: SafeCoreSDKProps): Promise<Safe | undefined> => {
  const providerNetwork = (await provider.getNetwork()).chainId
  if (providerNetwork !== BigInt(chainId)) {
    return
  }

  let safeVersion = version ?? (await Gnosis_safe__factory.connect(address, provider).VERSION())
  let isL1SafeSingleton = chainId === chains.eth
  let contractNetworks: ContractNetworksConfig | undefined

  // Hetu chains (mainnet 560000 and testnet 565000) are not in official deployments
  // Even though implementationVersionState is UP_TO_DATE, we need to provide contract addresses
  // ✅ Updated to use SafeL2 singleton for proper L2 mode event indexing
  if (isHetuChain(chainId)) {
    // Contract addresses are different for mainnet and testnet
    // They depend on deployer address and nonce at deployment time
    if (chainId === HETU_MAINNET_CHAIN_ID) {
      // Hetu Mainnet (560000) contract addresses
      contractNetworks = {
        [chainId]: {
          safeSingletonAddress: '0x26B06FBdBDc84Ae740b4Ed3c9A2588Bd63Da3582',
          safeProxyFactoryAddress: '0x0b09bda80A011073ea460A352ec9396D8C683902',
          multiSendAddress: '0x87405963a42c8B078Cc15ced44b8d44BD23f1c3B',
          multiSendCallOnlyAddress: '0xC39A8220Ac4EAA811E4378663322Ec64396De0c5',
          fallbackHandlerAddress: '0xa1d7792Fdd620246330383868e811916Ef3d0ba5',
          signMessageLibAddress: '0x33AE7D25F283fc461Ae5713774D579faf935D8B7',
          createCallAddress: '0xdAa7CB84cFf22481306b079088716013bf69A0a5',
          simulateTxAccessorAddress: '0xd2dBE2ec98A60Da8f33159314dF11EAF8d7E08Ba',
        },
      }
    } else if (chainId === HETU_TESTNET_CHAIN_ID) {
      // Hetu Testnet (565000) contract addresses
      contractNetworks = {
        [chainId]: {
          safeSingletonAddress: '0x279caD2eA77c124e5c65091333E9c3FfE1ee5aCf',
          safeProxyFactoryAddress: '0xa812FaE86c9d12E90daaD723BDb45e2bd7C6768B',
          multiSendAddress: '0x3c6449611F1Fc8d9Fa1b31518dDa905e21964708',
          multiSendCallOnlyAddress: '0xd3199A49C2889F8742b4A5Dcd79FfCf6F334Fd0a',
          fallbackHandlerAddress: '0x18124e6926F529cd7B994704d2BF4ed6FCbB9d6C',
          signMessageLibAddress: '0x5671A4892a43b47d3534f4423f96F53f59Ae18BD',
          createCallAddress: '0x9a120428267Cfa508087cca498610237174221c5',
          simulateTxAccessorAddress: '0x62fBfdD30c4E8820e4aaf07C8957a361dfaAdecB',
        },
      }
    }
    isL1SafeSingleton = false // SafeL2, not L1
    safeVersion = version || '1.4.1'
  }

  // For Hetu chains, skip the official deployment check since we provide custom contractNetworks
  // If it is an official deployment we should still initiate the safeSDK
  if (!isHetuChain(chainId) && !isValidMasterCopy(implementationVersionState)) {
    const masterCopy = implementation

    const safeL1Deployment = getSafeSingletonDeployments({ network: chainId, version: safeVersion })
    const safeL2Deployment = getSafeL2SingletonDeployments({ network: chainId, version: safeVersion })

    isL1SafeSingleton = isInDeployments(masterCopy, safeL1Deployment?.networkAddresses[chainId])
    const isL2SafeMasterCopy = isInDeployments(masterCopy, safeL2Deployment?.networkAddresses[chainId])

    if (!isL1SafeSingleton && !isL2SafeMasterCopy) {
      try {
        const code = await provider.getCode(masterCopy)

        if (code && code !== '0x') {
          const codeHash = keccak256(code)
          const isUpgradeableL2MasterCopy = isL2MasterCopyCodeHash(codeHash)

          if (isUpgradeableL2MasterCopy) {
            const upgradeableVersion = getL2MasterCopyVersionByCodeHash(codeHash)

            if (upgradeableVersion) {
              // Use the custom mastercopy address with the SDK
              contractNetworks = {
                [chainId]: {
                  safeSingletonAddress: masterCopy,
                },
              }

              safeVersion = upgradeableVersion
              isL1SafeSingleton = false
            } else {
              console.warn(`[SafeSDK] Could not determine version for L2 mastercopy at ${masterCopy}`)
            }
          } else {
            console.warn(`[SafeSDK] Mastercopy at ${masterCopy} is not a recognized L2 mastercopy`)
          }
        } else {
          console.warn(`[SafeSDK] No bytecode found for mastercopy at ${masterCopy}`)
        }
      } catch (error) {
        logError(Errors._808, error)
      }
    }

    if (isL2SafeMasterCopy) {
      isL1SafeSingleton = false
    }
  }
  // Legacy Safe contracts
  if (isLegacyVersion(safeVersion)) {
    isL1SafeSingleton = true
  }

  if (undeployedSafe) {
    if (isPredictedSafeProps(undeployedSafe.props) || isReplayedSafeProps(undeployedSafe.props)) {
      return Safe.init({
        provider: provider._getConnection().url,
        isL1SafeSingleton,
        ...(contractNetworks ? { contractNetworks } : {}),
        predictedSafe: undeployedSafe.props,
      })
    }
    // We cannot initialize a Core SDK for replayed Safes yet.
    return
  }

  return Safe.init({
    provider: provider._getConnection().url,
    safeAddress: address,
    isL1SafeSingleton,
    ...(contractNetworks ? { contractNetworks } : {}),
  })
}

export const {
  getStore: getSafeSDK,
  setStore: setSafeSDK,
  useStore: useSafeSDK,
} = new ExternalStore<Safe | undefined>()
