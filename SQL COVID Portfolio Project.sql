/*
Covid 19 Data Exploration 

Skills used: Joins, CTE's, Temp Tables, Windows Functions, Aggregate Functions, Creating Views, Converting Data Types

*/

select *
from PortfolioProject.dbo.CovidDeaths
where continent is not null
order by 3,4

select *
from PortfolioProject.dbo.CovidVaccinations
order by 3,4

--Select data we are going to start with
select location, date, total_cases, new_cases, total_deaths, population
from PortfolioProject.dbo.CovidDeaths
where continent is not null
order by 1,2

--Total cases vs total deaths
--Shows likelihood of dying if you contract covid in your country
select location, date, total_cases,  total_deaths, (total_deaths/total_cases)*100 as DeathPercentage
from PortfolioProject.dbo.CovidDeaths
where continent is not null
order by 1,2

--Total cases vs population
--Shows what percentage of population got covid
select location, date, population, total_cases, (total_cases/population)*100 as PercentPopulationInfected
from PortfolioProject.dbo.CovidDeaths
--where location like '%states%'
where continent is not null
order by 1,2

--Looking at countries with highest infection rate compared to population
select location, population, MAX(total_cases) as HighestInfectionCount, Max((total_cases/population))*100 as PercentPopulationInfected
from PortfolioProject.dbo.CovidDeaths
where continent is not null
group by location, population
order by PercentPopulationInfected desc

--Showing countries with highest death count per population
select location, MAX(cast(total_deaths as int)) as TotalDeathCount
from PortfolioProject.dbo.CovidDeaths
where continent is not null
group by location
order by TotalDeathCount desc

--Break things down by continent
--Showing contintents with highest death count per population
select continent, MAX(cast(total_deaths as int)) as TotalDeathCount
from PortfolioProject.dbo.CovidDeaths
where continent is not null
group by continent
order by TotalDeathCount desc



--Global numbers
select sum(new_cases) as total_cases, SUM(cast(new_deaths as int)) as total_deaths, sum(cast(new_deaths as int))/sum(new_cases)*100 as DeathPercentage
from PortfolioProject.dbo.CovidDeaths
where continent is not null
--group by date
order by 1,2


--Total population vs. vaccinations
--Shows percentage of population that has recieved at least one covid vaccine
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, SUM(convert(int, vac.new_vaccinations)) over (partition by dea.location order by dea.location, dea.date) as RollingPeopleVaccinated --, (RollingPeopleVaccinated/population)*100
from PortfolioProject..CovidDeaths dea
join PortfolioProject..CovidVaccinations vac
	on dea.location = vac.location 
	and dea.date = vac.date
where dea.continent is not null
order by 2,3


--Using CTE to preform calculation on partition by in previous query
with PopvcVac (Continent, Location, Date, population, New_Vaccinations, RollingPeopleVaccinated)
as
(
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, SUM(convert(int, vac.new_vaccinations)) over (partition by dea.location order by dea.location, dea.date) as RollingPeopleVaccinated 
from PortfolioProject..CovidDeaths dea
join PortfolioProject..CovidVaccinations vac
	on dea.location = vac.location 
	and dea.date = vac.date
where dea.continent is not null
)
select *, (RollingPeopleVaccinated/population)*100
from PopvcVac


--Using temp table to preform calculation on partition by in previous query
drop table if exists #PercentPopulationVaccinated
Create table #PercentPopulationVaccinated
(
continent nvarchar(255),
location nvarchar(255),
date datetime,
population numeric,
new_vaccinations numeric,
RollingPeopleVaccinated numeric
)

insert into #PercentPopulationVaccinated
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, SUM(convert(int, vac.new_vaccinations)) over (partition by dea.location order by dea.location, dea.date) as RollingPeopleVaccinated 
from PortfolioProject..CovidDeaths dea
join PortfolioProject..CovidVaccinations vac
	on dea.location = vac.location 
	and dea.date = vac.date
where dea.continent is not null

select *, (RollingPeopleVaccinated /population)*100
from #PercentPopulationVaccinated


-- Creating view to store data for later visulaization
create view PercentPopulationVaccinated as
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, SUM(convert(int, vac.new_vaccinations)) over (partition by dea.location order by dea.location, dea.date) as RollingPeopleVaccinated 
from PortfolioProject..CovidDeaths dea
join PortfolioProject..CovidVaccinations vac
	on dea.location = vac.location 
	and dea.date = vac.date
where dea.continent is not null

select *
from PercentPopulationVaccinated