-- =====================================
-- HR ANALYTICS - SQL EDA
-- IBM HR Attrition Dataset
-- =====================================

-- ============================================
-- SETUP: CREATE TABLE & IMPORT
-- ============================================

CREATE TABLE IF NOT EXISTS employees (
    Age INTEGER,
    Attrition VARCHAR(5),
    BusinessTravel VARCHAR(50),
    DailyRate INTEGER,
    Department VARCHAR(50),
    DistanceFromHome INTEGER,
    Education INTEGER,
    EducationField VARCHAR(50),
    EnvironmentSatisfaction INTEGER,
    Gender VARCHAR(10),
    HourlyRate INTEGER,
    JobInvolvement INTEGER,
    JobLevel INTEGER,
    JobRole VARCHAR(50),
    JobSatisfaction INTEGER,
    MaritalStatus VARCHAR(20),
    MonthlyIncome INTEGER,
    MonthlyRate INTEGER,
    NumCompaniesWorked INTEGER,
    Over18 VARCHAR(5),
    OverTime VARCHAR(5),
    PercentSalaryHike INTEGER,
    PerformanceRating INTEGER,
    RelationshipSatisfaction INTEGER,
    StandardHours INTEGER,
    StockOptionLevel INTEGER,
    TotalWorkingYears INTEGER,
    TrainingTimesLastYear INTEGER,
    WorkLifeBalance INTEGER,
    YearsAtCompany INTEGER,
    YearsInCurrentRole INTEGER,
    YearsSinceLastPromotion INTEGER,
    YearsWithCurrManager INTEGER
);

-- =====================================
-- SECTION 1: DATA PROFILING
-- =====================================

-- Total Row Count
select count(*) from employees;

-- Checking attrition distribution
select Attrition, count(*) as count, 
	round(count(*) * 100.0 / sum(count(*)) over(), 2) as percentage
	from employees group by Attrition;

-- Age distribution by bucket
select
	case
		when Age < 30 then 'Under 30'
		when Age between 30 and 40 then '30-40'
		when Age between 41 and 50 then '41-50'
		else 'Over 50'
	end as age_group, count(*) as count from employees
	group by age_group order by count desc;

-- Department Distribution
select Department, count(*) as count from employees
	group by Department order by count desc; 

-- Gender Distribution
select Gender, count(*) as count,
	round(count(*) * 100.0 / sum(count(*)) over(), 2) as percentage
	from employees group by Gender;

-- Overtime Distribution
select OverTime, count(*) as count,
	round(count(*) * 100.0 / sum(count(*)) over(), 2) as percentage
	from employees group by OverTime;

-- =====================================
-- SECTION 2: ATTRITION ANALYSIS
-- =====================================

-- Attrition rate by department
-- Using rate not count because departments are different sizes
with dept_attrition as (
	select Department, count(*) as total,
	sum(case when Attrition = 'Yes' then 1 else 0 end) as left_count
	from employees group by Department
)
select Department, total, left_count,
	round(left_count * 100.0 / total, 2) as attrition_rate
	from dept_attrition order by attrition_rate desc;

-- Attrition by job role
with role_attrition as (
	select JobRole, count(*) as total,
	sum(case when Attrition = 'Yes' then 1 else 0 end) as left_count
	from employees group by JobRole
)
select JobRole, total, left_count,
	round(left_count * 100.0 / total, 2) as attrition_rate
	from role_attrition order by attrition_rate desc;

-- Overtime vs Non-Overtime attrition
-- Strongest finding
select OverTime, count(*) as total,
	sum(case when Attrition = 'Yes' then 1 else 0 end) as left_count,
	round(sum(case when Attrition = 'Yes' then 1 else 0 end) * 100.0 / count(*), 2) as attrition_rate
	from employees group by OverTime order by attrition_rate desc;

-- Attrition by age group
select
	case
		when Age < 30 then 'Under 30'
		when Age between 30 and 40 then '30-40'
		when Age between 41 and 50 then '41-50'
		else 'Over 50'
	end as age_group,
	count(*) as total,
	sum(case when Attrition = 'Yes' then 1 else 0 end) as left_count,
	round(sum(case when Attrition = 'Yes' then 1 else 0 end) * 100.0 / count(*), 2) as attrition_rate
	from employees group by age_group order by attrition_rate desc;

--Average tenure of employees who left vs stayed
select Attrition,
	round(avg(YearsAtCompany), 2) as avg_tenure,
	round(avg(TotalWorkingYears), 2) as avg_total_experience,
	round(avg(Age), 2) as avg_age
	from employees group by Attrition;

-- Attrition by marital status
select MaritalStatus,
	count(*) as total,
	sum(case when Attrition = 'Yes' then 1 else 0 end) as left_count,
	round(sum(case when Attrition = 'Yes' then 1 else 0 end) * 100.0 / count(*), 2) as attrition_rate
	from employees group by MaritalStatus order by attrition_rate desc;

