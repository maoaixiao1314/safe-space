import { useCallback } from 'react'
import useOnboard, { connectWallet, initOnboard } from '@/hooks/wallets/useOnboard'
import useChains, { useCurrentChain } from '@/hooks/useChains'
import { useAppSelector } from '@/store'
import { selectRpc } from '@/store/settingsSlice'

let isInitializing = false

const useConnectWallet = () => {
  const onboard = useOnboard()
  const { configs, loading: chainsLoading } = useChains()
  const chain = useCurrentChain()
  const customRpc = useAppSelector(selectRpc)

  return useCallback(async () => {
    console.log('🔧 useConnectWallet: Attempting to connect wallet', { 
      onboard: !!onboard,
      configs: configs.length,
      chainsLoading,
      chain: chain?.chainId,
      isInitializing
    })
    
    // If Onboard exists, connect immediately
    if (onboard) {
      console.log('🔧 useConnectWallet: Onboard ready, connecting...')
      return connectWallet(onboard).catch((error) => {
        console.error('🔧 useConnectWallet: Connection failed:', error)
        return undefined
      })
    }

    // Wait for chains to load if they're still loading
    if (chainsLoading) {
      console.log('🔧 useConnectWallet: Chains still loading, waiting...')
      
      return new Promise((resolve) => {
        // Wait for chains to load (max 5 seconds)
        const maxWaitTime = 5000
        const checkInterval = 100
        let waited = 0
        
        const checkChains = setInterval(async () => {
          waited += checkInterval
          
          // Import fresh chain data
          const { selectChains } = await import('@/store/chainsSlice')
          const { makeStore } = await import('@/store')
          const storeInstance = makeStore()
          const state = storeInstance.getState()
          const chainsState = selectChains(state)
          
          console.log('🔧 useConnectWallet: Checking chains...', {
            waited,
            loading: chainsState.loading,
            dataLength: chainsState.data?.length || 0
          })
          
          if (!chainsState.loading && chainsState.data?.length > 0) {
            clearInterval(checkChains)
            console.log('🔧 useConnectWallet: Chains loaded, continuing...')
            
            // Retry with loaded chains
            const currentChain = chainsState.data[0] // Use first chain as fallback
            
            if (!isInitializing) {
              isInitializing = true
              try {
                await initOnboard(chainsState.data, currentChain, customRpc)
                
                setTimeout(async () => {
                  const { getStore } = await import('@/hooks/wallets/useOnboard')
                  const newOnboard = getStore()
                  isInitializing = false
                  
                  if (newOnboard) {
                    resolve(connectWallet(newOnboard))
                  } else {
                    resolve(undefined)
                  }
                }, 200)
              } catch (error) {
                console.error('🔧 useConnectWallet: Initialization failed:', error)
                isInitializing = false
                resolve(undefined)
              }
            } else {
              resolve(undefined)
            }
          } else if (waited >= maxWaitTime) {
            clearInterval(checkChains)
            console.error('🔧 useConnectWallet: Timeout waiting for chains')
            resolve(undefined)
          }
        }, checkInterval)
      })
    }

    // If Onboard doesn't exist but chains are loaded, try to initialize
    if (!isInitializing && configs.length > 0 && chain) {
      console.log('🔧 useConnectWallet: Onboard not ready, initializing...')
      isInitializing = true
      
      try {
        await initOnboard(configs, chain, customRpc)
        console.log('🔧 useConnectWallet: Onboard initialized successfully')
        
        // Wait for store update and retry
        return new Promise((resolve) => {
          setTimeout(async () => {
            isInitializing = false
            const { getStore } = await import('@/hooks/wallets/useOnboard')
            const newOnboard = getStore()
            
            if (newOnboard) {
              console.log('🔧 useConnectWallet: Connecting with new Onboard instance')
              resolve(connectWallet(newOnboard).catch((error) => {
                console.error('🔧 useConnectWallet: Connection failed after init:', error)
                return undefined
              }))
            } else {
              console.error('🔧 useConnectWallet: Onboard still not available after init')
              resolve(undefined)
            }
          }, 200)
        })
      } catch (error) {
        console.error('🔧 useConnectWallet: Initialization failed:', error)
        isInitializing = false
        return undefined
      }
    }

    console.error('🔧 useConnectWallet: Cannot connect - missing requirements', {
      isInitializing,
      hasConfigs: configs.length > 0,
      hasChain: !!chain,
      chainsLoading
    })
    return Promise.resolve(undefined)
  }, [onboard, configs, chain, customRpc, chainsLoading])
}

export default useConnectWallet
