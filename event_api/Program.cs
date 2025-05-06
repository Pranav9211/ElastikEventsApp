using event_api.Services.Interfaces;
using event_api.Services;
using event_api.Utils;
using event_api.Data;
using Microsoft.EntityFrameworkCore;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.IdentityModel.Tokens;
using Microsoft.Extensions.Logging;
using Serilog;
using BCrypt.Net;
using System.Text;

var builder = WebApplication.CreateBuilder(args);

// Set up Serilog for logging before building the host
Log.Logger = new LoggerConfiguration()
    .MinimumLevel.Information()  // Set minimum log level
    .WriteTo.Console()           // Log to the console
    .WriteTo.File(@"D:\ET\FlutterApp\Logs\app-log-.txt", rollingInterval: RollingInterval.Day) // Log to a file on D drive
    .CreateLogger();

// Add Serilog as the logging provider before building the app
builder.Host.UseSerilog(); // Ensure Serilog is used for logging

builder.Services.AddLogging(loggingBuilder => loggingBuilder.AddSerilog());

builder.Services.AddControllers();

// Add DB Context
builder.Services.AddDbContext<ApplicationDbContext>(options =>
    options.UseSqlServer(builder.Configuration.GetConnectionString("DefaultConnection")));

// Enable CORS (for Flutter app to connect)
builder.Services.AddCors(options =>
{
    options.AddPolicy("AllowFlutterApp",
        policy => policy
            .AllowAnyOrigin()
            .AllowAnyHeader()
            .AllowAnyMethod());
});

// Learn more about configuring OpenAPI at https://aka.ms/aspnet/openapi
builder.Services.AddEndpointsApiExplorer(); // Correct for Swagger
builder.Services.AddSwaggerGen();

// JWT Config
builder.Services.AddAuthentication(JwtBearerDefaults.AuthenticationScheme)
    .AddJwtBearer(options =>
    {
        options.TokenValidationParameters = new TokenValidationParameters
        {
            ValidateIssuer = true,
            ValidateAudience = true,
            ValidateLifetime = true,
            ValidateIssuerSigningKey = true,
            ValidIssuer = builder.Configuration["Jwt:Issuer"],
            ValidAudience = builder.Configuration["Jwt:Audience"],
            IssuerSigningKey = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(builder.Configuration["Jwt:Key"]))
        };
    });

builder.Services.AddScoped<IUserService, UserService>();
builder.Services.AddSingleton<JwtTokenGenerator>();
builder.Services.AddScoped<IEventService, EventService>();
builder.Services.AddScoped<IParticipantService, ParticipantService>();
builder.Services.AddScoped<IAdminService, AdminService>();
builder.Services.AddScoped<IRegistrationService, RegistrationService>();

// Build the app after configuring logging
var app = builder.Build();

// Use Serilog request logging middleware to log HTTP request/response details
app.UseSerilogRequestLogging(); // Logs HTTP request/response details

//// Password hashing logic
//string plainPassword = "9211"; // Replace this with your actual password
//string hashedPassword = BCrypt.Net.BCrypt.HashPassword(plainPassword);

//// Log the hashed password to both console and file
//Log.Information($"Hashed Password for {plainPassword}: {hashedPassword}");

// Configure the HTTP request pipeline.
if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

app.UseAuthentication(); 
app.UseAuthorization();

app.UseCors("AllowFlutterApp");

app.UseHttpsRedirection();

app.MapControllers();

app.Run();
