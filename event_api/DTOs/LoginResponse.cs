namespace event_api.DTOs
{
    public class LoginResponse
    {
        public string Token { get; set; }
        public string Role { get; set; }
        public string RedirectUrl { get; set; }
    }
}

