# Use the official .NET Core SDK as a parent image
FROM 136299550619.dkr.ecr.us-west-2.amazonaws.com/cammismspapp:1.0.6 AS build
RUN yum install -y libicu-devel
# Install OpenSSL
RUN yum install -y openssl openssl-devel
WORKDIR /app

# Copy the project file and restore any dependencies (use .csproj for the project name)
#COPY *.csproj ./
#COPY . .
COPY NET-Core-Web-API-Docker-Demo/*.csproj .
RUN pwd
#COPY NET-Core-Web-API-Docker-Demo/*.csproj ./NET-Core-Web-API-Docker-Demo/
RUN ls -l NET-Core-Web-API-Docker-Demo
#WORKDIR /app/NET-Core-Web-API-Docker-Demo
RUN pwd
#RUN dotnet restore --verbosity diganostic "NET-Core-Web-API-Docker-Demo/NET-Core-Web-API-Docker-Demo.csproj"
RUN dotnet restore --verbosity detailed

# Copy the rest of the application code
#COPY . .

# Publish the application
RUN dotnet publish -c Release -o out

# Build the runtime image
FROM 136299550619.dkr.ecr.us-west-2.amazonaws.com/cammismspapp:1.0.6 AS runtime
RUN yum install -y libicu-devel
WORKDIR /app
COPY --from=build /app/out ./

# Expose the port your application will run on
EXPOSE 80

# Start the application
ENTRYPOINT ["dotnet", "NET-Core-Web-API-Docker-Demo.dll"]
