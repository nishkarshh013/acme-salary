ACME Salary Management — Manual Test Plan
Nov 22, 2026 · @Nishkarsh
How to use this plan
Run the sections in order on freshly seeded data: the expected numbers below hold only until the first write in section 5. Record Pass or Fail in each Result cell, and write down anything unexpected, even small. A failed case is a bug to fix before deployment.
Setup
1.	Reset the data: cd backend && bin/rails db:seed:replant.
2.	Start Rails: bin/rails server (port 3000).
3.	Start the frontend: cd frontend && npm run dev, then open http://localhost:5173.
4.	Keep DevTools open on the Network tab.
5.	Demo login: hr@acme.example / demo-password-dev-only.
Expected numbers on fresh seed data
Measure	Value
Employees, all statuses	10,000
Active employees	9,711
Inactive employees	289
Countries	8
Employees who moved country	192
Next employee code	EMP10001
Org total payroll	745,189,898.00 USD at 2026-10-01 rates
US headcount / median	2,769 / 100,000 USD
India headcount / median	2,336 / 2,350,000 INR

The US and India figures were measured on all employees during seeding, so the active-only figures on the insights page may be slightly lower. Note what the page shows the first time and use that as the baseline.
1. Authentication and session
Every page except login must require a session, and an ended session must send the user back to login.
ID	Steps	Expected	Result
A1	Open http://localhost:5173/employees while logged out	Login page shows	
A2	Log in with the right email and a wrong password	"Invalid email address or password"; still on login	
A3	Log in with an unknown email	Exactly the same message as A2	
A4	Submit the form with the password empty	Form error shown; no request in the Network tab	
A5	Log in with the demo credentials	Lands on /employees (the page asked for in A1); header shows the email	
A6	Reload the page	Still logged in, same page	
A7	Click Log out, then press the browser's Back button	Login page, not the previous screen	
A8	Log in, delete the session_id cookie (DevTools, Application, Cookies), switch to another tab and back	Sent to login on return	
A9	Log in, delete the session_id cookie, then change a filter on the employee list	Sent to login	
A10	Do this one last: submit a wrong password 11 times in a row	11th attempt is refused with a rate-limit message; works again after 3 minutes	

2. Employee list
The list must find any employee quickly, and its whole state must live in the URL.
ID	Steps	Expected	Result
L1	Open Employees	25 rows, "1–25 of 9,711 employees", sorted by last name; salaries shown with currency	
L2	Type a surname at normal speed	One request after you pause, not one per keystroke; matching rows only	
L3	Search a full name with a space, such as a first and last name from the list	That employee is found; the space isn't swallowed while typing	
L4	Search an employee code from the list	That employee is found	
L5	Filter by country, then department, then job title	Each narrows the rows; total updates; page goes back to 1	
L6	Set status to All, then Inactive	All shows 10,000; Inactive shows 289	
L7	With no country filter, hover the salary header	No sort control; tooltip explains currencies can't be sorted together	
L8	Filter to India, sort by salary descending	Highest INR salary first	
L9	Clear the country filter	Salary sort drops; URL updates	
L10	Switch to 50, then 100 per page	Back to page 1; correct row count	
L11	Go to page 300	Rows load; previous rows stay dimmed until then	
L12	Make several changes, then press Back repeatedly	Each step restores the earlier search, filters, sort and page, including the search box text	
L13	Copy the URL of a filtered, sorted view into a new tab	Same view opens	
L14	Search for nonsense text	"No employees match these filters"	
L15	Edit the URL to a page past the end	Message with a button back to page 1, keeping filters	
L16	Ctrl or Cmd-click an employee code	New tab opens; current tab stays on the list	

3. Employee detail and history
The detail page must show the current values and a complete, correctly ordered history.
ID	Steps	Expected	Result
D1	Click any row in the list	Detail page with name, code, status, email, country, department, job title, hire date and current salary	
D2	Read the timeline	Newest first; first entries read "Starting salary" and "Hired as"; each entry has a date and reason	
D3	Compare the current salary with the newest salary entry	They match	
D4	Find an employee who moved country (filter the list by a country, open a few, or ask the seed for one in the Rails console)	Move shows both countries ("India → Germany") and the revision shows both currencies	
D5	Open /employees/999999	"Employee not found"	
D6	Open an inactive employee (status filter Inactive)	Revise salary and Change assignment are disabled; hovering explains why	

To find a moved employee in the Rails console: EmployeeAssignment.group(:employee_id).having("count(*) > 1").pluck(:employee_id).first.
4. Insights (before any edits)
Insights must count active employees only, keep statistics within one currency, and label every converted figure. Write down the baseline numbers here; section 6 checks they change correctly.
ID	Steps	Expected	Result
I1	Open Insights	Headcount card shows 9,711; total payroll card shows a USD amount with its "converted at fixed rates as of" label	
I2	Read the country table	8 rows; min, median, average, max and total in local currency; USD column label shown once in its header, not on every row	
I3	Check INR amounts	Readable grouping (Indian grouping in an en-IN browser)	
I4	Read the department chart	One bar per department; exact amounts as text; label once under the heading	
I5	Check the notes	"Active employees only" and the one-cent rounding note are shown	
I6	Click the United States row	Country page with overall statistics in USD	
I7	Switch Department to Job title, then press Back and reload	Grouping switches; Back and reload keep the right grouping	
I8	Sort each column	Amounts sort numerically (9,000 before 10,000)	
I9	Click a department row	Employee list filtered to that country and department; its total equals the row's headcount	
I10	Open /insights/countries/999	"Country not found"	

