-- Total Cases vs Total Deaths
-- Shows the likelihood of dying if you contract covid in the U.S.
SELECT location, date, total_cases, total_deaths, 
	CONVERT(float, total_deaths)/CONVERT(float, total_cases) * 100 AS DeathPercentage
FROM CovidAnalysis..CovidDeaths
WHERE location LIKE '%states%' AND continent IS NOT NULL
ORDER BY location, date

-- Total Cases vs Population
-- Shows what percentage of population got Covid (U.S.)
SELECT location, date, population, total_cases, 
	CONVERT(float, total_cases)/CONVERT(float, population) * 100 AS InfectedPopulationPercentage
FROM CovidAnalysis..CovidDeaths
WHERE location LIKE '%states%'  AND continent IS NOT NULL
ORDER BY location, date

-- Countries with Highest Infection Rate compared to Population
SELECT location, population, 
	MAX(total_cases) AS HighestInfectionCount, 
	MAX(CONVERT(float, total_cases)/CONVERT(float, population)) * 100 AS InfectedPopulationPercentage
FROM CovidAnalysis..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location, population
ORDER BY InfectedPopulationPercentage DESC

-- Countries with Highest Death Count per Population
SELECT location, MAX(total_deaths) AS TotalDeathCount 
FROM CovidAnalysis..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY TotalDeathCount DESC
--Breaking down by Continent
SELECT location AS Continent,
	MAX(total_deaths) AS TotalDeathCount 
FROM CovidAnalysis..CovidDeaths
WHERE continent IS NULL
GROUP BY location
ORDER BY TotalDeathCount DESC

-- Total Death Count for each Continent
SELECT continent, SUM(new_deaths) as TotalDeathCount
FROM CovidAnalysis..CovidDeaths
WHERE continent IS NOT NULL AND location NOT IN ('World', 'European Union', 'International')
--European Union is part of Europe
GROUP BY continent
ORDER BY TotalDeathCount

-- Global Numbers
SELECT SUM(new_cases) AS TotalCases, SUM(new_deaths) AS TotalDeaths,
	SUM(CONVERT(float, new_deaths))/SUM(NULLIF(CONVERT(float, new_cases), 0)) * 100 AS DeathPercentage
FROM CovidAnalysis..CovidDeaths
WHERE continent IS NOT NULL


-- USING CTE to perform (RollingPeopleVaccinated/population)
--CTEs are temporary views
WITH PopvsVac (continent, location, date, population, new_vaccinations, RollingPeopleVaccinated) AS 
(
-- Looking at Total Population vs Vaccinations
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
	SUM(vac.new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea.date) AS RollingPeopleVaccinated
	--PARTITION BY restarts the rolling count by lcoation
	--ORDER BY allows you to see the numbers being added up
FROM CovidAnalysis..CovidDeaths dea
JOIN CovidAnalysis..CovidVaccinations vac
	ON dea.location = vac.location 
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
)
SELECT *, (RollingPeopleVaccinated * 100.0 /population) AS VaccinationPercentage
FROM PopvsVac
ORDER BY location, date

-- another way to do this is to use a TEMP TABLE (shown below)
--DROP TABLE if exists #PercentagePopulationVaccinated
--Create Table #PercentagePopulationVaccinated
--(
--Continent nvarchar(255),
--Location nvarchar(255),
--Date datetime,
--Population numeric,
--New_Vaccinations numeric,
--RollingPeopleVaccinated numeric
--)

--INSERT INTO #PercentagePopulationVaccinated
--...

-- a few of the Views
CREATE OR ALTER VIEW USDeathPercentage AS
SELECT location, date, total_cases, total_deaths, 
	CONVERT(float, total_deaths)/CONVERT(float, total_cases) * 100 AS DeathPercentage
FROM CovidAnalysis..CovidDeaths
WHERE location LIKE '%states%' 
	AND continent IS NOT NULL;

CREATE OR ALTER VIEW USInfectionPercentage AS
SELECT location, date, population, total_cases, 
	CONVERT(float, total_cases)/CONVERT(float, population) * 100 AS InfectedPopulationPercentage
FROM CovidAnalysis..CovidDeaths
WHERE location LIKE '%states%' 
	AND continent IS NOT NULL;

CREATE OR ALTER VIEW WorldInfectedPercentage AS
SELECT location, population, 
	MAX(total_cases) AS HighestInfectionCount, 
	MAX(CONVERT(float, total_cases)/CONVERT(float, population)) * 100 AS InfectedPopulationPercentage
FROM CovidAnalysis..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location, population

CREATE OR ALTER VIEW PercentPopulationVaccinated AS
WITH PopvsVac ([Continent], [Location], [Date], [Population], [New Vaccinations], [Rolling People Vaccinated]) AS
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
	SUM(vac.new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated
FROM CovidAnalysis..CovidDeaths dea
JOIN CovidAnalysis..CovidVaccinations vac
	ON dea.location = vac.location 
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
)
SELECT *, ([Rolling People Vaccinated] * 100.0 /population) AS [Vaccination Percentage]
FROM PopvsVac