-- Part 3: Permissions

ALTER TABLE hrmswishluv.users ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Allow all access" ON hrmswishluv.users FOR ALL USING (true);

ALTER TABLE hrmswishluv.attendance ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Allow all access" ON hrmswishluv.attendance FOR ALL USING (true);

ALTER TABLE hrmswishluv.leave_requests ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Allow all access" ON hrmswishluv.leave_requests FOR ALL USING (true);

ALTER TABLE hrmswishluv.expense_claims ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Allow all access" ON hrmswishluv.expense_claims FOR ALL USING (true);

ALTER TABLE hrmswishluv.employee_salary_structure ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Allow all access" ON hrmswishluv.employee_salary_structure FOR ALL USING (true);

ALTER TABLE hrmswishluv.payroll ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Allow all access" ON hrmswishluv.payroll FOR ALL USING (true);

ALTER TABLE hrmswishluv.employee_profiles ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Allow all access" ON hrmswishluv.employee_profiles FOR ALL USING (true);

ALTER TABLE hrmswishluv.leave_assignments ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Allow all access" ON hrmswishluv.leave_assignments FOR ALL USING (true);

ALTER TABLE hrmswishluv.announcements ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Allow all access" ON hrmswishluv.announcements FOR ALL USING (true);

ALTER TABLE hrmswishluv.company_settings ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Allow all access" ON hrmswishluv.company_settings FOR ALL USING (true);

ALTER TABLE hrmswishluv.departments ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Allow all access" ON hrmswishluv.departments FOR ALL USING (true);

ALTER TABLE hrmswishluv.designations ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Allow all access" ON hrmswishluv.designations FOR ALL USING (true);

-- Grant privileges
GRANT USAGE ON SCHEMA hrmswishluv TO postgres, anon, authenticated, service_role;
GRANT ALL ON ALL TABLES IN SCHEMA hrmswishluv TO postgres, anon, authenticated, service_role;
GRANT ALL ON ALL SEQUENCES IN SCHEMA hrmswishluv TO postgres, anon, authenticated, service_role;
GRANT ALL ON ALL FUNCTIONS IN SCHEMA hrmswishluv TO postgres, anon, authenticated, service_role;
