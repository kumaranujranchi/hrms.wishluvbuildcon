-- STEP 1: DIAGNOSTIC QUERIES
-- Run these first to understand the current state

-- Check if hrmswishluv schema exists
SELECT schema_name 
FROM information_schema.schemata 
WHERE schema_name = 'hrmswishluv';

-- Check what schemas exist
SELECT schema_name 
FROM information_schema.schemata 
ORDER BY schema_name;

-- Check if any tables exist in hrmswishluv schema
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'hrmswishluv';

-- Check if custom types exist
SELECT n.nspname as schema, t.typname as type_name
FROM pg_type t 
LEFT JOIN pg_catalog.pg_namespace n ON n.oid = t.typnamespace 
WHERE n.nspname = 'hrmswishluv';

-- STEP 2: CLEANUP (Only run if you want to start fresh)
-- WARNING: This will delete all data in hrmswishluv schema!

-- Drop schema and recreate (UNCOMMENT ONLY IF YOU WANT TO START FRESH)
-- DROP SCHEMA IF EXISTS hrmswishluv CASCADE;

-- STEP 3: FRESH SETUP
-- After cleanup, run this to create everything fresh

CREATE SCHEMA IF NOT EXISTS hrmswishluv;

-- Create enums
DO $$ 
BEGIN
    -- Drop existing types if they exist
    DROP TYPE IF EXISTS hrmswishluv.user_role CASCADE;
    DROP TYPE IF EXISTS hrmswishluv.leave_status CASCADE;
    DROP TYPE IF EXISTS hrmswishluv.leave_type CASCADE;
    DROP TYPE IF EXISTS hrmswishluv.expense_status CASCADE;
    DROP TYPE IF EXISTS hrmswishluv.attendance_status CASCADE;
    
    -- Create new types
    CREATE TYPE hrmswishluv.user_role AS ENUM ('admin', 'manager', 'employee');
    CREATE TYPE hrmswishluv.leave_status AS ENUM ('pending', 'approved', 'rejected');
    CREATE TYPE hrmswishluv.leave_type AS ENUM ('sick', 'vacation', 'personal', 'maternity', 'paternity');
    CREATE TYPE hrmswishluv.expense_status AS ENUM ('submitted', 'approved', 'rejected', 'reimbursed');
    CREATE TYPE hrmswishluv.attendance_status AS ENUM ('present', 'absent', 'late', 'half_day');
END $$;

-- Create users table first (other tables depend on it)
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

-- Create sessions table
CREATE TABLE IF NOT EXISTS hrmswishluv.sessions (
  sid varchar PRIMARY KEY,
  sess jsonb NOT NULL,
  expire timestamp(6) NOT NULL
);
CREATE INDEX IF NOT EXISTS "IDX_session_expire" ON hrmswishluv.sessions(expire);

-- Create departments table
CREATE TABLE IF NOT EXISTS hrmswishluv.departments (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    name text NOT NULL UNIQUE,
    description text,
    created_by uuid REFERENCES hrmswishluv.users(id),
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now()
);

-- Create designations table
CREATE TABLE IF NOT EXISTS hrmswishluv.designations (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    name text NOT NULL,
    description text,
    department_id uuid REFERENCES hrmswishluv.departments(id),
    created_by uuid REFERENCES hrmswishluv.users(id),
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now()
);

-- Create attendance table
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

-- Create leave_requests table
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

-- Create expense_claims table
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

-- Create employee_salary_structure table
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

-- Create payroll table
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

-- Create announcements table
CREATE TABLE IF NOT EXISTS hrmswishluv.announcements (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  title text NOT NULL,
  content text NOT NULL,
  priority text DEFAULT 'normal',
  author_id uuid NOT NULL,
  is_active boolean DEFAULT true,
  created_at timestamp with time zone DEFAULT now()
);

