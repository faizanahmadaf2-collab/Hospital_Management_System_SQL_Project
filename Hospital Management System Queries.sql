
use hospital_management_system;

select * from hospitals;
select * from doctors;
select * from patients;
select * from appointments;
select * from departments;
select * from medications;
select * from prescriptions;
select * from rooms;

-- Find all patients born after the year 2000

select patient_id, name, dob
from patients where Year(dob) > 2000;

-- Find all prescriptions for patient_id 5

select * from prescriptions
where patient_id = 5;

-- Show the number of appointments per month

select monthname(appointment_date) as month, count(*) as total_appointments 
from appointments
group by month order by total_appointments desc
;

-- List all medications that include the keywords pain or infection in the description

select * from medications
where description like '%pain%' or description like '%infection%'
;

-- Show all doctors with their hospital name

select doctors.doctor_id, doctors.name as doctor_name, hospitals.name as hospital_name
from doctors
join hospitals 
on doctors.hospital_id = hospitals.hospital_id;

-- Find the names, phones and appointment_dates of all patients with appointments in August 2025

select patients.name as patient_name, patients.phone, appointments.appointment_date
from patients
join appointments 
on patients.patient_id = appointments.patient_id
where month(appointments.appointment_date) = 8 and year(appointments.appointment_date) = 2025
order by appointments.appointment_date asc;

-- Show all room numbers and their capacities from the Neurology departments

select rooms.room_no, rooms.capacity, rooms.department_id, departments.name as department_name
from rooms
join departments
on rooms.department_id = departments.department_id
where departments.name = 'Neurology'
;

-- Count how many doctors work in each hospital

select hospitals.name as hospital_name, count(doctors.doctor_id) as total_doctors
from doctors
join hospitals
on doctors.hospital_id = hospitals.hospital_id
group by hospitals.hospital_id order by total_doctors desc;

-- Find patients who have more than 3 appointments

select patients.patient_id, patients.name as patient_name, count(appointments.appointment_id) as total_appointments
from patients
join appointments
on patients.patient_id = appointments.patient_id
group by patients.patient_id
having count(appointments.appointment_id) > 2;

-- List appointments with patient and doctor names

select appointments.appointment_id, patients.name as patient_name, doctors.name as doctor_name
from appointments
join patients on appointments.patient_id = patients.patient_id
join doctors on appointments.doctor_id = doctors.doctor_id
order by appointments.appointment_id asc;


-- For all the emergency appointments, show patient name, date of birth as well as
-- age-group:
-- 18 or below - Pediatric
-- 19 to 64 - Adult
-- 65 or above - Geriatric


select appointments.appointment_id, appointments.reason, patients.name, patients.dob as date_of_birth, 
	case 
		when timestampdiff(year, patients.dob, curdate()) <= 18 then "Pediatric"
		when timestampdiff(year, patients.dob, curdate()) between 19 and 64 then "Adult"
		else "Geriatric"
	end as age_group
from appointments
join patients
on appointments.patient_id = patients.patient_id
where reason = "Emergency"
;

-- Show all departments of Green Valley Medical Center

select hospitals.name as hospital_name, departments.name as department_name
from departments
join hospitals
on departments.hospital_id = hospitals.hospital_id
where hospitals.name = "Green Valley Medical Center"
;

-- Find patients who have never had a prescription

select patients.patient_id, patients.name, prescriptions.prescribed_date
from patients
left join prescriptions
on patients.patient_id = prescriptions.patient_id
where prescriptions.prescribed_date is null
;

-- List name, address and phone for patients who have appointments in more than one hospital

select patients.patient_id, patients.name, patients.address, patients.phone
from patients
join appointments on patients.patient_id = appointments.patient_id
join doctors on appointments.doctor_id = doctors.doctor_id
join hospitals on doctors.hospital_id = hospitals.hospital_id
group by patients.patient_id, patients.name, patients.address, patients.phone
having count(distinct hospitals.hospital_id) > 1;


-- Show the latest appointment for each patient

select patient_id, min(appointment_date)
from appointments
group by patient_id
order by patient_id;


select patients.patient_id, patients.name, min(appointment_date) as frist_appointment_date
from patients
join appointments
on patients.patient_id = appointments.patient_id
group by patients.patient_id, patients.name
;


-- Show the 3rd most frequently prescribed medication/medications



select medication_id, name, frequency
from (
	select m.medication_id, m.name, 
	count(p.prescription_id) as frequency,
	dense_rank() over (order by count(p.prescription_id) desc) as frequency_rank
	from medications m
	join prescriptions p
	on m.medication_id = p.medication_id
	group by m.medication_id, m.name) as medicines_frequency_ranks
where frequency = 3;


-- Show all hospitals with the lowest doctor count


select hospital_id, name, number_of_doctors
from 
	(select h.hospital_id, h.name, count(d.doctor_id) as number_of_doctors,
	dense_rank() over (order by count(d.doctor_id) asc) as docs_frequency
	from hospitals h
	join doctors d
	on h.hospital_id = d.hospital_id
	group by h.hospital_id, h.name) as docs_count_table
where docs_frequency = 1
;


-- Find the department with the second largest room capacity in each hospital


select hospital_id, hospital_name, department_id, department_name, max_capacity, department_rank_in_hospital
from (
	select h.hospital_id, h.name as hospital_name, d.department_id, d.name as department_name,
		max(r.capacity) as max_capacity,
		dense_rank() over (partition by h.hospital_id order by max(capacity) desc) as department_rank_in_hospital
	from departments d
	join hospitals h on d.hospital_id = h.hospital_id
	join rooms r on d.department_id = r.department_id
	group by h.hospital_id, h.name, d.department_id, d.name
    ) as hospitals_capacity
where department_rank_in_hospital = 2
;

-- Retrieve doctors whose total number of patients is above the hospital average.

with patient_count as (
	select d.doctor_id, d.hospital_id, count(distinct a.patient_id) as total_patients
	from doctors d 
	join appointments a on d.doctor_id = a.doctor_id
	group by d.doctor_id, d.hospital_id
),
hospital_avg as (
	select hospital_id, avg(total_patients) as avg_patients
    from patient_count
    group by hospital_id
)
select 
	pc.doctor_id, pc.hospital_id, pc.total_patients, avg_patients
    from patient_count pc
    join hospital_avg ha 
    on pc.hospital_id = ha.hospital_id
where pc.total_patients > ha.avg_patients;





































