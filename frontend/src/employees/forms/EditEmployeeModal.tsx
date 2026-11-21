import { App, Form, Input, Modal, Segmented } from 'antd'
import { updateEmployee, type UpdateEmployeeBody } from '../../api/employees'
import type { EmployeeDetail, EmployeeStatus } from '../../api/types'
import { useEmployeeWrite } from '../useEmployee'
import { requiredRule } from './formRules'
import { useReloadEmployee } from './useReloadEmployee'
import { WriteErrorAlert } from './WriteErrorAlert'

type Values = Pick<UpdateEmployeeBody, 'first_name' | 'last_name' | 'email' | 'status'>

interface Props {
  employee: EmployeeDetail
  onClose: () => void
}

export function EditEmployeeModal({ employee, onClose }: Props) {
  const [form] = Form.useForm<Values>()
  const { message, modal } = App.useApp()
  const write = useEmployeeWrite((body: UpdateEmployeeBody) => updateEmployee(employee.id, body))
  const reload = useReloadEmployee(employee.id, write.reset)

  const save = (values: Values) =>
    write.mutate(
      {
        lock_version: employee.lock_version,
        first_name: values.first_name.trim(),
        last_name: values.last_name.trim(),
        email: values.email.trim(),
        status: values.status,
      },
      {
        onSuccess: () => {
          message.success('Details saved')
          onClose()
        },
      },
    )

  const confirmThenSave = (values: Values) => {
    if (employee.status === 'active' && values.status === 'inactive') {
      modal.confirm({
        title: `Make ${employee.first_name} ${employee.last_name} inactive?`,
        content:
          'Inactive employees are hidden from the employee list by default and left out of insights. ' +
          'Their salary and assignment can’t be changed until they are made active again. Their history is kept.',
        okText: 'Make inactive',
        okButtonProps: { danger: true },
        onOk: () => save(values),
      })
    } else {
      save(values)
    }
  }

  return (
    <Modal
      open
      title="Edit details"
      okText="Save"
      onOk={() => form.submit()}
      onCancel={onClose}
      confirmLoading={write.isPending}
    >
      <WriteErrorAlert error={write.error} onReload={reload} />
      <Form<Values>
        form={form}
        layout="vertical"
        requiredMark={false}
        initialValues={{
          first_name: employee.first_name,
          last_name: employee.last_name,
          email: employee.email,
          status: employee.status,
        }}
        onFinish={confirmThenSave}
      >
        <Form.Item label="First name" name="first_name" rules={requiredRule('Enter the first name')}>
          <Input autoComplete="off" />
        </Form.Item>
        <Form.Item label="Last name" name="last_name" rules={requiredRule('Enter the last name')}>
          <Input autoComplete="off" />
        </Form.Item>
        <Form.Item
          label="Email"
          name="email"
          rules={[{ required: true, type: 'email', message: 'Enter a valid email address' }]}
        >
          <Input autoComplete="off" />
        </Form.Item>
        <Form.Item label="Status" name="status">
          <Segmented<EmployeeStatus>
            options={[
              { label: 'Active', value: 'active' },
              { label: 'Inactive', value: 'inactive' },
            ]}
          />
        </Form.Item>
      </Form>
    </Modal>
  )
}