-- Create company_settings table
CREATE TABLE IF NOT EXISTS hrmswishluv.company_settings (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_name text NOT NULL,
  office_locations jsonb,
  working_hours jsonb,
  leave_types jsonb,
  created_at timestamp with time zone DEFAULT now(),
  updated_at timestamp with time zone DEFAULT now()
);

-- Create employee_profiles table
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

-- Create leave_assignments table
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

-- Enable RLS and create policies
ALTER TABLE hrmswishluv.users ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Allow all access" ON hrmswishluv.users;
CREATE POLICY "Allow all access" ON hrmswishluv.users FOR ALL USING (true);

ALTER TABLE hrmswishluv.sessions ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Allow all access" ON hrmswishluv.sessions;
CREATE POLICY "Allow all access" ON hrmswishluv.sessions FOR ALL USING (true);

ALTER TABLE hrmswishluv.attendance ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Allow all access" ON hrmswishluv.attendance;
CREATE POLICY "Allow all access" ON hrmswishluv.attendance FOR ALL USING (true);

ALTER TABLE hrmswishluv.leave_requests ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Allow all access" ON hrmswishluv.leave_requests;
CREATE POLICY "Allow all access" ON hrmswishluv.leave_requests FOR ALL USING (true);

ALTER TABLE hrmswishluv.expense_claims ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Allow all access" ON hrmswishluv.expense_claims;
CREATE POLICY "Allow all access" ON hrmswishluv.expense_claims FOR ALL USING (true);

ALTER TABLE hrmswishluv.employee_salary_structure ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Allow all access" ON hrmswishluv.employee_salary_structure;
CREATE POLICY "Allow all access" ON hrmswishluv.employee_salary_structure FOR ALL USING (true);

ALTER TABLE hrmswishluv.payroll ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Allow all access" ON hrmswishluv.payroll;
CREATE POLICY "Allow all access" ON hrmswishluv.payroll FOR ALL USING (true);

ALTER TABLE hrmswishluv.employee_profiles ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Allow all access" ON hrmswishluv.employee_profiles;
CREATE POLICY "Allow all access" ON hrmswishluv.employee_profiles FOR ALL USING (true);

ALTER TABLE hrmswishluv.leave_assignments ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Allow all access" ON hrmswishluv.leave_assignments;
CREATE POLICY "Allow all access" ON hrmswishluv.leave_assignments FOR ALL USING (true);

ALTER TABLE hrmswishluv.announcements ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Allow all access" ON hrmswishluv.announcements;
CREATE POLICY "Allow all access" ON hrmswishluv.announcements FOR ALL USING (true);

ALTER TABLE hrmswishluv.company_settings ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Allow all access" ON hrmswishluv.company_settings;
CREATE POLICY "Allow all access" ON hrmswishluv.company_settings FOR ALL USING (true);

ALTER TABLE hrmswishluv.departments ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Allow all access" ON hrmswishluv.departments;
CREATE POLICY "Allow all access" ON hrmswishluv.departments FOR ALL USING (true);

ALTER TABLE hrmswishluv.designations ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Allow all access" ON hrmswishluv.designations;
CREATE POLICY "Allow all access" ON hrmswishluv.designations FOR ALL USING (true);

-- Grant privileges
GRANT USAGE ON SCHEMA hrmswishluv TO postgres, anon, authenticated, service_role;
GRANT ALL ON ALL TABLES IN SCHEMA hrmswishluv TO postgres, anon, authenticated, service_role;
GRANT ALL ON ALL SEQUENCES IN SCHEMA hrmswishluv TO postgres, anon, authenticated, service_role;
GRANT ALL ON ALL FUNCTIONS IN SCHEMA hrmswishluv TO postgres, anon, authenticated, service_role;

-- Verify everything is set up
SELECT 'Setup completed successfully!' as status;
SELECT table_name FROM information_schema.tables WHERE table_schema = 'hrmswishluv' ORDER BY table_name;