-- =====================================
-- SECTION 3: COMPENSATION ANALYSIS
-- =====================================

-- Average monthly income by job role
select JobRole,
	round(avg(MonthlyIncome), 2) as avg_income,
	count(*) as employee_count
	from employees group by JobRole order by avg_income desc;

-- Average income by department
select Department,
	round(avg(MonthlyIncome), 2) as avg_income,
	round(min(MonthlyIncome), 2) as min_income,
	round(max(MonthlyIncome), 2) as max_income
	from employees group by Department order by avg_income desc;

-- Income gap between employees who stayed vs left
select Attrition,
	round(avg(MonthlyIncome), 2) as avg_income,
	round(min(MonthlyIncome), 2) as min_income,
	round(max(MonthlyIncome), 2) as max_income
	from employees group by Attrition;

-- Gender pay comparison within the same job role
select JobRole, Gender,
	round(avg(MonthlyIncome), 2) as avg_income,
	count(*) as count
	from employees group by JobRole, Gender
	order by JobRole, Gender;

-- Income vs job satisfaction
select JobSatisfaction,
	round(avg(MonthlyIncome), 2) as avg_income,
	count(*) as employee_count,
	sum(case when Attrition = 'Yes' then 1 else 0 end) as left_count,
	round(sum(case when Attrition = 'Yes' then 1 else 0 end) * 100.0 / count(*), 2) as attrition_rate
	from employees group by JobSatisfaction order by JobSatisfaction; 

-- Salary hike vs attrition
select Attrition,
	round(avg(PercentSalaryHike), 2) as avg_salary_hike,
	round(avg(PerformanceRating), 2) as avg_performance_rating
	from employees group by Attrition;

-- Employees earning below department average (window function)
select EmployeeNumber, Department, JobRole, MonthlyIncome,
	round(avg(MonthlyIncome) over (partition by Department), 2) as diff_from_avg
	from employees order by diff_from_avg asc limit 20;

-- =====================================
-- SECTION 4: SATISFACTION & PERFORMANCE
-- =====================================

-- Environment satisfaction vs attrition
select EnvironmentSatisfaction,
	count(*) as total,
	sum(case when Attrition = 'Yes' then 1 else 0 end) as left_count,
	round(sum(case when Attrition = 'Yes' then 1 else 0 end) * 100.0 / count(*), 2) as attrition_rate
	from employees group by EnvironmentSatisfaction order by EnvironmentSatisfaction;

-- work life balance vs attrition
select WorkLifeBalance,
	count(*) as total,
	sum(case when Attrition = 'Yes' then 1 else 0 end) as left_count,
	round(sum(case when Attrition = 'Yes' then 1 else 0 end) * 100.0 / count(*), 2) as attrition_rate
	from employees group by WorkLifeBalance order by WorkLifeBalance;

-- Relationship satisfaction vs attrition
select RelationshipSatisfaction,
	count(*) as total,
	sum(case when Attrition = 'Yes' then 1 else 0 end) as left_count,
	round(sum(case when Attrition = 'Yes' then 1 else 0 end) * 100.0 / count(*), 2) as attrition_rate
	from employees group by RelationshipSatisfaction order by RelationshipSatisfaction;

-- Training vs performance rating
select TrainingTimesLastYear,
	round(avg(PerformanceRating), 2) as avg_performance,
	count(*) as employee_count,
	round(sum(case when Attrition = 'Yes' then 1 else 0 end) * 100.0 / count(*), 2) as attrition_rate
	from employees group by TrainingTimesLastYear order by TrainingTimesLastYear;

-- Years since promotion vs attrition
select YearsSinceLastPromotion,
	count(*) as total,
	sum(case when Attrition = 'Yes' then 1 else 0 end) as left_count,
	round(sum(case when Attrition = 'Yes' then 1 else 0 end) * 100.0 / count(*), 2) as attrition_rate
	from employees group by YearsSinceLastPromotion order by attrition_rate desc
	limit 10;

-- Job Involvement vs attrition
select JobInvolvement,
	count(*) as total,
	sum(case when Attrition = 'Yes' then 1 else 0 end) as left_count,
	round(sum(case when Attrition = 'Yes' then 1 else 0 end) * 100.0 / count(*), 2) as attrition_rate
	from employees group by JobInvolvement order by JobInvolvement;

-- Stock options vs attrition
select StockOptionLevel,
	count(*) as total,
	sum(case when Attrition = 'Yes' then 1 else 0 end) as left_count,
	round(sum(case when Attrition = 'Yes' then 1 else 0 end) * 100.0 / count(*), 2) as attrition_rate
	from employees group by StockOptionLevel order by StockOptionLevel;

