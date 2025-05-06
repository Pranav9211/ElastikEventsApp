using event_api.DTOs;
using event_api.Services.Interfaces;
using event_api.Utils;
using event_api.Data;
using event_api.Models;
using Microsoft.EntityFrameworkCore;

namespace event_api.Services
{
    public class UserService : IUserService
    {
        private readonly ApplicationDbContext _context;
        private readonly JwtTokenGenerator _jwt;

        public UserService(ApplicationDbContext context, JwtTokenGenerator jwt)
        {
            _context = context;
            _jwt = jwt;
        }

        public async Task<LoginResponse> LoginAsync(LoginRequest request)
        {
            var user = await _context.Users.FirstOrDefaultAsync(u => u.Email == request.Email);
            if (user == null || !BCrypt.Net.BCrypt.Verify(request.Password, user.PasswordHash))
                throw new UnauthorizedAccessException("Invalid credentials");

            var token = _jwt.GenerateToken(user);

            var redirectUrl = user.Role?.ToLower() switch
            {
                "admin" => "/admin",
                "participant" => "/participant",
                _ => "/"
            };

            return new LoginResponse
            {
                Token = token,
                Role = user.Role,
                RedirectUrl = redirectUrl
            };
        }


        public async Task<User> GetUserByEmailAsync(string email)
        {
            return await _context.Users.FirstOrDefaultAsync(u => u.Email == email);
        }


    }
}
