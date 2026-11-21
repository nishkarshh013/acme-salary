import { QueryClientProvider, type QueryClient } from '@tanstack/react-query'
import { App as AntApp, ConfigProvider } from 'antd'
import type { ReactNode } from 'react'

interface Props {
  queryClient: QueryClient
  children: ReactNode
}

export function AppProviders({ queryClient, children }: Props) {
  return (
    <QueryClientProvider client={queryClient}>
      <ConfigProvider>
        <AntApp>{children}</AntApp>
      </ConfigProvider>
    </QueryClientProvider>
  )
}
