import { useState } from 'react'
import useConnectWallet from '@/components/common/ConnectWallet/useConnectWallet'
import useWallet from '@/hooks/wallets/useWallet'
import useChains from '@/hooks/useChains'
import { Box, Button, Typography, CircularProgress } from '@mui/material'
import EthHashInfo from '@/components/common/EthHashInfo'
import WalletIcon from '@/components/common/WalletIcon'

const WalletLogin = ({
  onLogin,
  onContinue,
  buttonText,
}: {
  onLogin: () => void
  onContinue: () => void
  buttonText?: string
}) => {
  const wallet = useWallet()
  const connectWallet = useConnectWallet()
  const { configs, loading: chainsLoading } = useChains()
  const [isConnecting, setIsConnecting] = useState(false)

  const onConnectWallet = async () => {
    console.log('🔧 WalletLogin: Connect wallet button clicked', {
      chainsLoading,
      configsLength: configs.length
    })
    setIsConnecting(true)
    
    try {
      await connectWallet()
      onLogin()
    } catch (error) {
      console.error('🔧 WalletLogin: Connection error:', error)
    } finally {
      // Keep button disabled for a moment to prevent double clicks
      setTimeout(() => setIsConnecting(false), 500)
    }
  }

  if (wallet !== null) {
    return (
      <Button variant="contained" sx={{ padding: '8px 16px' }} onClick={onContinue}>
        <Box justifyContent="space-between" display="flex" flexDirection="row" alignItems="center" gap={1}>
          <Box display="flex" flexDirection="column" alignItems="flex-start">
            <Typography variant="subtitle2" fontWeight={700}>
              {buttonText || 'Continue with'} {wallet.label}
            </Typography>
            {wallet.address && (
              <EthHashInfo address={wallet.address} shortAddress avatarSize={16} showName={false} copyAddress={false} />
            )}
          </Box>
          {wallet.icon && <WalletIcon icon={wallet.icon} provider={wallet.label} width={24} height={24} />}
        </Box>
      </Button>
    )
  }

  const buttonDisabled = isConnecting || chainsLoading
  const buttonLabel = chainsLoading 
    ? 'Loading...' 
    : isConnecting 
    ? 'Connecting...' 
    : 'Connect wallet'

  return (
    <Button 
      onClick={onConnectWallet} 
      sx={{ minHeight: '42px' }} 
      variant="contained" 
      size="small" 
      disableElevation
      disabled={buttonDisabled}
      startIcon={buttonDisabled ? <CircularProgress size={16} sx={{ color: 'inherit' }} /> : undefined}
    >
      {buttonLabel}
    </Button>
  )
}

export default WalletLogin
