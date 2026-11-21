# For services that update an employee on behalf of a caller who loaded it
# earlier. Staleness is checked twice:
# 1. Before any work, the caller's lock_version must match the employee
#    object passed in, so values read from it (such as the previous salary)
#    are the ones the caller saw.
# 2. On save, Rails' optimistic locking only updates the row if lock_version
#    is unchanged in the database; otherwise it raises StaleObjectError,
#    which the service rescues and reports with STALE_MESSAGE.
module OptimisticLocking
  STALE_MESSAGE = "This employee was changed by someone else. Reload and try again.".freeze

  private

  def stale?(employee, lock_version)
    Integer(lock_version, exception: false) != employee.lock_version
  end

  def stale_failure
    ServiceResult.failure(STALE_MESSAGE, error_type: :stale)
  end
end