Baseline to record: US headcount and median, India headcount and median, org total in USD, and one department's headcount in the US.
5. Write actions
Every change must save history and current values together, enforce the business rules, and save nothing when it fails. Pick one active US employee as your test employee and note their code and current salary.
Revise salary
ID	Steps	Expected	Result
W1	Open Revise salary	Currency shown in the amount box; date defaults to today; tomorrow can't be picked	
W2	Submit with the reason empty	Form error; no request sent	
W3	Enter 0, then 100.555, then 10000000000000	Each refused with a clear message	
W4	Enter a date earlier than the newest salary entry	Server error "earlier than the latest revision" shown in the form; nothing saved	
W5	Enter a valid raise with a reason and save	Salary and timeline update at once; no extra GET for the employee in the Network tab	
W6	Go back to the list	The new salary shows there	

Change assignment
ID	Steps	Expected	Result
W7	Change only the department, with a reason	Saved; timeline shows the department change	
W8	Change the job title and use "Also change the salary"	One action saves both; timeline shows both with the same reason	
W9	Pick a country with another currency (US to India)	Required "New salary in INR" field appears	
W10	Save the move without a new salary	Refused; nothing saved	
W11	Save the move with a new INR salary	Timeline shows the old USD amount and the new INR amount	
W12	On a Germany employee, move to France without a new salary	Saved; salary unchanged in EUR	
W13	Submit with nothing changed	"Nothing to change" message in the form	

Edit details
ID	Steps	Expected	Result
W14	Change the first name and save	Header and list show the new name	
W15	Change the email to another employee's email	Duplicate email message; nothing saved	
W16	Set status to Inactive	Confirmation asked first; afterwards actions are disabled	

Hire
ID	Steps	Expected	Result
W17	Click Hire employee and pick a country	Salary box shows that country's currency; no employee code field	
W18	Try a hire date of tomorrow	Can't be picked or is refused	
W19	Hire with an existing employee's email	Duplicate email message	
W20	Hire with valid details	Lands on the new employee's page; code is EMP10001; timeline shows starting salary and hire	

Conflicts
ID	Steps	Expected	Result
W21	Using another active employee (yours is now inactive), open the same employee in two tabs; revise the salary in tab 1; then try to revise in tab 2	Tab 2 shows "changed by someone else" with Reload; no revision saved	
W22	In tab 2, press Reload, then save	Typed values kept; save succeeds; timeline shows both revisions	

6. Consistency between features
The insights must reflect every change from section 5, which proves both halves of the app read the same data. Compare with the baseline from section 4.
ID	Check	Expected	Result
C1	Org headcount card	Baseline − 1 (deactivated in W16) + 1 (hired in W20) = unchanged, if the hire was active	
C2	US headcount	Baseline − 1 (your test employee moved to India in W11), adjusted if your hire was in the US	
C3	India headcount	Unchanged: +1 from the move in W11, then −1 when that employee became inactive in W16	
C4	Status filter Inactive on the list	290 (289 + the employee from W16)	
C5	Status filter All on the list	10,001 (one hire)	
C6	Drill into the country of the W21 employee	Its total payroll changed by that employee's two raises	
C7	Open your inactive test employee	Full history intact: hire, raise, department, promotion, move, all in order	

If a number is off, check the employee's timeline first: it shows exactly which changes were saved.
7. Security, errors and layout
Salary data must never be reachable without a session or visible in logs, and failures must be shown clearly.
ID	Steps	Expected	Result
S1	Log out, then run fetch('/api/employees').then(r => r.status) in the DevTools console	Prints 401	
S2	Run curl -i -X POST http://localhost:3000/api/session -H "Origin: https://evil.example" -H "Content-Type: application/json" -d '{}'	403, not 401 or 201	
S3	After a salary revision, run grep -n "amount" backend/log/development.log \| tail -5	Amount shows as [FILTERED], never the number	
S4	Log in, then run the same grep for password	Password shows as [FILTERED]	
E1	Stop Rails, then change a filter on the list	Error message with a Retry button	
E2	Start Rails again and press Retry	List loads	
E3	Narrow the window to phone width on the list, a detail page, a form and Insights	Everything stays usable; wide tables scroll sideways	

When you finish: reset the data with cd backend && bin/rails db:seed:replant, so the next run starts from the same numbers. Then fix every failed case before deploying, and keep this filled-in plan as docs/manual-test-plan.md: a completed run is good evidence for the evaluators.
