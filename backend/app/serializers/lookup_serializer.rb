# For departments and job titles.
class LookupSerializer
  def self.call(record)
    { id: record.id, name: record.name }
  end
end
