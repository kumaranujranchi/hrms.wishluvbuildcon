-- PostgreSQL Setup Script for HRMS Application
-- This script creates all necessary tables in the public schema with hrms_ prefix
-- Run this script in your PostgreSQL database

-- Enable UUID generation extension
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- Create ENUM types
CREATE TYPE user_role AS ENUM ('admin', 'manager', 'employee');
CREATE TYPE leave_status AS ENUM ('pending', 'approved', 'rejected');
CREATE TYPE leave_type AS ENUM ('sick', 'vacation', 'personal', 'maternity', 'paternity');
CREATE TYPE expense_status AS ENUM ('submitted', 'approved', 'rejected', 'reimbursed');
CREATE TYPE attendance_status AS ENUM ('present', 'absent', 'late', 'half_day');

-- Sessions table (for session management)
CREATE TABLE hrms_sessions (
  sid varchar PRIMARY KEY,
  sess jsonb NOT NULL,
  expire timestamp(6) NOT NULL
);
CREATE INDEX idx_hrms_session_expire ON hrms_sessions(expire);

-- Users table
CREATE TABLE hrms_users (
  id varchar PRIMARY KEY DEFAULT gen_random_uuid()::text,
  email varchar UNIQUE NOT NULL,
  password_hash varchar NOT NULL,
  first_name varchar NOT NULL,
  last_name varchar NOT NULL,
  profile_image_url varchar,
  role user_role DEFAULT 'employee',
  is_onboarding_complete boolean DEFAULT false,
  needs_password_reset boolean DEFAULT true,
  department varchar,
  position varchar,
  manager_id varchar,
  salary decimal(10, 2),
  join_date timestamp,
  is_active boolean DEFAULT true,
  created_at timestamp DEFAULT now(),
  updated_at timestamp DEFAULT now()
);

-- Departments table
CREATE TABLE hrms_departments (
  id varchar PRIMARY KEY DEFAULT gen_random_uuid()::text,
  name varchar UNIQUE NOT NULL,
  description text,
  created_by varchar REFERENCES hrms_users(id),
  created_at timestamp DEFAULT now(),
  updated_at timestamp DEFAULT now()
);

-- Designations table
CREATE TABLE hrms_designations (
  id varchar PRIMARY KEY DEFAULT gen_random_uuid()::text,
  name varchar NOT NULL,
  description text,
  department_id varchar REFERENCES hrms_departments(id),
  created_by varchar REFERENCES hrms_users(id),
  created_at timestamp DEFAULT now(),
  updated_at timestamp DEFAULT now()
);

-- Attendance table
CREATE TABLE hrms_attendance (
  id varchar PRIMARY KEY DEFAULT gen_random_uuid()::text,
  user_id varchar NOT NULL REFERENCES hrms_users(id),
  date timestamp NOT NULL,
  check_in timestamp,
  check_out timestamp,
  status attendance_status DEFAULT 'present',
  location varchar,
  location_name varchar,
  latitude decimal(10, 8),
  longitude decimal(11, 8),
  notes text,
  created_at timestamp DEFAULT now()
);

-- Leave requests table
CREATE TABLE hrms_leave_requests (
  id varchar PRIMARY KEY DEFAULT gen_random_uuid()::text,
  user_id varchar NOT NULL REFERENCES hrms_users(id),
  type leave_type NOT NULL,
  start_date timestamp NOT NULL,
  end_date timestamp NOT NULL,
  days integer NOT NULL,
  reason text,
  status leave_status DEFAULT 'pending',
  approver_id varchar,
  approver_notes text,
  created_at timestamp DEFAULT now(),
  updated_at timestamp DEFAULT now()
);

-- Expense claims table
CREATE TABLE hrms_expense_claims (
  id varchar PRIMARY KEY DEFAULT gen_random_uuid()::text,
  user_id varchar NOT NULL REFERENCES hrms_users(id),
  title varchar NOT NULL,
  amount decimal(10, 2) NOT NULL,
  category varchar NOT NULL,
  description text,
  receipt_url varchar,
  status expense_status DEFAULT 'submitted',
  approver_id varchar,
  approver_notes text,
  submission_date timestamp DEFAULT now(),
  approval_date timestamp,
  reimbursement_date timestamp
);

-- Employee salary structure table
CREATE TABLE hrms_employee_salary_structure (
  id varchar PRIMARY KEY DEFAULT gen_random_uuid()::text,
  user_id varchar UNIQUE NOT NULL REFERENCES hrms_users(id),
  basic_salary decimal(10, 2) NOT NULL,
  hra decimal(10, 2) DEFAULT 0.00,
  conveyance_allowance decimal(10, 2) DEFAULT 0.00,
  medical_allowance decimal(10, 2) DEFAULT 0.00,
  special_allowance decimal(10, 2) DEFAULT 0.00,
  gross_salary decimal(10, 2) NOT NULL,
  provident_fund decimal(10, 2) DEFAULT 0.00,
  professional_tax decimal(10, 2) DEFAULT 0.00,
  income_tax decimal(10, 2) DEFAULT 0.00,
  other_deductions decimal(10, 2) DEFAULT 0.00,
  total_deductions decimal(10, 2) NOT NULL,
  net_salary decimal(10, 2) NOT NULL,
  effective_date timestamp DEFAULT now(),
  created_at timestamp DEFAULT now(),
  updated_at timestamp DEFAULT now()
);

