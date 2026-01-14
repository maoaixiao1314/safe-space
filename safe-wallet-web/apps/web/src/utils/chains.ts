import { AppRoutes } from '@/config/routes'
import type { ChainInfo } from '@safe-global/safe-gateway-typescript-sdk'
import { getExplorerLink } from '@safe-global/utils/utils/gateway'
import { FEATURES, hasFeature } from '@safe-global/utils/utils/chains'

export const FeatureRoutes = {
  [AppRoutes.apps.index]: FEATURES.SAFE_APPS,
  [AppRoutes.swap]: FEATURES.NATIVE_SWAPS,
  [AppRoutes.stake]: FEATURES.STAKING,
  [AppRoutes.balances.nfts]: FEATURES.ERC721,
  [AppRoutes.settings.notifications]: FEATURES.PUSH_NOTIFICATIONS,
  [AppRoutes.bridge]: FEATURES.BRIDGE,
  [AppRoutes.earn]: FEATURES.EARN,
  [AppRoutes.balances.positions]: FEATURES.POSITIONS,
}

export const getBlockExplorerLink = (
  chain: ChainInfo,
  address: string,
): { href: string; title: string } | undefined => {
  if (chain.blockExplorerUriTemplate) {
    return getExplorerLink(address, chain.blockExplorerUriTemplate)
  }
}

export const isRouteEnabled = (route: string, chain?: ChainInfo) => {
  if (!chain) return false
  const featureRoute = FeatureRoutes[route]
  return !featureRoute || hasFeature(chain, featureRoute)
}

// Hetu chain IDs
export const HETU_MAINNET_CHAIN_ID = '560000'
export const HETU_TESTNET_CHAIN_ID = '565000'

/**
 * Check if a chain ID is a Hetu chain (mainnet or testnet)
 */
export const isHetuChain = (chainId: string): boolean => {
  return chainId === HETU_MAINNET_CHAIN_ID || chainId === HETU_TESTNET_CHAIN_ID
}

/**
 * Check if a chain ID is Hetu mainnet
 */
export const isHetuMainnet = (chainId: string): boolean => {
  return chainId === HETU_MAINNET_CHAIN_ID
}

/**
 * Check if a chain ID is Hetu testnet
 */
export const isHetuTestnet = (chainId: string): boolean => {
  return chainId === HETU_TESTNET_CHAIN_ID
}
