import { App, Form, Input, Modal, Typography } from 'antd'
import { reviseSalary, type ReviseSalaryBody } from '../../api/employees'
import type { EmployeeDetail } from '../../api/types'
import { useToday } from '../../auth/useSession'
import { formatMoney } from '../../money/formatMoney'
import { useEmployeeWrite } from '../useEmployee'
import { moneyRules, pastDateRules, requiredRule } from './formRules'
import { useReloadEmployee } from './useReloadEmployee'
import { WriteErrorAlert } from './WriteErrorAlert'

interface Values {
  amount: string
  effective_date: string
  reason: string
}

interface Props {
  employee: EmployeeDetail
  onClose: () => void
}

export function ReviseSalaryModal({ employee, onClose }: Props) {
  const [form] = Form.useForm<Values>()
  const today = useToday()
  const { message } = App.useApp()
  const write = useEmployeeWrite((body: ReviseSalaryBody) => reviseSalary(employee.id, body))
  const reload = useReloadEmployee(employee.id, write.reset)
  const currency = employee.current_salary.currency

  const save = (values: Values) =>
    write.mutate(
      { lock_version: employee.lock_version, amount: values.amount.trim(), effective_date: values.effective_date, reason: values.reason.trim() },
      {
        onSuccess: () => {
          message.success('Salary revised')
          onClose()
        },
      },
    )

  return (
    <Modal
      open
      title="Revise salary"
      okText="Save revision"
      onOk={() => form.submit()}
      onCancel={onClose}
      confirmLoading={write.isPending}
    >
      <WriteErrorAlert error={write.error} onReload={reload} />
      <Form<Values>
        form={form}
        layout="vertical"
        requiredMark={false}
        initialValues={{ effective_date: today }}
        onFinish={save}
      >
        <Form.Item
          label="New annual salary"
          name="amount"
          rules={moneyRules('Amount')}
          extra={
            <Typography.Text type="secondary">
              Current: {formatMoney(employee.current_salary)}. Paid in {currency}, the currency of{' '}
              {employee.country.name}.
            </Typography.Text>
          }
        >
          <Input inputMode="decimal" autoComplete="off" suffix={currency} />
        </Form.Item>
        <Form.Item label="Effective date" name="effective_date" rules={pastDateRules('Effective date', today)}>
          <Input type="date" max={today} />
        </Form.Item>
        <Form.Item label="Reason" name="reason" rules={requiredRule('Give a reason, for example “Annual review”')}>
          <Input.TextArea rows={2} maxLength={255} />
        </Form.Item>
      </Form>
    </Modal>
  )
}
