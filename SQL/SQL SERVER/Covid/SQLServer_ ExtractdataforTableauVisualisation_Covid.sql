-- Extract data for Tableau Visualisation
-- Table 1
SELECT location, continent, SUM(new_cases) total_cases, SUM(new_deaths) total_deaths, SUM(new_deaths)/NULLIF(SUM(new_cases),0)*100 death_percentage
FROM CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location, continent;


-- Table 2
SELECT location, continent, population, MAX(total_cases) highest_infection_count, MAX(total_cases/population)* 100 percentage_population_infected
FROM CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location, continent, population
ORDER BY 5 DESC;

-- Table 3
SELECT location, continent, date, MAX(new_cases) new_infection_count
FROM CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location, continent, date
ORDER BY 2,1,4;
