-- clinic_system.sql
-- Clinic Booking System schema (MySQL / InnoDB)
-- Creates database, tables, constraints, and relationships

DROP DATABASE IF EXISTS clinic_db;
CREATE DATABASE clinic_db CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;
USE clinic_db;

-- Roles (Admin, Doctor, Patient, Receptionist, Nurse, etc.)
CREATE TABLE roles (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(50) NOT NULL UNIQUE,
    description VARCHAR(255)
) ENGINE=InnoDB;

-- Users: base for Patients, Doctors, Admins
CREATE TABLE users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    role_id INT NOT NULL,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    email VARCHAR(255) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL, -- store password hashes, not plaintext
    phone VARCHAR(30),
    date_of_birth DATE,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT fk_users_role FOREIGN KEY (role_id) REFERENCES roles(id) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB;

-- Doctors: one-to-one with users (role must be Doctor in practice)
CREATE TABLE doctors (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL UNIQUE, -- each doctor is a user
    license_number VARCHAR(100) UNIQUE,
    bio TEXT,
    years_experience INT DEFAULT 0,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_doctors_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;

-- Patients: optional separate table linking to users (one-to-one)
CREATE TABLE patients (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL UNIQUE,
    medical_record_number VARCHAR(100) UNIQUE,
    emergency_contact_name VARCHAR(150),
    emergency_contact_phone VARCHAR(30),
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_patients_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;

-- Specialties (Cardiology, Pediatrics, etc.)
CREATE TABLE specialties (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(150) NOT NULL UNIQUE,
    description VARCHAR(255)
) ENGINE=InnoDB;

-- Many-to-many: doctors <-> specialties
CREATE TABLE doctor_specialties (
    doctor_id INT NOT NULL,
    specialty_id INT NOT NULL,
    PRIMARY KEY (doctor_id, specialty_id),
    CONSTRAINT fk_ds_doctor FOREIGN KEY (doctor_id) REFERENCES doctors(id) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_ds_specialty FOREIGN KEY (specialty_id) REFERENCES specialties(id) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;

-- Clinics (physical locations)
CREATE TABLE clinics (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(200) NOT NULL,
    address VARCHAR(300),
    phone VARCHAR(30),
    email VARCHAR(255),
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

-- Many-to-many: doctors working at clinics (a doctor can work at multiple clinics)
CREATE TABLE clinic_doctors (
    clinic_id INT NOT NULL,
    doctor_id INT NOT NULL,
    PRIMARY KEY (clinic_id, doctor_id),
    CONSTRAINT fk_cd_clinic FOREIGN KEY (clinic_id) REFERENCES clinics(id) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_cd_doctor FOREIGN KEY (doctor_id) REFERENCES doctors(id) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;

-- Doctor availability / schedule slots (simple model)
CREATE TABLE doctor_availabilities (
    id INT AUTO_INCREMENT PRIMARY KEY,
    doctor_id INT NOT NULL,
    clinic_id INT, -- optional: availability at a specific clinic
    day_of_week TINYINT NOT NULL, -- 0 = SUN .. 6 = SAT
    start_time TIME NOT NULL,
    end_time TIME NOT NULL,
    note VARCHAR(255),
    CONSTRAINT fk_avail_doctor FOREIGN KEY (doctor_id) REFERENCES doctors(id) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_avail_clinic FOREIGN KEY (clinic_id) REFERENCES clinics(id) ON DELETE SET NULL ON UPDATE CASCADE,
    CHECK (day_of_week BETWEEN 0 AND 6),
    CHECK (start_time < end_time)
) ENGINE=InnoDB;

-- Appointments: a patient books with a doctor (optionally at a clinic)
CREATE TABLE appointments (
    id INT AUTO_INCREMENT PRIMARY KEY,
    patient_id INT NOT NULL,
    doctor_id INT NOT NULL,
    clinic_id INT,
    scheduled_start DATETIME NOT NULL,
    scheduled_end DATETIME NOT NULL,
    status ENUM('REQUESTED','CONFIRMED','RESCHEDULED','COMPLETED','CANCELLED','NO_SHOW') NOT NULL DEFAULT 'REQUESTED',
    reason VARCHAR(255),
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT fk_appt_patient FOREIGN KEY (patient_id) REFERENCES patients(id) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_appt_doctor FOREIGN KEY (doctor_id) REFERENCES doctors(id) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_appt_clinic FOREIGN KEY (clinic_id) REFERENCES clinics(id) ON DELETE SET NULL ON UPDATE CASCADE,
    CHECK (scheduled_start < scheduled_end)
) ENGINE=InnoDB;

-- Ensure a doctor cannot have overlapping appointments (partial enforcement via index + application logic)
-- This index helps detect overlaps faster; full overlap prevention requires transaction + checks in app.
CREATE INDEX idx_appt_doctor_time ON appointments (doctor_id, scheduled_start, scheduled_end);

-- Medical records (visits, notes). Many-to-one: patient has many records; each record optionally by a doctor.
CREATE TABLE medical_records (
    id INT AUTO_INCREMENT PRIMARY KEY,
    patient_id INT NOT NULL,
    doctor_id INT, -- doctor who created the record (nullable if created by admin)
    appointment_id INT, -- optional link to appointment
    record_date DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    summary TEXT,
    details TEXT,
    CONSTRAINT fk_mr_patient FOREIGN KEY (patient_id) REFERENCES patients(id) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_mr_doctor FOREIGN KEY (doctor_id) REFERENCES doctors(id) ON DELETE SET NULL ON UPDATE CASCADE,
    CONSTRAINT fk_mr_appointment FOREIGN KEY (appointment_id) REFERENCES appointments(id) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB;

-- Prescriptions: linked to an appointment (one appointment can produce multiple prescriptions)
CREATE TABLE prescriptions (
    id INT AUTO_INCREMENT PRIMARY KEY,
    appointment_id INT NOT NULL,
    prescribed_by INT NOT NULL, -- doctor id
    prescription_date DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    medication TEXT NOT NULL,
    dosage_instructions TEXT,
    notes TEXT,
    CONSTRAINT fk_rx_appointment FOREIGN KEY (appointment_id) REFERENCES appointments(id) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_rx_doctor FOREIGN KEY (prescribed_by) REFERENCES doctors(id) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB;

-- Payments (e.g., for appointments). Keep basic fields; integrate with payment gateway externally.
CREATE TABLE payments (
    id INT AUTO_INCREMENT PRIMARY KEY,
    appointment_id INT,
    patient_id INT NOT NULL,
    amount DECIMAL(10,2) NOT NULL CHECK (amount >= 0),
    currency VARCHAR(10) NOT NULL DEFAULT 'KES',
    payment_method ENUM('CASH','CARD','M-PESA','INTASEND','OTHER') NOT NULL DEFAULT 'INTASEND',
    status ENUM('PENDING','COMPLETED','FAILED','REFUNDED') NOT NULL DEFAULT 'PENDING',
    transaction_reference VARCHAR(255) UNIQUE,
    paid_at DATETIME,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_pay_appointment FOREIGN KEY (appointment_id) REFERENCES appointments(id) ON DELETE SET NULL ON UPDATE CASCADE,
    CONSTRAINT fk_pay_patient FOREIGN KEY (patient_id) REFERENCES patients(id) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;

-- Audit logs (simple)
CREATE TABLE audit_logs (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    user_id INT,
    action VARCHAR(150) NOT NULL,
    object_type VARCHAR(100),
    object_id VARCHAR(100),
    details TEXT,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_audit_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB;

-- Example seed data for roles (optional)
INSERT INTO roles (name, description) VALUES
('Admin', 'System administrator'),
('Doctor', 'Medical doctor'),
('Patient', 'Patient / client'),
('Receptionist', 'Front desk staff'),
('Nurse', 'Nursing staff');


-- End of schema
