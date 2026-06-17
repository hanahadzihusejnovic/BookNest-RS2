using Microsoft.AspNetCore.Authentication;
using Microsoft.Extensions.Options;
using System.Security.Claims;
using System.Text.Encodings.Web;

namespace BookNest.API.Authentication
{
    public class ApiKeyAuthenticationHandler : AuthenticationHandler<AuthenticationSchemeOptions>
    {
        private const string ApiKeyHeaderName = "X-Internal-Api-Key";

        public ApiKeyAuthenticationHandler(
            IOptionsMonitor<AuthenticationSchemeOptions> options,
            ILoggerFactory logger,
            UrlEncoder encoder) : base(options, logger, encoder) { }

        protected override Task<AuthenticateResult> HandleAuthenticateAsync()
        {
            if (!Request.Headers.TryGetValue(ApiKeyHeaderName, out var providedKey))
                return Task.FromResult(AuthenticateResult.Fail("Missing X-Internal-Api-Key header."));

            var configuredKey = Environment.GetEnvironmentVariable("INTERNAL_API_KEY");

            if (string.IsNullOrEmpty(configuredKey) || providedKey != configuredKey)
                return Task.FromResult(AuthenticateResult.Fail("Invalid API key."));

            var claims = new[] { new Claim(ClaimTypes.Name, "InternalService") };
            var identity = new ClaimsIdentity(claims, Scheme.Name);
            var principal = new ClaimsPrincipal(identity);
            var ticket = new AuthenticationTicket(principal, Scheme.Name);

            return Task.FromResult(AuthenticateResult.Success(ticket));
        }
    }
}
