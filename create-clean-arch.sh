#!/bin/bash

# Verifica se o número de argumentos é insuficiente
if [ "$#" -ne 1 ]; then
  echo "Uso: $0 <NomeDoProjeto>"
  exit 1
fi

# Cria a pasta do projeto
mkdir $1
cd $1

# Nome do projeto passado como parâmetro
project_name=$1

# Criar a solução
dotnet new sln -n $project_name

# Criar e adicionar projetos de domínio
dotnet new classlib -n $project_name.Domain
mkdir $project_name.Domain/Entities
mkdir $project_name.Domain/Interfaces
mkdir $project_name.Domain/Interfaces/Repositories
touch $project_name.Domain/Interfaces/

# Criar e adicionar projetos de aplicação
dotnet new classlib -n $project_name.Application
mkdir  $project_name.Application/Interfaces
mkdir  $project_name.Application/UseCases


# Criar e adicionar projetos de infraestrutura
dotnet new classlib -n $project_name.Infrastructure
mkdir $project_name.Infrastructure/Persistence
touch $project_name.Infrastructure/Persistence/ApplicationDbContext.cs

echo " 
using Microsoft.EntityFrameworkCore;

namespace $project_name.Infrastructure.Persistence
{
    public class ApplicationDbContext : DbContext
    {
        public ApplicationDbContext(DbContextOptions<ApplicationDbContext> options)
            : base(options)
        {
        }
    }

} " > $project_name.Infrastructure/Persistence/ApplicationDbContext.cs

# Criar e adicionar o projeto da API
dotnet new webapi -n $project_name.Api
echo "using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using $project_name.Infrastructure.Persistence;
using Microsoft.EntityFrameworkCore;


namespace $project_name.Api
{
    public class Startup
    {
        public Startup(IConfiguration configuration)
        {
            Configuration = configuration;
        }

        public IConfiguration Configuration { get; }

        public void ConfigureServices(IServiceCollection services)
        {
            services.AddDbContext<ApplicationDbContext>(options =>
                options.UseSqlite(Configuration.GetConnectionString(\"DefaultConnection\")));
            // services.AddScoped<IUserRepository>();
            // services.AddScoped<IUseCase>();
            services.AddControllers();
        }

        public void Configure(IApplicationBuilder app, IWebHostEnvironment env)
        {
            if (env.IsDevelopment())
            {
                app.UseDeveloperExceptionPage();
            }

            app.UseRouting();

            app.UseEndpoints(endpoints =>
            {
                endpoints.MapControllers();
            });
        }
    }
}" > $project_name.Api/Startup.cs;

echo "
// CleanArch.Api/Program.cs
using Microsoft.AspNetCore.Hosting;
using Microsoft.Extensions.Hosting;

namespace $project_name.Api
{
    public class Program
    {
        public static void Main(string[] args)
        {
            CreateHostBuilder(args).Build().Run();
        }

        public static IHostBuilder CreateHostBuilder(string[] args) =>
            Host.CreateDefaultBuilder(args)
                .ConfigureWebHostDefaults(webBuilder =>
                {
                    webBuilder.UseStartup<Startup>();
                });
    }
}" > $project_name.Api/Program.cs

dotnet sln add $project_name.Domain
dotnet sln add $project_name.Application
dotnet sln add $project_name.Infrastructure
dotnet sln add $project_name.Api

dotnet add $project_name.Application/$project_name.Application.csproj reference $project_name.Domain/$project_name.Domain.csproj
dotnet add $project_name.Infrastructure/$project_name.Infrastructure.csproj reference $project_name.Domain/$project_name.Domain.csproj

dotnet add $project_name.Api/$project_name.Api.csproj reference $project_name.Application/$project_name.Application.csproj
dotnet add $project_name.Api/$project_name.Api.csproj reference $project_name.Infrastructure/$project_name.Infrastructure.csproj
dotnet add $project_name.Api/$project_name.Api.csproj reference $project_name.Domain/$project_name.Domain.csproj

rm $project_name.Application/Class1.cs
rm $project_name.Domain/Class1.cs
rm $project_name.Infrastructure/Class1.cs

dotnet add $project_name.Api/$project_name.Api.csproj package Microsoft.EntityFrameworkCore.Design 
dotnet add $project_name.Api/$project_name.Api.csproj package Microsoft.EntityFrameworkCore.Sqlite
dotnet add $project_name.Api/$project_name.Api.csproj package Microsoft.EntityFrameworkCore

dotnet add $project_name.Infrastructure/$project_name.Infrastructure.csproj package Microsoft.EntityFrameworkCore

echo ' 
{
  "ConnectionStrings": {
    "DefaultConnection": "Data Source=database.db"
  },
  "Logging": {
    "LogLevel": {
      "Default": "Information",
      "Microsoft.AspNetCore": "Warning"
    }
  },
  "AllowedHosts": "*"
}
' > $project_name.Api/appsettings.json

echo "Projeto Clean Architecture '$project_name' criado com sucesso!"
echo "Inciando primeiro build"
cd $project_name
dotnet build
echo "Build finalizado com sucesso!"
clear

echo "Inciando primeiro run"
dotnet run --project $project_name.Api/$project_name.Api.csproj --urls=http://localhost:5000/
cd $project_name



