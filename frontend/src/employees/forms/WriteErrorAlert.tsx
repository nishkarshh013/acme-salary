import { Alert, Button } from 'antd'
import { ApiError } from '../../api/client'

interface Props {
  error: Error | null
  /** Fetch the employee again, for a 409. */
  onReload?: () => void
}

/**
 * Shows a failed save inside the form: the API's messages as they are, and
 * for a 409 (someone else changed the employee) a Reload button.
 */
export function WriteErrorAlert({ error, onReload }: Props) {
  if (!error) return null

  const messages = error instanceof ApiError ? error.messages : [error.message]
  if (error instanceof ApiError && error.status === 409) {
    return (
      <Alert
        type="warning"
        showIcon
        role="alert"
        title={messages.join(' ')}
        action={
          onReload && (
            <Button size="small" onClick={onReload}>
              Reload
            </Button>
          )
        }
        style={{ marginBottom: 16 }}
      />
    )
  }

  return (
    <Alert
      type="error"
      showIcon
      role="alert"
      title={messages.length === 1 ? messages[0] : 'The changes couldn’t be saved:'}
      description={
        messages.length > 1 && (
          <ul style={{ margin: 0, paddingInlineStart: 20 }}>
            {messages.map((message) => (
              <li key={message}>{message}</li>
            ))}
          </ul>
        )
      }
      style={{ marginBottom: 16 }}
    />
  )
}
