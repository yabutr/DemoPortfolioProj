-- Covid Deaths Table

SELECT *
FROM PortfolioProject.dbo.CovidDeaths$
Where Continent is not null
ORDER BY 1,2

--SELECT *
--FROM PortfolioProject.DBO.CovidVaccinations$
--ORDER BY 1,2

-- Selecting data that we want

SELECT Location
	, date
	, total_cases
	, new_cases
	, total_deaths
	, population 
FROM PortfolioProject.DBO.CovidDeaths$
Where Continent is not null

-- Looking at Total Cases vs Total Deaths

SELECT Location,
	date,
	total_cases,
	total_deaths,
	(total_deaths/total_cases)*100 as DeathPercentage
FROM PortfolioProject.DBO.CovidDeaths$
WHERE Location like '%states%'
Where Continent is not null
ORDER BY 1,2

-- Looking at Cases vs Population
-- Shows what percentage of population got covid

SELECT Location,
	date,
	total_cases,
	population,
	(total_cases/population)*100 as PopulationPercentage
FROM PortfolioProject.DBO.CovidDeaths$
WHERE Location like '%states%'
Where Continent is not null
ORDER BY 1,2

-- Looking at counties with highest infection rate compared to population

SELECT Location,
	population,
	MAX(total_cases) as HighestInfectionCount,
	MAX((total_cases/population)*100) as PercentagePopulationInfected
FROM PortfolioProject.DBO.CovidDeaths$
Where Continent is not null
GROUP BY location, population
ORDER BY PercentagePopulationInfected DESC


-- Showing countries with the Highest Death Count per Population

SELECT LOCATION,
	MAX(cast(total_deaths as int)) as TotalDeathCount
FROM PortfolioProject.DBO.CovidDeaths$
Where Continent is not null
GROUP BY location
ORDER BY TotalDeathCount desc


-- Lets break things down by Continent
-- Showing continents with the highest death count per population

SELECT continent
	, MAX(cast(total_deaths as int)) as TotalDeathCount
FROM PortfolioProject.DBO.CovidDeaths$
Where Continent is not null
GROUP BY continent
ORDER BY TotalDeathCount desc


-- Global Numbers by date

SELECT date
	, SUM(new_cases) as total_cases
	, SUM(cast(new_deaths as int)) as total_deaths
	, SUM(cast(new_deaths as int))/SUM(new_cases)*100 AS DeathPercentage
FROM PortfolioProject.DBO.CovidDeaths$
--WHERE Location like '%states%'
Where Continent is not null
GROUP BY date
ORDER BY 1,2

-- Global numbers total

SELECT SUM(new_cases) as total_cases
	, SUM(cast(new_deaths as int)) as total_deaths
	, SUM(cast(new_deaths as int))/SUM(new_cases)*100 AS DeathPercentage
FROM PortfolioProject.DBO.CovidDeaths$
Where Continent is not null
ORDER BY 1,2


-- Joining covid deaths and vaccinations tables

SELECT *
FROM PortfolioProject.dbo.CovidDeaths$ dea --'dea' is alias for covid death table
JOIN PortfolioProject.dbo.CovidVaccinations$ vac --'vac' is alias for covid vaccinations table
	ON dea.location = vac.location
	and dea.date = vac.date


-- Looking at total population vs vaccinations

SELECT dea.continent
	, dea.location
	, dea.date
	, dea.population
	, vac.new_vaccinations
FROM PortfolioProject.dbo.CovidDeaths$ dea
JOIN PortfolioProject.dbo.CovidVaccinations$ vac
	ON dea.location = vac.location
	and dea.date = vac.date
WHERE dea.continent is not null
ORDER BY 2,3


-- Rolling new vaccinations

SELECT dea.continent
	, dea.location
	, dea.date
	, dea.population
	, vac.new_vaccinations
	, SUM(cast(vac.new_vaccinations as INT)) OVER (Partition BY dea.location ORDER BY dea.location, dea.date) as RollingPeopleVaccinated
FROM PortfolioProject.dbo.CovidDeaths$ dea
JOIN PortfolioProject.dbo.CovidVaccinations$ vac
	ON dea.location = vac.location
	and dea.date = vac.date
WHERE dea.continent is not null
ORDER BY 2,3


-- User created column in Select statemnt arithmetic (RollingPeopleVaccinated)
-- Try to get a rolling percentage of population that are becoming vaccinated

-- Cannot use RollingPeopleVaccinated in select statement arithmetic
SELECT dea.continent
	, dea.location
	, dea.date
	, dea.population
	, vac.new_vaccinations
	, SUM(cast(vac.new_vaccinations as INT)) OVER (Partition BY dea.location ORDER BY dea.location, dea.date) as RollingPeopleVaccinated
	, (RollingPeopleVaccinated/population) *100
FROM PortfolioProject.dbo.CovidDeaths$ dea
JOIN PortfolioProject.dbo.CovidVaccinations$ vac
	ON dea.location = vac.location
	and dea.date = vac.date
WHERE dea.continent is not null
ORDER BY 2,3

-- USING CTE to include user created column in select statement arithmetic

WITH PopvsVac (Continent, Location, Date, Population, new_vaccinations, RollingPeopleVaccinated)
as 
(
SELECT dea.continent
	, dea.location
	, dea.date
	, dea.population
	, vac.new_vaccinations
	, SUM(cast(vac.new_vaccinations as INT)) OVER (Partition BY dea.location ORDER BY dea.location, dea.date) as RollingPeopleVaccinated
FROM PortfolioProject.dbo.CovidDeaths$ dea
JOIN PortfolioProject.dbo.CovidVaccinations$ vac
	ON dea.location = vac.location
	and dea.date = vac.date
WHERE dea.continent is not null
)
SELECT *
	, (RollingPeopleVaccinated/Population)*100
FROM PopvsVac



-- Temporary Table

--'drop table if exist' is helpful when changes need to be made to table
DROP TABLE IF EXISTS #PercentPopulationVaccinated 
Create Table #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric, 
new_vaccinations numeric,
RollingPeopleVaccinated numeric
)

INSERT INTO #PercentPopulationVaccinated
SELECT dea.continent
	, dea.location
	, dea.date
	, dea.population
	, vac.new_vaccinations
	, SUM(cast(vac.new_vaccinations as INT)) OVER (Partition BY dea.location ORDER BY dea.location, dea.date) as RollingPeopleVaccinated
FROM PortfolioProject.dbo.CovidDeaths$ dea
JOIN PortfolioProject.dbo.CovidVaccinations$ vac
	ON dea.location = vac.location
	and dea.date = vac.date
WHERE dea.continent is not null

SELECT *
	, (RollingPeopleVaccinated/Population)*100
FROM #PercentPopulationVaccinated


-- Creating view to store data for later viz

CREATE VIEW PercentPopulationVaccinated as 
SELECT dea.continent
	, dea.location
	, dea.date
	, dea.population
	, vac.new_vaccinations
	, SUM(cast(vac.new_vaccinations as INT)) OVER (Partition BY dea.location ORDER BY dea.location, dea.date) as RollingPeopleVaccinated
FROM PortfolioProject.dbo.CovidDeaths$ dea
JOIN PortfolioProject.dbo.CovidVaccinations$ vac
	ON dea.location = vac.location
	and dea.date = vac.date
WHERE dea.continent is not null
--ORDER BY 2,3

