CREATE TYPE "public"."attendance_status" AS ENUM('present', 'absent', 'late', 'half_day');--> statement-breakpoint
CREATE TYPE "public"."expense_status" AS ENUM('submitted', 'approved', 'rejected', 'reimbursed');--> statement-breakpoint
CREATE TYPE "public"."leave_status" AS ENUM('pending', 'approved', 'rejected');--> statement-breakpoint
CREATE TYPE "public"."leave_type" AS ENUM('sick', 'vacation', 'personal', 'maternity', 'paternity');--> statement-breakpoint
CREATE TYPE "public"."user_role" AS ENUM('admin', 'manager', 'employee');--> statement-breakpoint
CREATE TABLE "announcements" (
	"id" varchar PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"title" varchar NOT NULL,
	"content" text NOT NULL,
	"priority" varchar DEFAULT 'normal',
	"author_id" varchar NOT NULL,
	"is_active" boolean DEFAULT true,
	"created_at" timestamp DEFAULT now()
);
--> statement-breakpoint
CREATE TABLE "attendance" (
	"id" varchar PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"user_id" varchar NOT NULL,
	"date" timestamp NOT NULL,
	"check_in" timestamp,
	"check_out" timestamp,
	"status" "attendance_status" DEFAULT 'present',
	"location" varchar,
	"location_name" varchar,
	"latitude" numeric(10, 8),
	"longitude" numeric(11, 8),
	"notes" text,
	"created_at" timestamp DEFAULT now()
);
--> statement-breakpoint
CREATE TABLE "company_settings" (
	"id" varchar PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"company_name" varchar NOT NULL,
	"office_locations" jsonb,
	"working_hours" jsonb,
	"leave_types" jsonb,
	"created_at" timestamp DEFAULT now(),
	"updated_at" timestamp DEFAULT now()
);
--> statement-breakpoint
CREATE TABLE "departments" (
	"id" varchar PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"name" varchar NOT NULL,
	"description" text,
	"created_by" varchar,
	"created_at" timestamp DEFAULT now(),
	"updated_at" timestamp DEFAULT now(),
	CONSTRAINT "departments_name_unique" UNIQUE("name")
);
--> statement-breakpoint
CREATE TABLE "designations" (
	"id" varchar PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"name" varchar NOT NULL,
	"description" text,
	"department_id" varchar,
	"created_by" varchar,
	"created_at" timestamp DEFAULT now(),
	"updated_at" timestamp DEFAULT now()
);
--> statement-breakpoint
CREATE TABLE "employee_profiles" (
	"id" varchar PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"user_id" varchar NOT NULL,
	"father_name" varchar,
	"date_of_birth" timestamp,
	"marriage_anniversary" timestamp,
	"personal_mobile" varchar,
	"emergency_contact_name" varchar,
	"emergency_contact_number" varchar,
	"emergency_contact_relation" varchar,
	"date_of_joining" timestamp,
	"designation" varchar,
	"pan_number" varchar,
	"aadhar_number" varchar,
	"bank_account_number" varchar,
	"ifsc_code" varchar,
	"bank_name" varchar,
	"bank_proof_document_path" varchar,
	"uan_number" varchar,
	"pf_number" varchar,
	"basic_salary" numeric(15, 2),
	"hra" numeric(15, 2),
	"pf_employee_contribution" numeric(15, 2),
	"pf_employer_contribution" numeric(15, 2),
	"esic_employee_contribution" numeric(15, 2),
	"esic_employer_contribution" numeric(15, 2),
	"special_allowance" numeric(15, 2),
	"performance_bonus" numeric(15, 2),
	"gratuity" numeric(15, 2),
	"professional_tax" numeric(15, 2),
	"medical_allowance" numeric(15, 2),
	"conveyance_allowance" numeric(15, 2),
	"food_coupons" numeric(15, 2),
	"lta" numeric(15, 2),
	"shift_allowance" numeric(15, 2),
	"overtime_pay" numeric(15, 2),
	"attendance_bonus" numeric(15, 2),
	"joining_bonus" numeric(15, 2),
	"retention_bonus" numeric(15, 2),
	"onboarding_completed" boolean DEFAULT false,
	"approved_by" varchar,
	"approved_at" timestamp,
	"created_at" timestamp DEFAULT now(),
	"updated_at" timestamp DEFAULT now(),
	CONSTRAINT "employee_profiles_user_id_unique" UNIQUE("user_id")
);
--> statement-breakpoint
CREATE TABLE "employee_salary_structure" (
	"id" varchar PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"user_id" varchar NOT NULL,
	"basic_salary" numeric(10, 2) NOT NULL,
	"hra" numeric(10, 2) DEFAULT '0.00',
	"conveyance_allowance" numeric(10, 2) DEFAULT '0.00',
	"medical_allowance" numeric(10, 2) DEFAULT '0.00',
	"special_allowance" numeric(10, 2) DEFAULT '0.00',
	"gross_salary" numeric(10, 2) NOT NULL,
	"provident_fund" numeric(10, 2) DEFAULT '0.00',
	"professional_tax" numeric(10, 2) DEFAULT '0.00',
	"income_tax" numeric(10, 2) DEFAULT '0.00',
	"other_deductions" numeric(10, 2) DEFAULT '0.00',
	"total_deductions" numeric(10, 2) NOT NULL,
	"net_salary" numeric(10, 2) NOT NULL,
	"effective_date" timestamp DEFAULT now(),
	"created_at" timestamp DEFAULT now(),
	"updated_at" timestamp DEFAULT now(),
	CONSTRAINT "employee_salary_structure_user_id_unique" UNIQUE("user_id")
);
--> statement-breakpoint
CREATE TABLE "expense_claims" (
	"id" varchar PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"user_id" varchar NOT NULL,
	"title" varchar NOT NULL,
	"amount" numeric(10, 2) NOT NULL,
	"category" varchar NOT NULL,
	"description" text,
	"receipt_url" varchar,
	"status" "expense_status" DEFAULT 'submitted',
	"approver_id" varchar,
	"approver_notes" text,
	"submission_date" timestamp DEFAULT now(),
	"approval_date" timestamp,
	"reimbursement_date" timestamp
);
--> statement-breakpoint
CREATE TABLE "leave_assignments" (
	"id" varchar PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"user_id" varchar NOT NULL,
	"year" integer NOT NULL,
	"annual_leave" integer DEFAULT 21,
	"sick_leave" integer DEFAULT 7,
	"casual_leave" integer DEFAULT 7,
	"maternity_leave" integer DEFAULT 84,
	"paternity_leave" integer DEFAULT 15,
	"annual_used" integer DEFAULT 0,
	"sick_used" integer DEFAULT 0,
	"casual_used" integer DEFAULT 0,
	"maternity_used" integer DEFAULT 0,
	"paternity_used" integer DEFAULT 0,
	"created_at" timestamp DEFAULT now(),
	"updated_at" timestamp DEFAULT now()
);
--> statement-breakpoint
CREATE TABLE "leave_requests" (
	"id" varchar PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"user_id" varchar NOT NULL,
	"type" "leave_type" NOT NULL,
	"start_date" timestamp NOT NULL,
	"end_date" timestamp NOT NULL,
	"days" integer NOT NULL,
	"reason" text,
	"status" "leave_status" DEFAULT 'pending',
	"approver_id" varchar,
	"approver_notes" text,
	"created_at" timestamp DEFAULT now(),
	"updated_at" timestamp DEFAULT now()
);
--> statement-breakpoint
CREATE TABLE "payroll" (
	"id" varchar PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"user_id" varchar NOT NULL,
	"month" integer NOT NULL,
	"year" integer NOT NULL,
	"basic_salary" numeric(10, 2) NOT NULL,
	"allowances" numeric(10, 2) DEFAULT '0',
	"deductions" numeric(10, 2) DEFAULT '0',
	"gross_salary" numeric(10, 2) NOT NULL,
	"net_salary" numeric(10, 2) NOT NULL,
	"salary_breakup" jsonb,
	"status" varchar DEFAULT 'draft',
	"processed_at" timestamp,
	"payslip_url" varchar,
	"created_at" timestamp DEFAULT now(),
	"updated_at" timestamp DEFAULT now()
);
--> statement-breakpoint
CREATE TABLE "sessions" (
	"sid" varchar PRIMARY KEY NOT NULL,
	"sess" jsonb NOT NULL,
	"expire" timestamp NOT NULL
);
--> statement-breakpoint
CREATE TABLE "users" (
	"id" varchar PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"email" varchar NOT NULL,
	"password_hash" varchar NOT NULL,
	"first_name" varchar NOT NULL,
	"last_name" varchar NOT NULL,
	"profile_image_url" varchar,
	"role" "user_role" DEFAULT 'employee',
	"is_onboarding_complete" boolean DEFAULT false,
	"needs_password_reset" boolean DEFAULT true,
	"department" varchar,
	"position" varchar,
	"manager_id" varchar,
	"salary" numeric(10, 2),
	"join_date" timestamp,
	"is_active" boolean DEFAULT true,
	"created_at" timestamp DEFAULT now(),
	"updated_at" timestamp DEFAULT now(),
	CONSTRAINT "users_email_unique" UNIQUE("email")
);
--> statement-breakpoint
ALTER TABLE "departments" ADD CONSTRAINT "departments_created_by_users_id_fk" FOREIGN KEY ("created_by") REFERENCES "public"."users"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "designations" ADD CONSTRAINT "designations_department_id_departments_id_fk" FOREIGN KEY ("department_id") REFERENCES "public"."departments"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "designations" ADD CONSTRAINT "designations_created_by_users_id_fk" FOREIGN KEY ("created_by") REFERENCES "public"."users"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "employee_profiles" ADD CONSTRAINT "employee_profiles_user_id_users_id_fk" FOREIGN KEY ("user_id") REFERENCES "public"."users"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "employee_profiles" ADD CONSTRAINT "employee_profiles_approved_by_users_id_fk" FOREIGN KEY ("approved_by") REFERENCES "public"."users"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "employee_salary_structure" ADD CONSTRAINT "employee_salary_structure_user_id_users_id_fk" FOREIGN KEY ("user_id") REFERENCES "public"."users"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "leave_assignments" ADD CONSTRAINT "leave_assignments_user_id_users_id_fk" FOREIGN KEY ("user_id") REFERENCES "public"."users"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
CREATE INDEX "IDX_session_expire" ON "sessions" USING btree ("expire");