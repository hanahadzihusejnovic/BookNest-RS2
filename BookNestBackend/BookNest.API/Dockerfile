FROM mcr.microsoft.com/dotnet/aspnet:8.0 AS base
USER app
WORKDIR /app
EXPOSE 7110

FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
ARG BUILD_CONFIGURATION=Release
WORKDIR /src
COPY ["BookNest.API/BookNest.API.csproj", "BookNest.API/"]
COPY ["BookNest.Services/BookNest.Services.csproj", "BookNest.Services/"]
COPY ["BookNest.Model/BookNest.Model.csproj", "BookNest.Model/"]
RUN dotnet restore "./BookNest.API/BookNest.API.csproj"
COPY . .
WORKDIR "/src/BookNest.API"
RUN dotnet build "./BookNest.API.csproj" -c $BUILD_CONFIGURATION -o /app/build

FROM build AS publish
ARG BUILD_CONFIGURATION=Release
RUN dotnet publish "./BookNest.API.csproj" -c $BUILD_CONFIGURATION -o /app/publish /p:UseAppHost=false

FROM base AS final
WORKDIR /app
COPY --from=publish /app/publish .
ENTRYPOINT ["dotnet", "BookNest.API.dll"]
