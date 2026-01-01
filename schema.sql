-- Enable pgcrypto for gen_random_uuid
CREATE EXTENSION IF NOT EXISTS pgcrypto WITH SCHEMA extensions;

-- Create Schema
CREATE SCHEMA IF NOT EXISTS hrmswishluv;

-- Enums
CREATE TYPE hrmswishluv.user_role AS ENUM ('admin', 'manager', 'employee');
CREATE TYPE hrmswishluv.leave_status AS ENUM ('pending', 'approved', 'rejected');
CREATE TYPE hrmswishluv.leave_type AS ENUM ('sick', 'vacation', 'personal', 'maternity', 'paternity');
CREATE TYPE hrmswishluv.expense_status AS ENUM ('submitted', 'approved', 'rejected', 'reimbursed');
CREATE TYPE hrmswishluv.attendance_status AS ENUM ('present', 'absent', 'late', 'half_day');

-- Tables

CREATE TABLE IF NOT EXISTS hrmswishluv.users (
  id varchar PRIMARY KEY DEFAULT gen_random_uuid(),
  email varchar NOT NULL UNIQUE,
  password_hash varchar NOT NULL,
  first_name varchar NOT NULL,
  last_name varchar NOT NULL,
  profile_image_url varchar,
  role hrmswishluv.user_role DEFAULT 'employee',
  is_onboarding_complete boolean DEFAULT false,
  needs_password_reset boolean DEFAULT true,
  department varchar,
  position varchar,
  manager_id varchar,
  salary numeric(10, 2),
  join_date timestamp,
  is_active boolean DEFAULT true,
  created_at timestamp DEFAULT now(),
  updated_at timestamp DEFAULT now(),
  tenant_id varchar DEFAULT 'default'
);

CREATE TABLE IF NOT EXISTS hrmswishluv.sessions (
  sid varchar PRIMARY KEY,
  sess jsonb NOT NULL,
  expire timestamp NOT NULL
);
CREATE INDEX IF NOT EXISTS "IDX_session_expire" ON hrmswishluv.sessions(expire);

CREATE TABLE IF NOT EXISTS hrmswishluv.attendance (
  id varchar PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id varchar NOT NULL REFERENCES hrmswishluv.users(id),
  date timestamp NOT NULL,
  check_in timestamp,
  check_out timestamp,
  status hrmswishluv.attendance_status DEFAULT 'present',
  location varchar,
  location_name varchar,
  latitude numeric(10, 8),
  longitude numeric(11, 8),
  notes text,
  created_at timestamp DEFAULT now()
);

CREATE TABLE IF NOT EXISTS hrmswishluv.leave_requests (
  id varchar PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id varchar NOT NULL REFERENCES hrmswishluv.users(id),
  type hrmswishluv.leave_type NOT NULL,
  start_date timestamp NOT NULL,
  end_date timestamp NOT NULL,
  days integer NOT NULL,
  reason text,
  status hrmswishluv.leave_status DEFAULT 'pending',
  approver_id varchar,
  approver_notes text,
  created_at timestamp DEFAULT now(),
  updated_at timestamp DEFAULT now()
);

CREATE TABLE IF NOT EXISTS hrmswishluv.expense_claims (
  id varchar PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id varchar NOT NULL REFERENCES hrmswishluv.users(id),
  title varchar NOT NULL,
  amount numeric(10, 2) NOT NULL,
  category varchar NOT NULL,
  description text,
  receipt_url varchar,
  status hrmswishluv.expense_status DEFAULT 'submitted',
  approver_id varchar,
  approver_notes text,
  submission_date timestamp DEFAULT now(),
  approval_date timestamp,
  reimbursement_date timestamp
);

CREATE TABLE IF NOT EXISTS hrmswishluv.employee_salary_structure (
  id varchar PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id varchar NOT NULL UNIQUE REFERENCES hrmswishluv.users(id),
  basic_salary numeric(10, 2) NOT NULL,
  hra numeric(10, 2) DEFAULT 0.00,
  conveyance_allowance numeric(10, 2) DEFAULT 0.00,
  medical_allowance numeric(10, 2) DEFAULT 0.00,
  special_allowance numeric(10, 2) DEFAULT 0.00,
  gross_salary numeric(10, 2) NOT NULL,
  provident_fund numeric(10, 2) DEFAULT 0.00,
  professional_tax numeric(10, 2) DEFAULT 0.00,
  income_tax numeric(10, 2) DEFAULT 0.00,
  other_deductions numeric(10, 2) DEFAULT 0.00,
  total_deductions numeric(10, 2) NOT NULL,
  net_salary numeric(10, 2) NOT NULL,
  effective_date timestamp DEFAULT now(),
  created_at timestamp DEFAULT now(),
  updated_at timestamp DEFAULT now()
);

CREATE TABLE IF NOT EXISTS hrmswishluv.payroll (
  id varchar PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id varchar NOT NULL,
  month integer NOT NULL,
  year integer NOT NULL,
  basic_salary numeric(10, 2) NOT NULL,
  allowances numeric(10, 2) DEFAULT 0,
  deductions numeric(10, 2) DEFAULT 0,
  gross_salary numeric(10, 2) NOT NULL,
  net_salary numeric(10, 2) NOT NULL,
  salary_breakup jsonb,
  status varchar DEFAULT 'draft',
  processed_at timestamp,
  payslip_url varchar,
  created_at timestamp DEFAULT now(),
  updated_at timestamp DEFAULT now()
);

