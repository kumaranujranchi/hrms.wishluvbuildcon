-- Complete Supabase Setup Script for HRMS
-- Run this entire script in Supabase SQL Editor

-- Step 1: Enable required extensions
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- Step 2: Create custom schema
CREATE SCHEMA IF NOT EXISTS hrmswishluv;

-- Step 3: Create custom types (enums)
DO $$ 
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'user_role' AND typnamespace = 'hrmswishluv'::regnamespace) THEN
        CREATE TYPE hrmswishluv.user_role AS ENUM ('admin', 'manager', 'employee');
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'leave_status' AND typnamespace = 'hrmswishluv'::regnamespace) THEN
        CREATE TYPE hrmswishluv.leave_status AS ENUM ('pending', 'approved', 'rejected');
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'leave_type' AND typnamespace = 'hrmswishluv'::regnamespace) THEN
        CREATE TYPE hrmswishluv.leave_type AS ENUM ('sick', 'vacation', 'personal', 'maternity', 'paternity');
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'expense_status' AND typnamespace = 'hrmswishluv'::regnamespace) THEN
        CREATE TYPE hrmswishluv.expense_status AS ENUM ('submitted', 'approved', 'rejected', 'reimbursed');
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'attendance_status' AND typnamespace = 'hrmswishluv'::regnamespace) THEN
        CREATE TYPE hrmswishluv.attendance_status AS ENUM ('present', 'absent', 'late', 'half_day');
    END IF;
END $$;

-- Step 4: Create tables
CREATE TABLE IF NOT EXISTS hrmswishluv.users (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  email text NOT NULL UNIQUE,
  password_hash text NOT NULL,
  first_name text NOT NULL,
  last_name text NOT NULL,
  profile_image_url text,
  role hrmswishluv.user_role DEFAULT 'employee',
  is_onboarding_complete boolean DEFAULT false,
  needs_password_reset boolean DEFAULT true,
  department text,
  position text,
  manager_id uuid,
  salary numeric(10, 2),
  join_date timestamp with time zone,
  is_active boolean DEFAULT true,
  created_at timestamp with time zone DEFAULT now(),
  updated_at timestamp with time zone DEFAULT now(),
  tenant_id text DEFAULT 'default'
);

CREATE TABLE IF NOT EXISTS hrmswishluv.sessions (
  sid varchar PRIMARY KEY,
  sess jsonb NOT NULL,
  expire timestamp(6) NOT NULL
);
CREATE INDEX IF NOT EXISTS "IDX_session_expire" ON hrmswishluv.sessions(expire);

CREATE TABLE IF NOT EXISTS hrmswishluv.departments (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    name text NOT NULL UNIQUE,
    description text,
    created_by uuid REFERENCES hrmswishluv.users(id),
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now()
);

CREATE TABLE IF NOT EXISTS hrmswishluv.designations (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    name text NOT NULL,
    description text,
    department_id uuid REFERENCES hrmswishluv.departments(id),
    created_by uuid REFERENCES hrmswishluv.users(id),
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now()
);

CREATE TABLE IF NOT EXISTS hrmswishluv.attendance (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES hrmswishluv.users(id),
  date timestamp with time zone NOT NULL,
  check_in timestamp with time zone,
  check_out timestamp with time zone,
  status hrmswishluv.attendance_status DEFAULT 'present',
  location text,
  location_name text,
  latitude numeric(10, 8),
  longitude numeric(11, 8),
  notes text,
  created_at timestamp with time zone DEFAULT now()
);

CREATE TABLE IF NOT EXISTS hrmswishluv.leave_requests (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES hrmswishluv.users(id),
  type hrmswishluv.leave_type NOT NULL,
  start_date timestamp with time zone NOT NULL,
  end_date timestamp with time zone NOT NULL,
  days integer NOT NULL,
  reason text,
  status hrmswishluv.leave_status DEFAULT 'pending',
  approver_id uuid,
  approver_notes text,
  created_at timestamp with time zone DEFAULT now(),
  updated_at timestamp with time zone DEFAULT now()
);

