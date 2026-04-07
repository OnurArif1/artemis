FROM mcr.microsoft.com/dotnet/aspnet:9.0 AS base
WORKDIR /app
EXPOSE 5095

FROM mcr.microsoft.com/dotnet/sdk:9.0 AS build
ARG BUILD_CONFIGURATION=Release
WORKDIR /src

COPY ["src/Artemis.API/Artemis.API.csproj", "src/Artemis.API/"]
RUN dotnet restore "src/Artemis.API/Artemis.API.csproj" --verbosity quiet

COPY ["src/Identity.Api/Identity.Api.csproj", "src/Identity.Api/"]
RUN dotnet restore "src/Identity.Api/Identity.Api.csproj" --verbosity quiet

COPY . .
WORKDIR "/src/src/Identity.Api"
RUN dotnet build "Identity.Api.csproj" -c ${BUILD_CONFIGURATION} -o /app/build

FROM build AS publish
ARG BUILD_CONFIGURATION=Release
WORKDIR "/src/src/Identity.Api"
RUN mv /src/src/Artemis.API/appsettings.json /src/src/Artemis.API/appsettings.json.bak 2>/dev/null || true && \
    mv /src/src/Artemis.API/appsettings.Development.json /src/src/Artemis.API/appsettings.Development.json.bak 2>/dev/null || true
RUN dotnet publish "Identity.Api.csproj" -c ${BUILD_CONFIGURATION} -o /app/publish /p:UseAppHost=false
RUN mv /src/src/Artemis.API/appsettings.json.bak /src/src/Artemis.API/appsettings.json 2>/dev/null || true && \
    mv /src/src/Artemis.API/appsettings.Development.json.bak /src/src/Artemis.API/appsettings.Development.json 2>/dev/null || true

FROM base AS final
WORKDIR /app
COPY --from=publish /app/publish .
ENTRYPOINT ["dotnet", "Identity.Api.dll"]