CREATE TABLE IF NOT EXISTS hrmswishluv.announcements (
  id varchar PRIMARY KEY DEFAULT gen_random_uuid(),
  title varchar NOT NULL,
  content text NOT NULL,
  priority varchar DEFAULT 'normal',
  author_id varchar NOT NULL,
  is_active boolean DEFAULT true,
  created_at timestamp DEFAULT now()
);

CREATE TABLE IF NOT EXISTS hrmswishluv.company_settings (
  id varchar PRIMARY KEY DEFAULT gen_random_uuid(),
  company_name varchar NOT NULL,
  office_locations jsonb,
  working_hours jsonb,
  leave_types jsonb,
  created_at timestamp DEFAULT now(),
  updated_at timestamp DEFAULT now()
);

CREATE TABLE IF NOT EXISTS hrmswishluv.departments (
    id varchar PRIMARY KEY DEFAULT gen_random_uuid(),
    name varchar NOT NULL UNIQUE,
    description text,
    created_by varchar REFERENCES hrmswishluv.users(id),
    created_at timestamp DEFAULT now(),
    updated_at timestamp DEFAULT now()
);

CREATE TABLE IF NOT EXISTS hrmswishluv.designations (
    id varchar PRIMARY KEY DEFAULT gen_random_uuid(),
    name varchar NOT NULL,
    description text,
    department_id varchar REFERENCES hrmswishluv.departments(id),
    created_by varchar REFERENCES hrmswishluv.users(id),
    created_at timestamp DEFAULT now(),
    updated_at timestamp DEFAULT now()
);


CREATE TABLE IF NOT EXISTS hrmswishluv.employee_profiles (
  id varchar PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id varchar NOT NULL UNIQUE REFERENCES hrmswishluv.users(id),
  father_name varchar,
  date_of_birth timestamp,
  marriage_anniversary timestamp,
  personal_mobile varchar,
  emergency_contact_name varchar,
  emergency_contact_number varchar,
  emergency_contact_relation varchar,
  date_of_joining timestamp,
  designation varchar,
  pan_number varchar,
  aadhar_number varchar,
  bank_account_number varchar,
  ifsc_code varchar,
  bank_name varchar,
  bank_proof_document_path varchar,
  uan_number varchar,
  pf_number varchar,
  basic_salary numeric(15, 2),
  hra numeric(15, 2),
  pf_employee_contribution numeric(15, 2),
  pf_employer_contribution numeric(15, 2),
  esic_employee_contribution numeric(15, 2),
  esic_employer_contribution numeric(15, 2),
  special_allowance numeric(15, 2),
  performance_bonus numeric(15, 2),
  gratuity numeric(15, 2),
  professional_tax numeric(15, 2),
  medical_allowance numeric(15, 2),
  conveyance_allowance numeric(15, 2),
  food_coupons numeric(15, 2),
  lta numeric(15, 2),
  shift_allowance numeric(15, 2),
  overtime_pay numeric(15, 2),
  attendance_bonus numeric(15, 2),
  joining_bonus numeric(15, 2),
  retention_bonus numeric(15, 2),
  onboarding_completed boolean DEFAULT false,
  approved_by varchar REFERENCES hrmswishluv.users(id),
  approved_at timestamp,
  created_at timestamp DEFAULT now(),
  updated_at timestamp DEFAULT now()
);

CREATE TABLE IF NOT EXISTS hrmswishluv.leave_assignments (
  id varchar PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id varchar NOT NULL REFERENCES hrmswishluv.users(id),
  year integer NOT NULL,
  annual_leave integer DEFAULT 21,
  sick_leave integer DEFAULT 7,
  casual_leave integer DEFAULT 7,
  maternity_leave integer DEFAULT 84,
  paternity_leave integer DEFAULT 15,
  annual_used integer DEFAULT 0,
  sick_used integer DEFAULT 0,
  casual_used integer DEFAULT 0,
  maternity_used integer DEFAULT 0,
  paternity_used integer DEFAULT 0,
  created_at timestamp DEFAULT now(),
  updated_at timestamp DEFAULT now()
);

-- Note: IMPORTANT for Access
-- Since we are creating a new schema, we must ensure RLS is handled.
-- For simplicity in this script, we will enable RLS and add a permissve policy.
-- The user should restrict this later.

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

-- Grant privileges (Must be done AFTER tables are created)
GRANT USAGE ON SCHEMA hrmswishluv TO postgres, anon, authenticated, service_role;
GRANT ALL ON ALL TABLES IN SCHEMA hrmswishluv TO postgres, anon, authenticated, service_role;
GRANT ALL ON ALL SEQUENCES IN SCHEMA hrmswishluv TO postgres, anon, authenticated, service_role;
GRANT ALL ON ALL FUNCTIONS IN SCHEMA hrmswishluv TO postgres, anon, authenticated, service_role;
