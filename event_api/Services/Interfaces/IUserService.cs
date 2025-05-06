using event_api.DTOs;
using event_api.Models;

namespace event_api.Services.Interfaces
{
    public interface IUserService
    {
        Task<LoginResponse> LoginAsync(LoginRequest request);
        Task<User> GetUserByEmailAsync(string email);
    }

}
