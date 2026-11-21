import { useState } from 'react'
import { BrowserRouter } from 'react-router-dom'
import { createQueryClient } from './api/queryClient'
import { AppProviders } from './app/AppProviders'
import { AppRoutes } from './app/AppRoutes'

export default function App() {
  const [queryClient] = useState(createQueryClient)

  return (
    <AppProviders queryClient={queryClient}>
      <BrowserRouter>
        <AppRoutes />
      </BrowserRouter>
    </AppProviders>
  )
}