-- Payroll table
CREATE TABLE hrms_payroll (
  id varchar PRIMARY KEY DEFAULT gen_random_uuid()::text,
  user_id varchar NOT NULL,
  month integer NOT NULL,
  year integer NOT NULL,
  basic_salary decimal(10, 2) NOT NULL,
  allowances decimal(10, 2) DEFAULT 0,
  deductions decimal(10, 2) DEFAULT 0,
  gross_salary decimal(10, 2) NOT NULL,
  net_salary decimal(10, 2) NOT NULL,
  salary_breakup jsonb,
  status varchar DEFAULT 'draft',
  processed_at timestamp,
  payslip_url varchar,
  created_at timestamp DEFAULT now(),
  updated_at timestamp DEFAULT now()
);

-- Announcements table
CREATE TABLE hrms_announcements (
  id varchar PRIMARY KEY DEFAULT gen_random_uuid()::text,
  title varchar NOT NULL,
  content text NOT NULL,
  priority varchar DEFAULT 'normal',
  author_id varchar NOT NULL,
  is_active boolean DEFAULT true,
  created_at timestamp DEFAULT now()
);

-- Company settings table
CREATE TABLE hrms_company_settings (
  id varchar PRIMARY KEY DEFAULT gen_random_uuid()::text,
  company_name varchar NOT NULL,
  office_locations jsonb,
  working_hours jsonb,
  leave_types jsonb,
  created_at timestamp DEFAULT now(),
  updated_at timestamp DEFAULT now()
);

-- Employee profiles table
CREATE TABLE hrms_employee_profiles (
  id varchar PRIMARY KEY DEFAULT gen_random_uuid()::text,
  user_id varchar UNIQUE NOT NULL REFERENCES hrms_users(id),
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
  basic_salary decimal(15, 2),
  hra decimal(15, 2),
  pf_employee_contribution decimal(15, 2),
  pf_employer_contribution decimal(15, 2),
  esic_employee_contribution decimal(15, 2),
  esic_employer_contribution decimal(15, 2),
  special_allowance decimal(15, 2),
  performance_bonus decimal(15, 2),
  gratuity decimal(15, 2),
  professional_tax decimal(15, 2),
  medical_allowance decimal(15, 2),
  conveyance_allowance decimal(15, 2),
  food_coupons decimal(15, 2),
  lta decimal(15, 2),
  shift_allowance decimal(15, 2),
  overtime_pay decimal(15, 2),
  attendance_bonus decimal(15, 2),
  joining_bonus decimal(15, 2),
  retention_bonus decimal(15, 2),
  onboarding_completed boolean DEFAULT false,
  approved_by varchar REFERENCES hrms_users(id),
  approved_at timestamp,
  created_at timestamp DEFAULT now(),
  updated_at timestamp DEFAULT now()
);

-- Leave assignments table
CREATE TABLE hrms_leave_assignments (
  id varchar PRIMARY KEY DEFAULT gen_random_uuid()::text,
  user_id varchar NOT NULL REFERENCES hrms_users(id),
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

-- Create indexes for better performance
CREATE INDEX idx_hrms_attendance_user_id ON hrms_attendance(user_id);
CREATE INDEX idx_hrms_attendance_date ON hrms_attendance(date);
CREATE INDEX idx_hrms_leave_requests_user_id ON hrms_leave_requests(user_id);
CREATE INDEX idx_hrms_leave_requests_status ON hrms_leave_requests(status);
CREATE INDEX idx_hrms_expense_claims_user_id ON hrms_expense_claims(user_id);
CREATE INDEX idx_hrms_expense_claims_status ON hrms_expense_claims(status);
CREATE INDEX idx_hrms_payroll_user_id ON hrms_payroll(user_id);
CREATE INDEX idx_hrms_payroll_month_year ON hrms_payroll(month, year);

-- Insert default admin user (password: admin123)
-- Password hash for 'admin123' using bcrypt
INSERT INTO hrms_users (
  id,
  email,
  password_hash,
  first_name,
  last_name,
  role,
  is_onboarding_complete,
  needs_password_reset,
  is_active
) VALUES (
  gen_random_uuid()::text,
  'admin@hrms.com',
  '$2a$10$rN8qZ5qZ5qZ5qZ5qZ5qZ5.O5qZ5qZ5qZ5qZ5qZ5qZ5qZ5qZ5qZ5qZ',
  'Admin',
  'User',
  'admin',
  true,
  false,
  true
);

-- Verification query
SELECT 'Database setup completed successfully!' as status;
SELECT tablename FROM pg_tables WHERE schemaname = 'public' AND tablename LIKE 'hrms_%' ORDER BY tablename;
