SELECT*
FROM PortfolioProject..CovidDeaths
where continent is not null
order by 3,4

--SELECT*
--FROM PortfolioProject..CovidVaccinations
--order by 3,4

---Selected Data that I am going to use

SELECT location, date, total_cases, new_cases, total_deaths, population
FROM PortfolioProject..CovidDeaths
where continent is not null
order by 1,2


--Looking at Tatol Cases Vs Total Deaths
--Shows likelihood of dying if you contract covid in your country
SELECT location, date, total_cases, total_deaths,
(CONVERT (float, total_deaths)/NULLIF(CONVERT(float,total_cases),0))*100 As Deathpercentage
FROM PortfolioProject..CovidDeaths
Where location like '%states%'
and continent is not null
order by 1,2

-- Looking at Total Cases Vs Population
-- Shows what percentage of population got Covid

SELECT location, date, population, total_cases,
(CONVERT (float, total_cases)/NULLIF(CONVERT(float,Population),0))*100 As PercentPopulationInfected
FROM PortfolioProject..CovidDeaths
Where location like '%states%' and continent is not null
order by 1,2


-- Looking at Countries with Highest Infection Rate Compared to Population


SELECT 
    location, 
    MAX(population) as Population, 
    SUM(CAST(total_cases AS float)) as TotalCases, -- Cast total_cases to float before summing
    (SUM(CAST(total_cases AS float)) / NULLIF(MAX(CAST(population AS float)), 0)) * 100 AS PercentPopulationInfected
FROM 
    PortfolioProject..CovidDeaths
where continent is not null
GROUP BY 
    location
ORDER BY 
    PercentPopulationInfected DESC;

--Let's Break Things Down by Continent
--Showing Countries with Highest Death Count per Population


SELECT 
    location, 
    SUM(CAST(total_deaths AS float)) as TotalDeathCount -- Cast to float if total_deaths is not a numeric type
FROM 
    PortfolioProject..CovidDeaths
where continent is null
GROUP BY 
    location
ORDER BY 
    TotalDeathCount DESC;



-- Showing Contintents with Highest Death Count per Population

SELECT 
    location, 
    SUM(CAST(total_deaths AS float)) as TotalDeathCount -- Cast to float if total_deaths is not a numeric type
FROM 
    PortfolioProject..CovidDeaths
where continent is not null
GROUP BY 
    location
ORDER BY 
    TotalDeathCount DESC;


-- Global Numbers

SELECT SUM(new_cases) as TotalNewCases, 
    SUM(CAST(new_deaths AS float)) as TotalNewDeaths, 
    CASE 
        WHEN SUM(new_cases) = 0 THEN NULL 
        ELSE (SUM(CAST(new_deaths AS float)) / SUM(new_cases)) * 100 
    END AS DeathPercentage
FROM 
    PortfolioProject..CovidDeaths
WHERE 
    continent IS NOT NULL
--GROUP BY date
ORDER BY 
    1,2

---------------------------------------------------------------------------------------

-- Looking at Total Population Vs Vaccinations


SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
SUM(CAST(vac.new_vaccinations AS float)) OVER (Partition by dea.location Order by dea.location, dea.date) AS --(RollingPeopleVaccinated/population)*100
FROM PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
     On dea.location = vac.location
	 and dea.date = vac.date
where dea.continent is not null
order by 2,3

-- Using CTE to perform Calculation on Partition By in previous query

WITH PopvsVac (continent, location, date, population, new_vaccinations, RollingPeopleVaccinated) AS
(
    SELECT 
        dea.continent, 
        dea.location, 
        dea.date, 
        dea.population, 
        vac.new_vaccinations,
        SUM(CAST(vac.new_vaccinations AS float)) OVER (
            PARTITION BY dea.location 
            ORDER BY dea.date
        ) / dea.population * 100 AS RollingPeopleVaccinated
    FROM 
        PortfolioProject..CovidDeaths dea
    JOIN 
        PortfolioProject..CovidVaccinations vac
    ON 
        dea.location = vac.location AND dea.date = vac.date
    WHERE 
        dea.continent IS NOT NULL
)

SELECT *
FROM PopvsVac;



--Using Temp Table to perform Calculation on Partition By in previous query

INSERT INTO #PercentPopulationVaccinated
SELECT 
    dea.continent, 
    dea.location, 
    dea.date, 
    dea.population, 
    vac.new_vaccinations,
    SUM(CONVERT(decimal(18,2), vac.new_vaccinations)) OVER 
        (PARTITION BY dea.location ORDER BY dea.date, dea.Date) AS RollingPeopleVaccinated
FROM 
    PortfolioProject..CovidDeaths dea
JOIN 
    PortfolioProject..CovidVaccinations vac
ON 
    dea.location = vac.location AND dea.date = vac.date

SELECT 
    *, 
    (RollingPeopleVaccinated / NULLIF(CONVERT(decimal(18,2), Population), 0)) * 100 AS PercentVaccinated
FROM 
    #PercentPopulationVaccinated

--Creating View to store data for later visualizations


CREATE VIEW PercentPopulationVaccinated AS
SELECT 
    dea.continent,
    dea.location,
    dea.date,
    dea.population,
    vac.new_vaccinations,
    SUM(CONVERT(decimal(18,2), vac.new_vaccinations)) OVER (
        PARTITION BY dea.location 
        ORDER BY dea.date, dea.Date
    ) AS RollingPeopleVaccinated
FROM 
    PortfolioProject..CovidDeaths dea
JOIN 
    PortfolioProject..CovidVaccinations vac
ON 
    dea.location = vac.location AND dea.date = vac.date
WHERE 
    dea.continent IS NOT NULL;
-------------------------------------------------------------------------------------------------

SELECT 
    *,
    (RollingPeopleVaccinated / NULLIF(CONVERT(decimal(18,2), Population), 0)) * 100 AS PercentVaccinated
FROM 
    PercentPopulationVaccinated;
-------------------------------------------------------------------------------------------------





