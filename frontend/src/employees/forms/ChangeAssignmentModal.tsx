import { App, Button, Form, Input, Modal, Select } from 'antd'
import { useState } from 'react'
import { changeAssignment, type ChangeAssignmentBody } from '../../api/employees'
import type { EmployeeDetail } from '../../api/types'
import { useToday } from '../../auth/useSession'
import { formatMoney } from '../../money/formatMoney'
import { useCountries, useDepartments, useJobTitles } from '../../lookups/useLookups'
import { useEmployeeWrite } from '../useEmployee'
import { moneyRules, pastDateRules, requiredRule } from './formRules'
import { useReloadEmployee } from './useReloadEmployee'
import { WriteErrorAlert } from './WriteErrorAlert'

interface Values {
  country_id: number
  department_id: number
  job_title_id: number
  new_salary?: string
  effective_date: string
  reason: string
}

interface Props {
  employee: EmployeeDetail
  onClose: () => void
}

/**
 * Moving to a country with another currency requires a new salary in that
 * currency. Otherwise a salary change is optional (a promotion with a raise),
 * behind a link.
 */
export function ChangeAssignmentModal({ employee, onClose }: Props) {
  const [form] = Form.useForm<Values>()
  const today = useToday()
  const { message } = App.useApp()
  const countries = useCountries()
  const departments = useDepartments()
  const jobTitles = useJobTitles()
  const write = useEmployeeWrite((body: ChangeAssignmentBody) => changeAssignment(employee.id, body))
  const reload = useReloadEmployee(employee.id, write.reset)
  const [optionalSalary, setOptionalSalary] = useState(false)

  const countryId = Form.useWatch('country_id', form) ?? employee.country.id
  const newCurrency = countries.data?.find((country) => country.id === countryId)?.currency_code
  const currentCurrency = employee.current_salary.currency
  const currencyChanges = newCurrency !== undefined && newCurrency !== currentCurrency
  const showSalary = currencyChanges || optionalSalary

  const save = (values: Values) =>
    write.mutate(
      {
        lock_version: employee.lock_version,
        country_id: values.country_id,
        department_id: values.department_id,
        job_title_id: values.job_title_id,
        new_salary: showSalary && values.new_salary?.trim() ? values.new_salary.trim() : undefined,
        effective_date: values.effective_date,
        reason: values.reason.trim(),
      },
      {
        onSuccess: () => {
          message.success('Assignment changed')
          onClose()
        },
      },
    )

  const options = (items: { id: number; name: string }[] | undefined) =>
    items?.map((item) => ({ value: item.id, label: item.name }))

  return (
    <Modal
      open
      title="Change assignment"
      okText="Save change"
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
          country_id: employee.country.id,
          department_id: employee.department.id,
          job_title_id: employee.job_title.id,
          effective_date: today,
        }}
        onFinish={save}
      >
        <Form.Item label="Country" name="country_id" rules={[{ required: true }]}>
          <Select
            showSearch={{ optionFilterProp: 'label' }}
            loading={countries.isPending}
            options={countries.data?.map((country) => ({
              value: country.id,
              label: `${country.name} (${country.currency_code})`,
            }))}
          />
        </Form.Item>
        <Form.Item label="Department" name="department_id" rules={[{ required: true }]}>
          <Select showSearch={{ optionFilterProp: 'label' }} loading={departments.isPending} options={options(departments.data)} />
        </Form.Item>
        <Form.Item label="Job title" name="job_title_id" rules={[{ required: true }]}>
          <Select showSearch={{ optionFilterProp: 'label' }} loading={jobTitles.isPending} options={options(jobTitles.data)} />
        </Form.Item>

        {showSalary ? (
          <Form.Item
            label={currencyChanges ? `New salary in ${newCurrency}` : 'New salary (optional)'}
            name="new_salary"
            rules={moneyRules('New salary', { required: currencyChanges })}
            extra={
              currencyChanges
                ? `The salary currency changes from ${currentCurrency} to ${newCurrency}, so a new salary is required. Current: ${formatMoney(employee.current_salary)}.`
                : `Current: ${formatMoney(employee.current_salary)}. Leave empty to keep it.`
            }
          >
            <Input inputMode="decimal" autoComplete="off" suffix={newCurrency ?? currentCurrency} />
          </Form.Item>
        ) : (
          <Form.Item>
            <Button type="link" style={{ padding: 0 }} onClick={() => setOptionalSalary(true)}>
              Also change the salary
            </Button>
          </Form.Item>
        )}

        <Form.Item label="Effective date" name="effective_date" rules={pastDateRules('Effective date', today)}>
          <Input type="date" max={today} />
        </Form.Item>
        <Form.Item label="Reason" name="reason" rules={requiredRule('Give a reason, for example “Promotion”')}>
          <Input.TextArea rows={2} maxLength={255} />
        </Form.Item>
      </Form>
    </Modal>
  )
}
