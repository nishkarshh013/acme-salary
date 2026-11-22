import { Alert, Button } from 'antd'
import { ApiError } from '../api/client'

interface Props {
  title: string
  error: Error
  onRetry: () => void
}

/** A failed load: the API's messages as they are, and a Retry button. */
export function QueryErrorAlert({ title, error, onRetry }: Props) {
  const messages = error instanceof ApiError ? error.messages : [error.message]
  return (
    <Alert
      type="error"
      showIcon
      title={title}
      description={messages.join(' ')}
      action={
        <Button size="small" onClick={onRetry}>
          Retry
        </Button>
      }
      style={{ marginBottom: 16 }}
    />
  )
}
