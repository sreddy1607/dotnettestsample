# Use the official .NET Core SDK as a parent image
FROM 136299550619.dkr.ecr.us-west-2.amazonaws.com/cammismspapp:1.0.6 AS build
WORKDIR /app

# Copy the project file and restore any dependencies (use .csproj for the project name)
#COPY *.csproj ./
COPY * ./
RUN ls -l
RUN dotnet restore

# Copy the rest of the application code
COPY . .

# Publish the application
RUN dotnet publish -c Release -o out

# Build the runtime image
FROM 136299550619.dkr.ecr.us-west-2.amazonaws.com/cammismspapp:1.0.6 AS runtime
WORKDIR /app
COPY --from=build /app/out ./

# Expose the port your application will run on
EXPOSE 80

# Start the application
ENTRYPOINT ["dotnet", "NET-Core-Web-API-Docker-Demo.dll"]
