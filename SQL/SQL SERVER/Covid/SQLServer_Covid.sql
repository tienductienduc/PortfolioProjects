-- Data Cleaning
-- 1. Remove Duplicates
-- 2. Standardize the Data
-- 3. Null Values or blank values
-- 4. Remove Any Columns
-- By now, I just want to make sure that the data types are correct to use, the data is too big with many columns and rows, so checking for duplicates and removing null values should take a lot of time
-- Some columns has wrong datatypes when imported (in both table), I can use CAST() function, but I decide to change the datatype in the database to smoothen the workflow
ALTER TABLE CovidDeaths
ALTER COLUMN total_cases float;
ALTER TABLE CovidDeaths
ALTER COLUMN total_deaths float;

ALTER TABLE CovidVaccinations
ALTER COLUMN total_tests float;
ALTER TABLE CovidVaccinations
ALTER COLUMN new_tests float;
ALTER TABLE CovidVaccinations
ALTER COLUMN total_vaccinations float;
ALTER TABLE CovidVaccinations
ALTER COLUMN people_vaccinated float;
ALTER TABLE CovidVaccinations
ALTER COLUMN people_fully_vaccinated float;

-- Take a look at the data
-- The original file is big with many columns, so I divided it into 2 separate tables with grouped data for better computer efficiency when exploring data
SELECT *
FROM CovidVaccinations
ORDER BY 3,4;

SELECT *
FROM CovidVaccinations
ORDER BY 3,4;

-- Select the data that I'm going to use
SELECT location, date, total_cases, total_deaths, population
FROM CovidDeaths
ORDER BY 1,2;


-- I want to see the total cases/deaths in each continent, by year, and overall the time
-- Cases/Deaths by Year in each Continent
SELECT continent, YEAR(date) yearly, MAX(total_cases) cases, MAX(total_deaths) deaths
FROM CovidDeaths
WHERE continent IS NOT NULL
GROUP BY continent, YEAR(date)
ORDER BY 2,1;

-- Cases/Deaths all time all over the world
SELECT location, MAX(total_cases) cases, MAX(total_deaths) deaths
FROM CovidDeaths
WHERE location = 'World'
GROUP BY location;

-- Percentage deaths on cases in each COUNTRY, overall the time
WITH deaths_cases_location AS
(SELECT location, MAX(total_deaths) total_deaths, MAX(total_cases) total_cases
FROM CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location)

SELECT location, total_deaths/NULLIF(total_cases,0)*100 deaths_on_cases_percentage
FROM deaths_cases_location
ORDER BY 2 DESC;

-- Percentage deaths on cases in each CONTINENT, overall the time
WITH deaths_cases_location AS
(SELECT continent, MAX(total_deaths) total_deaths, MAX(total_cases) total_cases
FROM CovidDeaths
WHERE continent IS NOT NULL
GROUP BY continent)

SELECT continent, total_deaths/NULLIF(total_cases,0)*100 deaths_on_cases_percentage
FROM deaths_cases_location
ORDER BY 2 DESC;


-- I want to see the total cases and deaths compared to each country's population all over the time
-- Cases on Population in each country
SELECT location, MAX(population) population, MAX(total_cases) cases, MAX(total_cases)/MAX(population)*100 DeathPercentage
FROM CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY 4 DESC;

-- Deaths on Population in each country
SELECT location, MAX(population) population, MAX(total_deaths) deaths, MAX(total_deaths)/MAX(population)*100 DeathPercentage
FROM CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY 4 DESC;

-- Deaths on Population in each CONTINENT
SELECT continent, MAX(population) population, MAX(total_deaths) deaths, MAX(total_deaths)/MAX(population)*100 DeathPercentage
FROM CovidDeaths
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY 4 DESC;

-- Total deaths on Population in Cyprus over time
SELECT location, YEAR(date) yearly, MAX(population) population, SUM(new_deaths) total_deaths, SUM(new_deaths)/MAX(population)*100 DeathPercentage
FROM CovidDeaths
WHERE location = 'Cyprus'
GROUP BY location, YEAR(date)


-- JOIN TABLES and checkout other data
-- Vaccinated People on Population each Country
SELECT dea.location, MAX(people_vaccinated) people_vaccinated, MAX(dea.population) population, MAX(people_vaccinated)/NULLIF(MAX(dea.population),0)*100 Pct_vaccinated_population
FROM CovidDeaths dea
JOIN CovidVaccinations vac
ON dea.location = vac.location AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
GROUP BY dea.location
ORDER BY 1;

-- Vaccinated People on Population each Continent
SELECT dea.continent, MAX(people_vaccinated) people_vaccinated, MAX(dea.population) population, MAX(people_vaccinated)/NULLIF(MAX(dea.population),0)*100 Pct_vaccinated_population
FROM CovidDeaths dea
JOIN CovidVaccinations vac
ON dea.location = vac.location AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
GROUP BY dea.continent
ORDER BY 4;

-- New Vaccinations and Vaccinated People over time in Vietnam
SELECT location, date, new_vaccinations, SUM(new_vaccinations) OVER(ORDER BY date) Rolling_new_vaccinations, people_vaccinated
FROM CovidVaccinations
WHERE location = 'Vietnam' AND date > '03-06-2021' -- date condition just to remove the NULL value due to no vaccinations
ORDER BY 2;

-- Use the result from above query as a TEMP TABLE for later use
DROP TABLE IF EXISTS #VietnamVaccinatedTemp
CREATE TABLE #VietnamVaccinatedTemp (location nvarchar(255),  date datetime, new_vaccinations bigint, Rolling_new_vaccinations bigint, people_vaccinated bigint)
INSERT INTO #VietnamVaccinatedTemp 
SELECT location, date, new_vaccinations, SUM(new_vaccinations) OVER(ORDER BY date) Rolling_new_vaccinations, people_vaccinated
FROM CovidVaccinations
WHERE location = 'Vietnam' AND date > '03-06-2021' -- date condition just to remove the NULL value due to no vaccinations
ORDER BY 2;

SELECT *
FROM #VietnamVaccinatedTemp;

-- Creating View to store data for later visualizations
DROP VIEW IF EXISTS Percent_vaccinated_population

CREATE VIEW Percent_vaccinated_population AS
(SELECT dea.location, MAX(people_vaccinated) people_vaccinated, MAX(dea.population) population, MAX(people_vaccinated)/NULLIF(MAX(dea.population),0)*100 Pct_vaccinated_population
FROM CovidDeaths dea
JOIN CovidVaccinations vac
ON dea.location = vac.location AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
GROUP BY dea.location)

SELECT *
FROM Percent_vaccinated_population
ORDER BY 1
