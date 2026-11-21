# Clarifications from the Incubyte team

Questions I asked before writing the requirements, and the answers received.
These answers define the scope in [requirements.md](requirements.md).

## 1. Functional requirements

### Employee management and identity
- **Employee ID:** Each employee should have a unique employee ID.
- **Country transfers:** An employee retains the same identity when transferring between countries. Detailed transfer history is optional.
- **Employment records:** A single employee record with country and department attributes is sufficient.

### Salary management
- **Salary components:** Focus on annual gross base salary. Bonuses, allowances and deductions can remain out of scope.
- **Salary revisions:** Effective dates and revision reasons are useful additions; approval workflows are not required.
- **Salary history:** Current salary is sufficient; historical records may be included if they add value.

### Multi-country and currency support
- **Local currency:** Maintain salaries in the respective local currencies.
- **Organization-wide analytics:** Country-wise statistics can be provided separately. A fixed exchange-rate table is acceptable for conversion; converted values must be clearly labelled and assumptions documented.

### Reporting and data management
- **Insights:** Average, minimum, maximum and median salary by country, department and job title, plus total salary expenditure by department or country.
- **Excel/CSV import:** Optional; seeded dummy data is sufficient.
- **User access:** A single HR Manager persona is sufficient; complex role-based access is not required.

## 2. Non-functional requirements
- **Performance:** Reasonable performance for searches, dashboard loading and reports; no enterprise-scale optimisation needed.
- **Security:** Basic security practices; salary information handled appropriately.
- **Scalability:** 10,000 employees as the reference dataset; extensive scalability engineering not expected.
- **Concurrent updates:** Complex concurrency handling not required; basic data consistency must be maintained.

## 3. Assessment expectations
- **Testing:** Coverage based on critical business functionality; meaningful tests over a coverage percentage.
- **Deployment:** Any platform; a publicly accessible demo with seeded data is acceptable.