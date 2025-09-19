# Clinic Booking System Database

## 📌 Project Overview
This project is a **relational database management system** for a **Clinic Booking System**, built using **MySQL**.  
The database supports key operations such as managing users (doctors, patients, admins), booking appointments, storing medical records, prescriptions, and handling payments.

The goal of this assignment is to design and implement a **complete relational schema** with proper constraints, relationships, and normalization.

---

## 🎯 Features
- **Users & Roles**  
  Supports multiple user roles (Admin, Doctor, Patient, Nurse, Receptionist).
- **Doctors & Specialties**  
  Doctors can have one or multiple specialties.
- **Clinics**  
  Multiple clinic branches, with doctors working at one or more clinics.
- **Appointments**  
  Patients can book appointments with doctors at specific times/clinics.
- **Medical Records & Prescriptions**  
  Doctors can record visit details and issue prescriptions.
- **Payments**  
  Tracks patient payments for appointments, integrated with external gateways like **IntaSend** or **M-PESA**.
- **Audit Logs**  
  Records system activities for traceability.

---

## 🏗️ Database Design

### Main Entities
- **roles** → Defines system roles (Admin, Doctor, Patient, etc.)  
- **users** → Core user table (linked to a role)  
- **doctors** → Extra info for doctors (license, bio, experience)  
- **patients** → Extra info for patients (medical record number, emergency contact)  
- **specialties** → Medical specialties (Cardiology, Pediatrics, etc.)  
- **clinics** → Clinic branches  
- **appointments** → Patient bookings with doctors  
- **medical_records** → Records of patient visits  
- **prescriptions** → Medications prescribed  
- **payments** → Payments linked to appointments  
- **audit_logs** → Activity logging  

### Relationships
- **One-to-One**:  
  - `users ↔ doctors`  
  - `users ↔ patients`
- **One-to-Many**:  
  - `patients ↔ appointments`  
  - `doctors ↔ appointments`  
  - `appointments ↔ prescriptions`
- **Many-to-Many**:  
  - `doctors ↔ specialties`  
  - `doctors ↔ clinics`

---

## ⚙️ Installation & Setup

### 1. Prerequisites
- MySQL Server (version 8+ recommended)
- MySQL Client / DBeaver / phpMyAdmin

### 2. Running the Schema
1. Clone or download the project.
2. Open MySQL terminal and run:
   ```sql
   SOURCE path/to/clinic_system.sql;


Or use a GUI (DBeaver / phpMyAdmin) to execute the script.

Verify database and tables:

SHOW DATABASES;
USE clinic_db;
SHOW TABLES;

3. Sample Data

The script inserts default roles (Admin, Doctor, Patient, Nurse, Receptionist).
You can extend it with test users, doctors, patients, and appointments.

🧩 Example Queries
Get all doctors and their specialties
SELECT u.first_name, u.last_name, s.name AS specialty
FROM doctors d
JOIN users u ON d.user_id = u.id
JOIN doctor_specialties ds ON d.id = ds.doctor_id
JOIN specialties s ON ds.specialty_id = s.id;

Find all appointments for a patient
SELECT a.id, a.scheduled_start, a.status, d.id AS doctor_id, u.first_name AS doctor_name
FROM appointments a
JOIN doctors d ON a.doctor_id = d.id
JOIN users u ON d.user_id = u.id
WHERE a.patient_id = 1;

List payments for completed appointments
SELECT p.id, p.amount, p.status, a.id AS appointment_id
FROM payments p
JOIN appointments a ON p.appointment_id = a.id
WHERE p.status = 'COMPLETED';

🛡️ Constraints & Integrity

Primary Keys → Ensure uniqueness of each record.

Foreign Keys → Enforce relationships between entities.

Unique Constraints → Prevent duplicate emails, license numbers, and medical record numbers.

Check Constraints → Ensure valid values (e.g., appointment times, day_of_week, payment amount ≥ 0).

Cascade Rules → Automatically update or delete related records where appropriate.

📖 Deliverables

clinic_system.sql → Database schema + roles seed data

README.md → Documentation (this file)

👨‍💻 Author

- Name: Salim Mbita

- Course: Database Management Systems

- Assignment: Complete DBMS Project – Clinic Booking System

- Date: September 2025