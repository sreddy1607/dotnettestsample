# Use the official .NET Core SDK as a parent image
#FROM 136299550619.dkr.ecr.us-west-2.amazonaws.com/cammismspapp:1.0.6 AS build
#ARG TARGETARCH
#RUN yum install -y libicu-devel
# Install OpenSSL
#RUN yum install -y openssl openssl-devel
#WORKDIR /app

# Copy the project file and restore any dependencies (use .csproj for the project name)
#COPY *.csproj ./
#COPY . .
#COPY NET-Core-Web-API-Docker-Demo/*.csproj .
#RUN pwd
#COPY NET-Core-Web-API-Docker-Demo/*.csproj ./NET-Core-Web-API-Docker-Demo/
#RUN ls -l NET-Core-Web-API-Docker-Demo
#RUN ls -l
#WORKDIR /app/NET-Core-Web-API-Docker-Demo
#RUN pwd
#RUN dotnet restore --verbosity diganostic "NET-Core-Web-API-Docker-Demo/NET-Core-Web-API-Docker-Demo.csproj"
#RUN dotnet restore --verbosity detailed
#RUN dotnet restore -a $TARGETARCH

# Copy the rest of the application code
#COPY . .

# Publish the application
#RUN dotnet publish -c Release -o out

# Build the runtime image
#FROM 136299550619.dkr.ecr.us-west-2.amazonaws.com/cammismspapp:1.0.6 AS runtime
#RUN yum install -y libicu-devel
#WORKDIR /app
#COPY --from=build /app/out ./

# Expose the port your application will run on
#EXPOSE 80

# Start the application
#ENTRYPOINT ["dotnet", "NET-Core-Web-API-Docker-Demo.dll"]

# Learn about building .NET container images:
# https://github.com/dotnet/dotnet-docker/blob/main/samples/README.md
#FROM --platform=$BUILDPLATFORM mcr.microsoft.com/dotnet/sdk:8.0 AS build
FROM 136299550619.dkr.ecr.us-west-2.amazonaws.com/cammismspapp:1.0.7 AS build
ARG TARGETARCH
WORKDIR /source

# copy csproj and restore as distinct layers
COPY NET-Core-Web-API-Docker-Demo/*.csproj .
RUN dotnet restore -a $TARGETARCH

# copy and publish app and libraries
COPY NET-Core-Web-API-Docker-Demo/. .
RUN dotnet publish -a $TARGETARCH --no-restore -o /app


# final stage/image
#FROM mcr.microsoft.com/dotnet/aspnet:8.0
FROM 136299550619.dkr.ecr.us-west-2.amazonaws.com/cammismspapp:1.0.7
EXPOSE 8080
WORKDIR /app
COPY --from=build /app .
USER $APP_UID
ENTRYPOINT ["./aspnetapp"]
