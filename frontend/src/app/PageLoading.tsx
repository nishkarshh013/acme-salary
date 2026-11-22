import { Flex, Spin } from 'antd'

/** Shown while a page's code is still downloading. */
export function PageLoading() {
  return (
    <Flex justify="center" style={{ padding: 64 }}>
      <Spin size="large" aria-label="Loading page" />
    </Flex>
  )
}
