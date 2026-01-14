import { Button } from '@mui/material'
import { useState } from 'react'
import useConnectWallet from '@/components/common/ConnectWallet/useConnectWallet'
import useOnboard from '@/hooks/wallets/useOnboard'
import useChains, { useCurrentChain } from '@/hooks/useChains'
import { useAppSelector } from '@/store'
import { selectRpc } from '@/store/settingsSlice'
import { initOnboard } from '@/hooks/wallets/useOnboard'

const ConnectWalletButton = ({
  onConnect,
  contained = true,
  small = false,
  text,
}: {
  onConnect?: () => void
  contained?: boolean
  small?: boolean
  text?: string
}): React.ReactElement => {
  const connectWallet = useConnectWallet()
  const onboard = useOnboard()
  const { configs } = useChains()
  const chain = useCurrentChain()
  const customRpc = useAppSelector(selectRpc)
  const [isInitializing, setIsInitializing] = useState(false)

  const handleConnect = async () => {
    console.log('🔧 ConnectWalletButton: Button clicked')
    console.log('🔧 ConnectWalletButton: State check:', {
      onboardExists: !!onboard,
      configsLength: configs.length,
      currentChain: chain?.chainId,
      currentChainName: chain?.chainName,
      isInitializing
    })

    // Prevent multiple initialization attempts
    if (isInitializing) {
      console.log('🔧 ConnectWalletButton: Already initializing, skipping...')
      return
    }

    // Force initialize Onboard if not available
    if (!onboard && configs.length > 0 && chain) {
      console.log('🔧 ConnectWalletButton: Force initializing Onboard...')
      setIsInitializing(true)
      try {
        await initOnboard(configs, chain, customRpc)
        console.log('🔧 ConnectWalletButton: Force initialization complete')
        // Wait a bit for the store to update, then connect
        setTimeout(() => {
          setIsInitializing(false)
          connectWallet()
        }, 150)
      } catch (error) {
        console.error('🔧 ConnectWalletButton: Force initialization failed:', error)
        setIsInitializing(false)
      }
    } else if (onboard) {
      // Onboard is ready, connect immediately
      connectWallet()
    } else {
      console.warn('🔧 ConnectWalletButton: Cannot connect - missing configs or chain')
    }
    
    onConnect?.()
  }

  return (
    <Button
      data-testid="connect-wallet-btn"
      onClick={handleConnect}
      variant={contained ? 'contained' : 'text'}
      size={small ? 'small' : 'medium'}
      disableElevation
      fullWidth
      disabled={isInitializing}
      sx={{ fontSize: small ? ['12px', '13px'] : '' }}
    >
      {isInitializing ? 'Initializing...' : (text || 'Connect')}
    </Button>
  )
}

export default ConnectWalletButton