-- =====================================
-- SECTION 5: ADVANCED ANALYSIS
-- =====================================

-- Rank employees by salary within their department
select EmployeeNumber, Department, JobRole, MonthlyIncome,
	Rank() over (partition by Department order by MonthlyIncome desc) as salary_rank
	from employees order by department, salary_rank;

-- Running count of attrition by age
select Age,
	sum(case when Attrition = 'Yes' then 1 else 0 end) as left_count,
	sum(sum(case when Attrition = 'Yes' then 1 else 0 end)) over (order by Age) as running_total_attrition
	from employees group by Age order by Age;

-- Identify high risk employees
-- Overtime + low satisfaction + low income + young age
select EmployeeNumber, Age, Department, JobRole, MonthlyIncome, JobSatisfaction,
	EnvironmentSatisfaction, WorkLifeBalance, OverTime, YearsAtCompany
	from employees where
	OverTime = 'Yes' and JobSatisfaction <= 2 and EnvironmentSatisfaction <= 2
	and MonthlyIncome < 5000 and Attrition = 'No'
	order by MonthlyIncome asc;

-- Department summary scorecard
select Department,
	count(*) as total_employees,
	round(avg(MonthlyIncome), 2) as avg_income,
	round(avg(JobSatisfaction), 2) as avg_job_satisfaction,
	round(avg(WorkLifeBalance), 2) as avg_work_life_balance,
	round(avg(YearsAtCompany), 2) as avg_tenure,
	sum(case when OverTime = 'Yes' then 1 else 0 end) as overtime_count,
	round(sum(case when Attrition = 'Yes' then 1 else 0 end) * 100.0 / count(*), 2) as attrition_rate
	from employees group by Department order by attrition_rate desc;

-- =====================================
-- SECTION 6: SALES DEPARTMENT DEEP DIVE
-- =====================================

-- Full satisfaction profile of Sales vs other departments
select Department,
	round(avg(JobSatisfaction), 2) as avg_job_satisfaction,
	round(avg(EnvironmentSatisfaction), 2) as avg_environment_satisfaction,
	round(avg(RelationshipSatisfaction), 2) as avg_relationship_satisfaction,
	round(avg(WorkLifeBalance), 2) as avg_work_life_balance,
	round(avg(JobInvolvement), 2) as avg_job_involvement
	from employees group by Department order by Department; 

-- Sales attrition broken down by job role within Sales
select JobRole,
	count(*) as total,
	sum(case when Attrition = 'Yes' then 1 else 0 end) as left_count,
	round(sum(case when Attrition = 'Yes' then 1 else 0 end) * 100.0 / count(*), 2) as attrition_rate,
	round(avg(MonthlyIncome), 2) as avg_income,
	round(avg(JobSatisfaction), 2) as avg_job_satisfaction
	from employees where Department = 'Sales'
	group by JobRole order by attrition_rate desc;

-- Sales attrition by years at company
-- Are sales people leaving early or after long tenure?
select Department,
	case
		when YearsAtCompany <= 2 then '0-2 Years'
		when YearsAtCompany between 3 and 5 then '3-5 Years'
		when YearsAtCompany between 6 and 10 then '6-10 Years'
		else 'Over 10 Years'
	end as tenure_band,
	count(*) as total,
	sum(case when Attrition = 'Yes' then 1 else 0 end) as left_count,
	round(sum(case when Attrition = 'Yes' then 1 else 0 end) * 100.0 / count(*), 2) as attrition_rate
	from employees where Department = 'Sales'
	group by Department, tenure_band order by attrition_rate desc;

-- Sales vs other departments: years since promotion
select Department,
	round(avg(YearsSinceLastPromotion), 2) as avg_years_since_promotion,
	round(avg(YearsInCurrentRole), 2) as avg_years_in_role,
	round(avg(StockOptionLevel), 2) as avg_stock_options
	from employees group by Department order by avg_years_since_promotion desc;

-- Distance from home for sales vs other departments
-- Sales roles often require travel - could be a factor
select Department,
	round(avg(DistanceFromHome), 2) as avg_distance,
	sum(case when DistanceFromHome > 20 then 1 else 0 end) as far_commuters,
	count(*) as total,
	round(sum(case when DistanceFromHome >20 then 1 else 0 end) * 100.0 / count(*), 2) as far_commuter_pct
	from employees group by Department order by avg_distance desc;

-- Business travel impact on sales attrition specifically
select Department, BusinessTravel,
	count(*) as total,
	sum(case when Attrition = 'Yes' then 1 else 0 end) as left_count,
	round(sum(case when Attrition = 'Yes' then 1 else 0 end) * 100.0 / count(*), 2) as attrition_rate
	from employees where Department = 'Sales'
	group by Department, BusinessTravel order by attrition_rate desc;
	
	