CREATE TABLE IF NOT EXISTS hrmswishluv.expense_claims (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES hrmswishluv.users(id),
  title text NOT NULL,
  amount numeric(10, 2) NOT NULL,
  category text NOT NULL,
  description text,
  receipt_url text,
  status hrmswishluv.expense_status DEFAULT 'submitted',
  approver_id uuid,
  approver_notes text,
  submission_date timestamp with time zone DEFAULT now(),
  approval_date timestamp with time zone,
  reimbursement_date timestamp with time zone
);

CREATE TABLE IF NOT EXISTS hrmswishluv.employee_salary_structure (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL UNIQUE REFERENCES hrmswishluv.users(id),
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
  effective_date timestamp with time zone DEFAULT now(),
  created_at timestamp with time zone DEFAULT now(),
  updated_at timestamp with time zone DEFAULT now()
);

CREATE TABLE IF NOT EXISTS hrmswishluv.payroll (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL,
  month integer NOT NULL,
  year integer NOT NULL,
  basic_salary numeric(10, 2) NOT NULL,
  allowances numeric(10, 2) DEFAULT 0,
  deductions numeric(10, 2) DEFAULT 0,
  gross_salary numeric(10, 2) NOT NULL,
  net_salary numeric(10, 2) NOT NULL,
  salary_breakup jsonb,
  status text DEFAULT 'draft',
  processed_at timestamp with time zone,
  payslip_url text,
  created_at timestamp with time zone DEFAULT now(),
  updated_at timestamp with time zone DEFAULT now()
);

CREATE TABLE IF NOT EXISTS hrmswishluv.announcements (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  title text NOT NULL,
  content text NOT NULL,
  priority text DEFAULT 'normal',
  author_id uuid NOT NULL,
  is_active boolean DEFAULT true,
  created_at timestamp with time zone DEFAULT now()
);

CREATE TABLE IF NOT EXISTS hrmswishluv.company_settings (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_name text NOT NULL,
  office_locations jsonb,
  working_hours jsonb,
  leave_types jsonb,
  created_at timestamp with time zone DEFAULT now(),
  updated_at timestamp with time zone DEFAULT now()
);

CREATE TABLE IF NOT EXISTS hrmswishluv.employee_profiles (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL UNIQUE REFERENCES hrmswishluv.users(id),
  father_name text,
  date_of_birth timestamp with time zone,
  marriage_anniversary timestamp with time zone,
  personal_mobile text,
  emergency_contact_name text,
  emergency_contact_number text,
  emergency_contact_relation text,
  date_of_joining timestamp with time zone,
  designation text,
  pan_number text,
  aadhar_number text,
  bank_account_number text,
  ifsc_code text,
  bank_name text,
  bank_proof_document_path text,
  uan_number text,
  pf_number text,
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
  approved_by uuid REFERENCES hrmswishluv.users(id),
  approved_at timestamp with time zone,
  created_at timestamp with time zone DEFAULT now(),
  updated_at timestamp with time zone DEFAULT now()
);

CREATE TABLE IF NOT EXISTS hrmswishluv.leave_assignments (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES hrmswishluv.users(id),
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
  created_at timestamp with time zone DEFAULT now(),
  updated_at timestamp with time zone DEFAULT now()
);

