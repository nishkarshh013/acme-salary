import { App, Form, Input, Modal, Select } from 'antd'
import { useNavigate } from 'react-router-dom'
import { hireEmployee, type HireBody } from '../../api/employees'
import { useToday } from '../../auth/useSession'
import { useCountries, useDepartments, useJobTitles } from '../../lookups/useLookups'
import { useEmployeeWrite } from '../useEmployee'
import { moneyRules, pastDateRules, requiredRule } from './formRules'
import { WriteErrorAlert } from './WriteErrorAlert'

type Values = HireBody

interface Props {
  onClose: () => void
}

/** The employee code is assigned by the server. On success, opens the new employee's page. */
export function HireEmployeeModal({ onClose }: Props) {
  const [form] = Form.useForm<Values>()
  const today = useToday()
  const { message } = App.useApp()
  const navigate = useNavigate()
  const countries = useCountries()
  const departments = useDepartments()
  const jobTitles = useJobTitles()
  const write = useEmployeeWrite(hireEmployee)

  const countryId = Form.useWatch('country_id', form)
  const currency = countries.data?.find((country) => country.id === countryId)?.currency_code

  const save = (values: Values) =>
    write.mutate(
      {
        ...values,
        first_name: values.first_name.trim(),
        last_name: values.last_name.trim(),
        email: values.email.trim(),
        salary: values.salary.trim(),
      },
      {
        onSuccess: (employee) => {
          message.success(`${employee.first_name} ${employee.last_name} hired as ${employee.employee_code}`)
          onClose()
          navigate(`/employees/${employee.id}`)
        },
      },
    )

  const options = (items: { id: number; name: string }[] | undefined) =>
    items?.map((item) => ({ value: item.id, label: item.name }))

  return (
    <Modal
      open
      title="Hire employee"
      okText="Hire"
      onOk={() => form.submit()}
      onCancel={onClose}
      confirmLoading={write.isPending}
    >
      <WriteErrorAlert error={write.error} />
      <Form<Values> form={form} layout="vertical" requiredMark={false} initialValues={{ hire_date: today }} onFinish={save}>
        <Form.Item label="First name" name="first_name" rules={requiredRule('Enter the first name')}>
          <Input autoComplete="off" />
        </Form.Item>
        <Form.Item label="Last name" name="last_name" rules={requiredRule('Enter the last name')}>
          <Input autoComplete="off" />
        </Form.Item>
        <Form.Item label="Email" name="email" rules={[{ required: true, type: 'email', message: 'Enter a valid email address' }]}>
          <Input autoComplete="off" />
        </Form.Item>
        <Form.Item label="Country" name="country_id" rules={[{ required: true, message: 'Choose a country' }]}>
          <Select
            showSearch={{ optionFilterProp: 'label' }}
            loading={countries.isPending}
            options={countries.data?.map((country) => ({
              value: country.id,
              label: `${country.name} (${country.currency_code})`,
            }))}
          />
        </Form.Item>
        <Form.Item label="Department" name="department_id" rules={[{ required: true, message: 'Choose a department' }]}>
          <Select showSearch={{ optionFilterProp: 'label' }} loading={departments.isPending} options={options(departments.data)} />
        </Form.Item>
        <Form.Item label="Job title" name="job_title_id" rules={[{ required: true, message: 'Choose a job title' }]}>
          <Select showSearch={{ optionFilterProp: 'label' }} loading={jobTitles.isPending} options={options(jobTitles.data)} />
        </Form.Item>
        <Form.Item label="Hire date" name="hire_date" rules={pastDateRules('Hire date', today)}>
          <Input type="date" max={today} />
        </Form.Item>
        <Form.Item
          label="Annual salary"
          name="salary"
          rules={moneyRules('Salary')}
          extra={currency ? `Paid in ${currency}, the currency of the chosen country.` : 'Choose a country to set the currency.'}
        >
          <Input inputMode="decimal" autoComplete="off" suffix={currency ?? ''} />
        </Form.Item>
      </Form>
    </Modal>
  )
}
