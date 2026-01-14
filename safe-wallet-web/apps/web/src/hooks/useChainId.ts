import { useParams } from 'next/navigation'
import { parse, type ParsedUrlQuery } from 'querystring'
import { DEFAULT_CHAIN_ID } from '@/config/constants'
import chains from '@/config/chains'
import { parsePrefixedAddress } from '@safe-global/utils/utils/addresses'
import useWallet from './wallets/useWallet'
import useChains from './useChains'

// Use the location object directly because Next.js's router.query is available only on mount
const getLocationQuery = (): ParsedUrlQuery => {
  if (typeof location === 'undefined') return {}
  const query = parse(location.search.slice(1))
  return query
}

export const useUrlChainId = (): string | undefined => {
  const queryParams = useParams()
  const { configs } = useChains()

  // Dynamic query params
  const query = queryParams && (queryParams.safe || queryParams.chain) ? queryParams : getLocationQuery()
  const chain = query.chain?.toString() || ''
  const safe = query.safe?.toString() || ''

  const { prefix } = parsePrefixedAddress(safe)
  const shortName = prefix || chain

  if (!shortName) return undefined

  // First try static chains config, then fallback to dynamic configs
  const staticChainId = chains[shortName]
  if (staticChainId) return staticChainId
  
  // For custom chains like Hetu, search in the dynamic configs
  const dynamicChain = configs.find((item) => item.shortName === shortName)
  if (dynamicChain) return dynamicChain.chainId
  
  // If shortName is already a chain ID, return it
  if (/^\d+$/.test(shortName)) {
    const chainExists = configs.some(item => item.chainId === shortName)
    return chainExists ? shortName : undefined
  }
  
  return undefined
}

const useWalletChainId = (): string | undefined => {
  const wallet = useWallet()
  const { configs } = useChains()
  const walletChainId =
    wallet?.chainId && configs.some(({ chainId }) => chainId === wallet.chainId) ? wallet.chainId : undefined
  return walletChainId
}

export const useChainId = (): string => {
  const urlChainId = useUrlChainId()
  const walletChainId = useWalletChainId()
  
  const finalChainId = urlChainId || walletChainId || String(DEFAULT_CHAIN_ID)
  
  console.log('🔧 useChainId:', {
    urlChainId,
    walletChainId,
    DEFAULT_CHAIN_ID,
    finalChainId
  })

  return finalChainId
}

export default useChainId
