FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
USER app
ARG BUILD_CONFIGURATION=Release

WORKDIR /src
COPY . .

RUN dotnet restore ./backend.csproj
RUN dotnet build ./backend.csproj -c $BUILD_CONFIGURATION -o /src/build

FROM build AS publish
ARG BUILD_CONFIGURATION=Release
RUN dotnet publish "./backend.csproj" -c $BUILD_CONFIGURATION -o /src/publish /p:UseAppHost=true

# Build runtime image
FROM mcr.microsoft.com/dotnet/aspnet:8.0
WORKDIR /app
EXPOSE 8080
COPY --from=publish /src/publish .
ENTRYPOINT ["./backend"]