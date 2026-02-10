FROM mcr.microsoft.com/dotnet/aspnet:9.0 AS base
WORKDIR /app
EXPOSE 5091

FROM mcr.microsoft.com/dotnet/sdk:9.0 AS build
ARG BUILD_CONFIGURATION=Release
WORKDIR /src

# Copy csproj file and restore dependencies
COPY ["src/Artemis.Gateway/Artemis.Gateway.csproj", "src/Artemis.Gateway/"]
RUN dotnet restore "src/Artemis.Gateway/Artemis.Gateway.csproj" --verbosity quiet

# Copy everything else and build
COPY . .
WORKDIR "/src/src/Artemis.Gateway"
RUN dotnet build "Artemis.Gateway.csproj" -c ${BUILD_CONFIGURATION} -o /app/build

FROM build AS publish
ARG BUILD_CONFIGURATION=Release
WORKDIR "/src/src/Artemis.Gateway"
RUN dotnet publish "Artemis.Gateway.csproj" -c ${BUILD_CONFIGURATION} -o /app/publish /p:UseAppHost=false

FROM base AS final
WORKDIR /app
COPY --from=publish /app/publish .
ENTRYPOINT ["dotnet", "Artemis.Gateway.dll"]
