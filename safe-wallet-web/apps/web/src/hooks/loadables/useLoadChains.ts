import { useEffect } from 'react'
import { useChainsGetChainsV1Query } from '@safe-global/store/gateway/AUTO_GENERATED/chains'
import { Errors, logError } from '@/services/exceptions'
import type { ChainInfo } from '@safe-global/safe-gateway-typescript-sdk'
import type { AsyncResult } from '@safe-global/utils/hooks/useAsync'

const MAX_CHAINS = 40

export const useLoadChains = () => {
  const { data, isLoading, error } = useChainsGetChainsV1Query({ cursor: `limit=${MAX_CHAINS}` })

  console.log('🔧 useLoadChains:', {
    dataLength: data?.results?.length || 0,
    isLoading,
    error: error?.toString(),
    chains: data?.results?.map(c => ({ id: c.chainId, name: c.chainName }))
  })

  // Log errors
  useEffect(() => {
    if (error) {
      logError(Errors._620, error.toString())
    }
  }, [error])

  return [data?.results, error, isLoading] as AsyncResult<ChainInfo[]>
}

export default useLoadChains
