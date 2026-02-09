FROM mcr.microsoft.com/dotnet/aspnet:9.0 AS base
WORKDIR /app
EXPOSE 5094

FROM mcr.microsoft.com/dotnet/sdk:9.0 AS build
ARG BUILD_CONFIGURATION=Release
WORKDIR /src

# Copy csproj file and restore dependencies
COPY ["src/Artemis.API/Artemis.API.csproj", "src/Artemis.API/"]
RUN dotnet restore "src/Artemis.API/Artemis.API.csproj" --verbosity quiet

# Copy everything else and build
COPY . .
WORKDIR "/src/src/Artemis.API"
RUN dotnet build "Artemis.API.csproj" -c ${BUILD_CONFIGURATION} -o /app/build

FROM build AS publish
WORKDIR "/src/src/Artemis.API"
RUN dotnet publish "Artemis.API.csproj" -c ${BUILD_CONFIGURATION} -o /app/publish /p:UseAppHost=false

FROM base AS final
WORKDIR /app
COPY --from=publish /app/publish .
ENTRYPOINT ["dotnet", "Artemis.API.dll"]