-- Step 5: Enable Row Level Security
ALTER TABLE hrmswishluv.users ENABLE ROW LEVEL SECURITY;
ALTER TABLE hrmswishluv.attendance ENABLE ROW LEVEL SECURITY;
ALTER TABLE hrmswishluv.leave_requests ENABLE ROW LEVEL SECURITY;
ALTER TABLE hrmswishluv.expense_claims ENABLE ROW LEVEL SECURITY;
ALTER TABLE hrmswishluv.employee_salary_structure ENABLE ROW LEVEL SECURITY;
ALTER TABLE hrmswishluv.payroll ENABLE ROW LEVEL SECURITY;
ALTER TABLE hrmswishluv.employee_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE hrmswishluv.leave_assignments ENABLE ROW LEVEL SECURITY;
ALTER TABLE hrmswishluv.announcements ENABLE ROW LEVEL SECURITY;
ALTER TABLE hrmswishluv.company_settings ENABLE ROW LEVEL SECURITY;
ALTER TABLE hrmswishluv.departments ENABLE ROW LEVEL SECURITY;
ALTER TABLE hrmswishluv.designations ENABLE ROW LEVEL SECURITY;

-- Step 6: Create permissive policies (Allow all access for now)
DROP POLICY IF EXISTS "Allow all access" ON hrmswishluv.users;
CREATE POLICY "Allow all access" ON hrmswishluv.users FOR ALL USING (true);

DROP POLICY IF EXISTS "Allow all access" ON hrmswishluv.attendance;
CREATE POLICY "Allow all access" ON hrmswishluv.attendance FOR ALL USING (true);

DROP POLICY IF EXISTS "Allow all access" ON hrmswishluv.leave_requests;
CREATE POLICY "Allow all access" ON hrmswishluv.leave_requests FOR ALL USING (true);

DROP POLICY IF EXISTS "Allow all access" ON hrmswishluv.expense_claims;
CREATE POLICY "Allow all access" ON hrmswishluv.expense_claims FOR ALL USING (true);

DROP POLICY IF EXISTS "Allow all access" ON hrmswishluv.employee_salary_structure;
CREATE POLICY "Allow all access" ON hrmswishluv.employee_salary_structure FOR ALL USING (true);

DROP POLICY IF EXISTS "Allow all access" ON hrmswishluv.payroll;
CREATE POLICY "Allow all access" ON hrmswishluv.payroll FOR ALL USING (true);

DROP POLICY IF EXISTS "Allow all access" ON hrmswishluv.employee_profiles;
CREATE POLICY "Allow all access" ON hrmswishluv.employee_profiles FOR ALL USING (true);

DROP POLICY IF EXISTS "Allow all access" ON hrmswishluv.leave_assignments;
CREATE POLICY "Allow all access" ON hrmswishluv.leave_assignments FOR ALL USING (true);

DROP POLICY IF EXISTS "Allow all access" ON hrmswishluv.announcements;
CREATE POLICY "Allow all access" ON hrmswishluv.announcements FOR ALL USING (true);

DROP POLICY IF EXISTS "Allow all access" ON hrmswishluv.company_settings;
CREATE POLICY "Allow all access" ON hrmswishluv.company_settings FOR ALL USING (true);

DROP POLICY IF EXISTS "Allow all access" ON hrmswishluv.departments;
CREATE POLICY "Allow all access" ON hrmswishluv.departments FOR ALL USING (true);

DROP POLICY IF EXISTS "Allow all access" ON hrmswishluv.designations;
CREATE POLICY "Allow all access" ON hrmswishluv.designations FOR ALL USING (true);

-- Step 7: Grant necessary privileges
GRANT USAGE ON SCHEMA hrmswishluv TO postgres, anon, authenticated, service_role;
GRANT ALL ON ALL TABLES IN SCHEMA hrmswishluv TO postgres, anon, authenticated, service_role;
GRANT ALL ON ALL SEQUENCES IN SCHEMA hrmswishluv TO postgres, anon, authenticated, service_role;
GRANT ALL ON ALL FUNCTIONS IN SCHEMA hrmswishluv TO postgres, anon, authenticated, service_role;

-- Step 8: Verify setup
SELECT 'Schema created successfully!' as status;
SELECT table_name FROM information_schema.tables WHERE table_schema = 'hrmswishluv' ORDER BY table_name;
