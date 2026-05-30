using BookNest.Model.Enums;
using BookNest.Services.Database;
using BookNest.Services.Database.Entities;
using BookNest.Services.Security;
using Microsoft.EntityFrameworkCore;

namespace BookNest.API.Data
{
    public static class DatabaseSeeder
    {
        public static async Task SeedAsync(IServiceProvider services)
        {
            using var scope = services.CreateScope();
            var db = scope.ServiceProvider.GetRequiredService<BookNestDbContext>();

            if (await db.Roles.AnyAsync()) return;

            var hasher = new Pbkdf2PasswordHasher();

            // ── Roles ───────────────────────────────────────────────────────────
            var roleAdmin = new Role { Name = "Admin" };
            var roleUser  = new Role { Name = "User" };
            db.Roles.AddRange(roleAdmin, roleUser);
            await db.SaveChangesAsync();

            // ── Countries ───────────────────────────────────────────────────────
            var countryBiH = new Country { Name = "Bosnia and Herzegovina" };
            var countryDE  = new Country { Name = "Germany" };
            var countryUS  = new Country { Name = "United States" };
            var countryUK  = new Country { Name = "United Kingdom" };
            var countryFR  = new Country { Name = "France" };
            db.Countries.AddRange(countryBiH, countryDE, countryUS, countryUK, countryFR);
            await db.SaveChangesAsync();

            // ── Cities ──────────────────────────────────────────────────────────
            var citySarajevo   = new City { Name = "Sarajevo",    CountryId = countryBiH.Id };
            var cityMostar     = new City { Name = "Mostar",      CountryId = countryBiH.Id };
            var cityBerlin     = new City { Name = "Berlin",      CountryId = countryDE.Id  };
            var cityMunich     = new City { Name = "Munich",      CountryId = countryDE.Id  };
            var cityNewYork    = new City { Name = "New York",    CountryId = countryUS.Id  };
            var cityLA         = new City { Name = "Los Angeles", CountryId = countryUS.Id  };
            var cityLondon     = new City { Name = "London",      CountryId = countryUK.Id  };
            var cityManchester = new City { Name = "Manchester",  CountryId = countryUK.Id  };
            var cityParis      = new City { Name = "Paris",       CountryId = countryFR.Id  };
            var cityLyon       = new City { Name = "Lyon",        CountryId = countryFR.Id  };
            db.Cities.AddRange(citySarajevo, cityMostar, cityBerlin, cityMunich,
                               cityNewYork, cityLA, cityLondon, cityManchester, cityParis, cityLyon);
            await db.SaveChangesAsync();

            // ── Book Categories ─────────────────────────────────────────────────
            var catFiction  = new Category { Name = "Fiction" };
            var catFantasy  = new Category { Name = "Fantasy" };
            var catMystery  = new Category { Name = "Mystery" };
            var catRomance  = new Category { Name = "Romance" };
            var catSciFi    = new Category { Name = "Science Fiction" };
            var catBio      = new Category { Name = "Biography" };
            var catHistory  = new Category { Name = "History" };
            var catSelfHelp = new Category { Name = "Self-Help" };
            db.Categories.AddRange(catFiction, catFantasy, catMystery, catRomance,
                                   catSciFi, catBio, catHistory, catSelfHelp);
            await db.SaveChangesAsync();

            // ── Event Categories ────────────────────────────────────────────────
            var evCatReading  = new EventCategory { Name = "Book Reading",        Description = "Live readings of books by authors or actors." };
            var evCatWorkshop = new EventCategory { Name = "Workshop",            Description = "Interactive sessions to improve writing skills." };
            var evCatFestival = new EventCategory { Name = "Literary Festival",   Description = "Multi-day events celebrating literature and authors." };
            var evCatMeetup   = new EventCategory { Name = "Author Meet & Greet", Description = "Opportunities to meet and talk with authors in person." };
            var evCatPoetry   = new EventCategory { Name = "Poetry Night",        Description = "Evenings dedicated to poetry readings and open mic." };
            db.EventCategories.AddRange(evCatReading, evCatWorkshop, evCatFestival, evCatMeetup, evCatPoetry);
            await db.SaveChangesAsync();

            // ── Authors ─────────────────────────────────────────────────────────
            var authorRowling = new Author {
                FirstName = "J.K.", LastName = "Rowling",
                DateOfBirth = new DateTime(1965, 7, 31),
                Biography = "British author best known for the Harry Potter fantasy series, which has sold over 500 million copies worldwide.",
                ImageUrl = "https://covers.openlibrary.org/a/id/7727559-L.jpg"
            };
            var authorMartin = new Author {
                FirstName = "George R.R.", LastName = "Martin",
                DateOfBirth = new DateTime(1948, 9, 20),
                Biography = "American novelist and screenwriter known for A Song of Ice and Fire, the basis for HBO's Game of Thrones.",
                ImageUrl = "https://covers.openlibrary.org/a/id/7727560-L.jpg"
            };
            var authorChristie = new Author {
                FirstName = "Agatha", LastName = "Christie",
                DateOfBirth = new DateTime(1890, 9, 15),
                DateOfDeath = new DateTime(1976, 1, 12),
                Biography = "English mystery writer regarded as the Queen of Crime, author of 66 detective novels.",
                ImageUrl = "https://covers.openlibrary.org/a/id/7727561-L.jpg"
            };
            var authorKing = new Author {
                FirstName = "Stephen", LastName = "King",
                DateOfBirth = new DateTime(1947, 9, 21),
                Biography = "American author of horror, supernatural fiction, and suspense with over 60 novels published.",
                ImageUrl = "https://covers.openlibrary.org/a/id/7727562-L.jpg"
            };
            var authorTolkien = new Author {
                FirstName = "J.R.R.", LastName = "Tolkien",
                DateOfBirth = new DateTime(1892, 1, 3),
                DateOfDeath = new DateTime(1973, 9, 2),
                Biography = "English author and Oxford professor best known for The Hobbit and The Lord of the Rings.",
                ImageUrl = "https://covers.openlibrary.org/a/id/7727563-L.jpg"
            };
            var authorAusten = new Author {
                FirstName = "Jane", LastName = "Austen",
                DateOfBirth = new DateTime(1775, 12, 16),
                DateOfDeath = new DateTime(1817, 7, 18),
                Biography = "English novelist known for her romantic fiction set among the landed gentry of early 19th-century England.",
                ImageUrl = "https://covers.openlibrary.org/a/id/7727564-L.jpg"
            };
            var authorMarquez = new Author {
                FirstName = "Gabriel García", LastName = "Márquez",
                DateOfBirth = new DateTime(1927, 3, 6),
                DateOfDeath = new DateTime(2014, 4, 17),
                Biography = "Colombian novelist and Nobel Prize winner, pioneer of magical realism.",
                ImageUrl = "https://covers.openlibrary.org/a/id/7727565-L.jpg"
            };
            var authorMurakami = new Author {
                FirstName = "Haruki", LastName = "Murakami",
                DateOfBirth = new DateTime(1949, 1, 12),
                Biography = "Japanese contemporary fiction author known for surreal narratives blending reality and fantasy.",
                ImageUrl = "https://covers.openlibrary.org/a/id/7727566-L.jpg"
            };
            db.Authors.AddRange(authorRowling, authorMartin, authorChristie, authorKing,
                                authorTolkien, authorAusten, authorMarquez, authorMurakami);
            await db.SaveChangesAsync();

            // ── Organizers ──────────────────────────────────────────────────────
            var org1 = new Organizer { FirstName = "Emma",    LastName = "Wilson",  ContactEmail = "emma.wilson@booknest.com",    PhoneNumber = "+38761100001" };
            var org2 = new Organizer { FirstName = "Michael", LastName = "Schmidt", ContactEmail = "michael.schmidt@booknest.com", PhoneNumber = "+4917620001"  };
            var org3 = new Organizer { FirstName = "Sarah",   LastName = "Johnson", ContactEmail = "sarah.johnson@booknest.com",   PhoneNumber = "+12125550001" };
            var org4 = new Organizer { FirstName = "Ali",     LastName = "Hassan",  ContactEmail = "ali.hassan@booknest.com",      PhoneNumber = "+38762200002" };
            db.Organizers.AddRange(org1, org2, org3, org4);
            await db.SaveChangesAsync();

            // ── Users ───────────────────────────────────────────────────────────
            var userAdmin = new User {
                FirstName = "Ana", LastName = "Admin",
                EmailAddress = "admin@booknest.com",
                Username = "admin",
                PasswordHash = hasher.Hash("Admin123!"),
                DateOfBirth = new DateTime(1985, 3, 15),
                Address = "Titova 1",
                CityId = citySarajevo.Id, CountryId = countryBiH.Id,
                PhoneNumber = "+38761000001"
            };
            var userJohn = new User {
                FirstName = "John", LastName = "Doe",
                EmailAddress = "john.doe@example.com",
                Username = "johndoe",
                PasswordHash = hasher.Hash("Test123!"),
                DateOfBirth = new DateTime(1990, 5, 20),
                Address = "Ferhadija 5",
                CityId = citySarajevo.Id, CountryId = countryBiH.Id
            };
            var userJane = new User {
                FirstName = "Jane", LastName = "Doe",
                EmailAddress = "jane.doe@example.com",
                Username = "janedoe",
                PasswordHash = hasher.Hash("Test123!"),
                DateOfBirth = new DateTime(1992, 8, 10),
                Address = "Unter den Linden 10",
                CityId = cityBerlin.Id, CountryId = countryDE.Id
            };
            var userMarko = new User {
                FirstName = "Marko", LastName = "Markovic",
                EmailAddress = "marko.markovic@example.com",
                Username = "marko.markovic",
                PasswordHash = hasher.Hash("Test123!"),
                DateOfBirth = new DateTime(1988, 11, 25),
                Address = "Obala Kulina Bana 3",
                CityId = citySarajevo.Id, CountryId = countryBiH.Id
            };
            var userAna = new User {
                FirstName = "Ana", LastName = "Petrovic",
                EmailAddress = "ana.petrovic@example.com",
                Username = "ana.petrovic",
                PasswordHash = hasher.Hash("Test123!"),
                DateOfBirth = new DateTime(1995, 2, 14),
                Address = "Bulevar 12",
                CityId = cityMostar.Id, CountryId = countryBiH.Id
            };
            var userLena = new User {
                FirstName = "Lena", LastName = "Muller",
                EmailAddress = "lena.muller@example.com",
                Username = "lena.muller",
                PasswordHash = hasher.Hash("Test123!"),
                DateOfBirth = new DateTime(1993, 7, 7),
                Address = "Maximilianstrasse 20",
                CityId = cityMunich.Id, CountryId = countryDE.Id
            };
            db.Users.AddRange(userAdmin, userJohn, userJane, userMarko, userAna, userLena);
            await db.SaveChangesAsync();

            // ── User Roles ──────────────────────────────────────────────────────
            db.UserRoles.AddRange(
                new UserRole { UserId = userAdmin.Id, RoleId = roleAdmin.Id },
                new UserRole { UserId = userJohn.Id,  RoleId = roleUser.Id  },
                new UserRole { UserId = userJane.Id,  RoleId = roleUser.Id  },
                new UserRole { UserId = userMarko.Id, RoleId = roleUser.Id  },
                new UserRole { UserId = userAna.Id,   RoleId = roleUser.Id  },
                new UserRole { UserId = userLena.Id,  RoleId = roleUser.Id  }
            );
            await db.SaveChangesAsync();

            // ── Carts ───────────────────────────────────────────────────────────
            db.Carts.AddRange(
                new Cart { UserId = userAdmin.Id },
                new Cart { UserId = userJohn.Id  },
                new Cart { UserId = userJane.Id  },
                new Cart { UserId = userMarko.Id },
                new Cart { UserId = userAna.Id   },
                new Cart { UserId = userLena.Id  }
            );
            await db.SaveChangesAsync();

            // ── Books ───────────────────────────────────────────────────────────
            // Prices: b1=24.99 b2=24.99 b3=29.99 b4=29.99 b5=19.99
            //         b6=18.99 b7=22.99 b8=27.99 b9=21.99 b10=23.99
            //         b11=16.99 b12=15.99 b13=20.99 b14=18.99 b15=19.99
            var book1 = new Book {
                Title = "Harry Potter and the Philosopher's Stone",
                AuthorId = authorRowling.Id,
                Description = "A young boy discovers he is a wizard and begins his education at Hogwarts School of Witchcraft and Wizardry, where he learns about his famous past.",
                PublicationDate = new DateTime(1997, 6, 26),
                CoverImageUrl = "https://covers.openlibrary.org/b/id/10521270-L.jpg",
                PageCount = 223, Price = 24.99m, Stock = 50
            };
            var book2 = new Book {
                Title = "Harry Potter and the Chamber of Secrets",
                AuthorId = authorRowling.Id,
                Description = "Harry Potter's second year at Hogwarts is marked by a series of attacks on Muggle-born students and a dark creature lurking within the walls.",
                PublicationDate = new DateTime(1998, 7, 2),
                CoverImageUrl = "https://covers.openlibrary.org/b/id/8406786-L.jpg",
                PageCount = 251, Price = 24.99m, Stock = 40
            };
            var book3 = new Book {
                Title = "A Game of Thrones",
                AuthorId = authorMartin.Id,
                Description = "Noble families fight for control of the Iron Throne in the fictional Seven Kingdoms of Westeros in this epic fantasy saga.",
                PublicationDate = new DateTime(1996, 8, 1),
                CoverImageUrl = "https://covers.openlibrary.org/b/id/8592826-L.jpg",
                PageCount = 694, Price = 29.99m, Stock = 35
            };
            var book4 = new Book {
                Title = "A Clash of Kings",
                AuthorId = authorMartin.Id,
                Description = "A comet heralds the war of five kings vying for the Iron Throne as chaos spreads across Westeros.",
                PublicationDate = new DateTime(1998, 11, 16),
                CoverImageUrl = "https://covers.openlibrary.org/b/id/8592827-L.jpg",
                PageCount = 768, Price = 29.99m, Stock = 30
            };
            var book5 = new Book {
                Title = "Murder on the Orient Express",
                AuthorId = authorChristie.Id,
                Description = "The famous detective Hercule Poirot investigates a murder that occurs on the snowbound Orient Express train.",
                PublicationDate = new DateTime(1934, 1, 1),
                CoverImageUrl = "https://covers.openlibrary.org/b/id/8084117-L.jpg",
                PageCount = 256, Price = 19.99m, Stock = 45
            };
            var book6 = new Book {
                Title = "And Then There Were None",
                AuthorId = authorChristie.Id,
                Description = "Ten strangers are lured to an isolated island and murdered one by one, following a chilling nursery rhyme.",
                PublicationDate = new DateTime(1939, 11, 6),
                CoverImageUrl = "https://covers.openlibrary.org/b/id/8232590-L.jpg",
                PageCount = 264, Price = 18.99m, Stock = 55
            };
            var book7 = new Book {
                Title = "The Shining",
                AuthorId = authorKing.Id,
                Description = "A writer becomes the winter caretaker of the isolated Overlook Hotel, where a dark supernatural presence threatens his family.",
                PublicationDate = new DateTime(1977, 1, 28),
                CoverImageUrl = "https://covers.openlibrary.org/b/id/8232588-L.jpg",
                PageCount = 447, Price = 22.99m, Stock = 25
            };
            var book8 = new Book {
                Title = "IT",
                AuthorId = authorKing.Id,
                Description = "A group of childhood friends reunite to battle the terrifying shapeshifting monster that terrorized them as children in Derry, Maine.",
                PublicationDate = new DateTime(1986, 9, 15),
                CoverImageUrl = "https://covers.openlibrary.org/b/id/8232589-L.jpg",
                PageCount = 1138, Price = 27.99m, Stock = 20
            };
            var book9 = new Book {
                Title = "The Hobbit",
                AuthorId = authorTolkien.Id,
                Description = "A reluctant hobbit is swept into an epic quest to reclaim the lost Dwarf Kingdom of Erebor from the fearsome dragon Smaug.",
                PublicationDate = new DateTime(1937, 9, 21),
                CoverImageUrl = "https://covers.openlibrary.org/b/id/8406787-L.jpg",
                PageCount = 310, Price = 21.99m, Stock = 60
            };
            var book10 = new Book {
                Title = "The Fellowship of the Ring",
                AuthorId = authorTolkien.Id,
                Description = "Frodo Baggins inherits the One Ring and begins a perilous journey to destroy it in the fires of Mount Doom.",
                PublicationDate = new DateTime(1954, 7, 29),
                CoverImageUrl = "https://covers.openlibrary.org/b/id/8406788-L.jpg",
                PageCount = 423, Price = 23.99m, Stock = 45
            };
            var book11 = new Book {
                Title = "Pride and Prejudice",
                AuthorId = authorAusten.Id,
                Description = "The spirited Elizabeth Bennet navigates issues of manners, upbringing, morality, and marriage in early 19th-century England.",
                PublicationDate = new DateTime(1813, 1, 28),
                CoverImageUrl = "https://covers.openlibrary.org/b/id/8091016-L.jpg",
                PageCount = 432, Price = 16.99m, Stock = 70
            };
            var book12 = new Book {
                Title = "Sense and Sensibility",
                AuthorId = authorAusten.Id,
                Description = "Two sisters—Elinor and Marianne Dashwood—navigate love, heartbreak, and society in early 19th-century England.",
                PublicationDate = new DateTime(1811, 10, 30),
                CoverImageUrl = "https://covers.openlibrary.org/b/id/8091017-L.jpg",
                PageCount = 374, Price = 15.99m, Stock = 65
            };
            var book13 = new Book {
                Title = "One Hundred Years of Solitude",
                AuthorId = authorMarquez.Id,
                Description = "The multi-generational story of the Buendía family in the fictional town of Macondo, a landmark of magical realism.",
                PublicationDate = new DateTime(1967, 5, 30),
                CoverImageUrl = "https://covers.openlibrary.org/b/id/8232591-L.jpg",
                PageCount = 417, Price = 20.99m, Stock = 30
            };
            var book14 = new Book {
                Title = "Norwegian Wood",
                AuthorId = authorMurakami.Id,
                Description = "A nostalgic story of loss, love, and melancholy set in late 1960s Tokyo, following Toru Watanabe's coming of age.",
                PublicationDate = new DateTime(1987, 9, 4),
                CoverImageUrl = "https://covers.openlibrary.org/b/id/8232593-L.jpg",
                PageCount = 296, Price = 18.99m, Stock = 35
            };
            var book15 = new Book {
                Title = "Kafka on the Shore",
                AuthorId = authorMurakami.Id,
                Description = "A metaphysical masterpiece about a teenage runaway and an elderly man with supernatural abilities, weaving two parallel stories.",
                PublicationDate = new DateTime(2002, 9, 12),
                CoverImageUrl = "https://covers.openlibrary.org/b/id/8232594-L.jpg",
                PageCount = 467, Price = 19.99m, Stock = 28
            };
            db.Books.AddRange(book1, book2, book3, book4, book5, book6, book7, book8,
                              book9, book10, book11, book12, book13, book14, book15);
            await db.SaveChangesAsync();

            // ── Book Categories ─────────────────────────────────────────────────
            db.BookCategories.AddRange(
                new BookCategory { BookId = book1.Id,  CategoryId = catFantasy.Id },
                new BookCategory { BookId = book1.Id,  CategoryId = catFiction.Id },
                new BookCategory { BookId = book2.Id,  CategoryId = catFantasy.Id },
                new BookCategory { BookId = book2.Id,  CategoryId = catFiction.Id },
                new BookCategory { BookId = book3.Id,  CategoryId = catFantasy.Id },
                new BookCategory { BookId = book4.Id,  CategoryId = catFantasy.Id },
                new BookCategory { BookId = book5.Id,  CategoryId = catMystery.Id },
                new BookCategory { BookId = book6.Id,  CategoryId = catMystery.Id },
                new BookCategory { BookId = book7.Id,  CategoryId = catFiction.Id },
                new BookCategory { BookId = book8.Id,  CategoryId = catFiction.Id },
                new BookCategory { BookId = book9.Id,  CategoryId = catFantasy.Id },
                new BookCategory { BookId = book10.Id, CategoryId = catFantasy.Id },
                new BookCategory { BookId = book11.Id, CategoryId = catRomance.Id },
                new BookCategory { BookId = book11.Id, CategoryId = catFiction.Id },
                new BookCategory { BookId = book12.Id, CategoryId = catRomance.Id },
                new BookCategory { BookId = book12.Id, CategoryId = catFiction.Id },
                new BookCategory { BookId = book13.Id, CategoryId = catFiction.Id },
                new BookCategory { BookId = book14.Id, CategoryId = catFiction.Id },
                new BookCategory { BookId = book14.Id, CategoryId = catRomance.Id },
                new BookCategory { BookId = book15.Id, CategoryId = catFiction.Id }
            );
            await db.SaveChangesAsync();

            // ── Events ──────────────────────────────────────────────────────────
            var event1 = new Event {
                Name = "Harry Potter Book Reading",
                Description = "A magical evening reading from Harry Potter and the Philosopher's Stone, hosted at the historic Vijećnica building.",
                EventCategoryId = evCatReading.Id, OrganizerId = org1.Id,
                EventDate = new DateTime(2026, 6, 15), EventTime = new TimeSpan(18, 0, 0),
                EventType = EventType.InPerson,
                Address = "Vijećnica, Obala Kulina bana 4",
                CityId = citySarajevo.Id, CountryId = countryBiH.Id,
                TicketPrice = 10.00m, Capacity = 100, IsActive = true, ReservedSeats = 2,
                ImageUrl = "https://covers.openlibrary.org/b/id/10521270-L.jpg"
            };
            var event2 = new Event {
                Name = "Fantasy Writers Workshop",
                Description = "A hands-on online workshop for aspiring fantasy writers covering world-building, character development, and plot structure.",
                EventCategoryId = evCatWorkshop.Id, OrganizerId = org2.Id,
                EventDate = new DateTime(2026, 7, 10), EventTime = new TimeSpan(14, 0, 0),
                EventType = EventType.Online,
                TicketPrice = 0.00m, Capacity = 200, IsActive = true, ReservedSeats = 1,
                ImageUrl = "https://covers.openlibrary.org/b/id/8592826-L.jpg"
            };
            var event3 = new Event {
                Name = "Sarajevo Literary Festival",
                Description = "Annual literary festival celebrating local and international authors with readings, panel discussions, and book signings.",
                EventCategoryId = evCatFestival.Id, OrganizerId = org1.Id,
                EventDate = new DateTime(2026, 8, 20), EventTime = new TimeSpan(10, 0, 0),
                EventType = EventType.InPerson,
                Address = "Baščaršija, Sarajevo",
                CityId = citySarajevo.Id, CountryId = countryBiH.Id,
                TicketPrice = 15.00m, Capacity = 500, IsActive = true, ReservedSeats = 2,
                ImageUrl = "https://covers.openlibrary.org/b/id/8232591-L.jpg"
            };
            var event4 = new Event {
                Name = "Meet Agatha Christie's World",
                Description = "An immersive evening exploring the life and works of Agatha Christie with themed readings and a murder mystery game.",
                EventCategoryId = evCatMeetup.Id, OrganizerId = org3.Id,
                EventDate = new DateTime(2026, 9, 5), EventTime = new TimeSpan(19, 30, 0),
                EventType = EventType.InPerson,
                Address = "British Library, 96 Euston Road",
                CityId = cityLondon.Id, CountryId = countryUK.Id,
                TicketPrice = 20.00m, Capacity = 80, IsActive = true, ReservedSeats = 1,
                ImageUrl = "https://covers.openlibrary.org/b/id/8084117-L.jpg"
            };
            var event5 = new Event {
                Name = "Poetry Night Mostar",
                Description = "An enchanting free evening of poetry reading under the stars by the Neretva River in the heart of Mostar.",
                EventCategoryId = evCatPoetry.Id, OrganizerId = org4.Id,
                EventDate = new DateTime(2026, 6, 30), EventTime = new TimeSpan(20, 0, 0),
                EventType = EventType.InPerson,
                Address = "Stari Most, Mostar",
                CityId = cityMostar.Id, CountryId = countryBiH.Id,
                TicketPrice = 0.00m, Capacity = 60, IsActive = true, ReservedSeats = 2
            };
            var event6 = new Event {
                Name = "Online Tolkien Reading Club",
                Description = "A virtual reading session for fans of J.R.R. Tolkien's Middle-earth, exploring The Fellowship of the Ring chapter by chapter.",
                EventCategoryId = evCatReading.Id, OrganizerId = org2.Id,
                EventDate = new DateTime(2026, 7, 25), EventTime = new TimeSpan(17, 0, 0),
                EventType = EventType.Online,
                TicketPrice = 5.00m, Capacity = 150, IsActive = true, ReservedSeats = 2,
                ImageUrl = "https://covers.openlibrary.org/b/id/8406787-L.jpg"
            };
            db.Events.AddRange(event1, event2, event3, event4, event5, event6);
            await db.SaveChangesAsync();

            // ── Favorites ───────────────────────────────────────────────────────
            db.Favorites.AddRange(
                new Favorite { UserId = userJohn.Id,  BookId = book1.Id  },
                new Favorite { UserId = userJohn.Id,  BookId = book3.Id  },
                new Favorite { UserId = userJohn.Id,  BookId = book9.Id  },
                new Favorite { UserId = userJane.Id,  BookId = book11.Id },
                new Favorite { UserId = userJane.Id,  BookId = book14.Id },
                new Favorite { UserId = userMarko.Id, BookId = book5.Id  },
                new Favorite { UserId = userMarko.Id, BookId = book7.Id  },
                new Favorite { UserId = userMarko.Id, BookId = book8.Id  },
                new Favorite { UserId = userAna.Id,   BookId = book11.Id },
                new Favorite { UserId = userAna.Id,   BookId = book12.Id },
                new Favorite { UserId = userAna.Id,   BookId = book13.Id },
                new Favorite { UserId = userLena.Id,  BookId = book14.Id },
                new Favorite { UserId = userLena.Id,  BookId = book15.Id },
                new Favorite { UserId = userLena.Id,  BookId = book2.Id  },
                new Favorite { UserId = userAdmin.Id, BookId = book1.Id  }
            );
            await db.SaveChangesAsync();

            // ── TBR Lists ───────────────────────────────────────────────────────
            db.TBRLists.AddRange(
                new TBRList { UserId = userJohn.Id,  BookId = book2.Id,  ReadingStatus = ReadingStatus.Read     },
                new TBRList { UserId = userJohn.Id,  BookId = book4.Id,  ReadingStatus = ReadingStatus.ToBeRead },
                new TBRList { UserId = userJane.Id,  BookId = book12.Id, ReadingStatus = ReadingStatus.Reading  },
                new TBRList { UserId = userJane.Id,  BookId = book13.Id, ReadingStatus = ReadingStatus.ToBeRead },
                new TBRList { UserId = userMarko.Id, BookId = book6.Id,  ReadingStatus = ReadingStatus.Read     },
                new TBRList { UserId = userMarko.Id, BookId = book10.Id, ReadingStatus = ReadingStatus.ToBeRead },
                new TBRList { UserId = userAna.Id,   BookId = book11.Id, ReadingStatus = ReadingStatus.Read     },
                new TBRList { UserId = userAna.Id,   BookId = book14.Id, ReadingStatus = ReadingStatus.Reading  },
                new TBRList { UserId = userLena.Id,  BookId = book15.Id, ReadingStatus = ReadingStatus.Reading  },
                new TBRList { UserId = userLena.Id,  BookId = book3.Id,  ReadingStatus = ReadingStatus.ToBeRead }
            );
            await db.SaveChangesAsync();

            // ── Shippings ───────────────────────────────────────────────────────
            var ship1 = new Shipping { Address = "Ferhadija 5",           CityId = citySarajevo.Id, CountryId = countryBiH.Id, PostalCode = "71000", ShippedDate = new DateTime(2026, 1, 13) };
            var ship2 = new Shipping { Address = "Obala Kulina Bana 3",   CityId = citySarajevo.Id, CountryId = countryBiH.Id, PostalCode = "71000", ShippedDate = new DateTime(2026, 3, 21) };
            var ship3 = new Shipping { Address = "Unter den Linden 10",   CityId = cityBerlin.Id,   CountryId = countryDE.Id,  PostalCode = "10117", ShippedDate = new DateTime(2026, 2, 8)  };
            var ship4 = new Shipping { Address = "Bulevar 12",            CityId = cityMostar.Id,   CountryId = countryBiH.Id, PostalCode = "88000" };
            var ship5 = new Shipping { Address = "Maximilianstrasse 20",  CityId = cityMunich.Id,   CountryId = countryDE.Id,  PostalCode = "80539" };
            var ship6 = new Shipping { Address = "Ferhadija 5",           CityId = citySarajevo.Id, CountryId = countryBiH.Id, PostalCode = "71000" };
            db.Shippings.AddRange(ship1, ship2, ship3, ship4, ship5, ship6);
            await db.SaveChangesAsync();

            // ── Orders ──────────────────────────────────────────────────────────
            // Order 1: John, Delivered  — book1(24.99) x1 + book9(21.99) x1 = 46.98
            // Order 2: Jane, Delivered  — book11(16.99) x1 + book12(15.99) x1 = 32.98
            // Order 3: Marko, Shipped   — book5(19.99) x1 + book7(22.99) x1 = 42.98
            // Order 4: Ana, Pending  — book11(16.99) x1 + book14(18.99) x1 = 35.98
            // Order 5: Lena, Pending    — book14(18.99) x1 + book15(19.99) x1 = 38.98
            // Order 6: John, Cancelled  — book3(29.99) x1 = 29.99
            var order1 = new Order { UserId = userJohn.Id,  OrderDate = new DateTime(2026, 1, 10), ShippedDate = new DateTime(2026, 1, 13), Status = OrderStatus.Delivered,  TotalPrice = 46.98m, ShippingId = ship1.Id };
            var order2 = new Order { UserId = userJane.Id,  OrderDate = new DateTime(2026, 2, 5),  ShippedDate = new DateTime(2026, 2, 8),  Status = OrderStatus.Delivered,  TotalPrice = 32.98m, ShippingId = ship3.Id };
            var order3 = new Order { UserId = userMarko.Id, OrderDate = new DateTime(2026, 3, 18), ShippedDate = new DateTime(2026, 3, 21), Status = OrderStatus.Shipped,    TotalPrice = 42.98m, ShippingId = ship2.Id };
            var order4 = new Order { UserId = userAna.Id,   OrderDate = new DateTime(2026, 4, 2),                                          Status = OrderStatus.Pending,    TotalPrice = 35.98m, ShippingId = ship4.Id };
            var order5 = new Order { UserId = userLena.Id,  OrderDate = new DateTime(2026, 4, 20),                                         Status = OrderStatus.Pending,    TotalPrice = 38.98m, ShippingId = ship5.Id };
            var order6 = new Order { UserId = userJohn.Id,  OrderDate = new DateTime(2026, 5, 1),                                          Status = OrderStatus.Cancelled,  TotalPrice = 29.99m, ShippingId = ship6.Id };
            db.Orders.AddRange(order1, order2, order3, order4, order5, order6);
            await db.SaveChangesAsync();

            // ── Order Items ─────────────────────────────────────────────────────
            db.OrderItems.AddRange(
                new OrderItem { OrderId = order1.Id, BookId = book1.Id,  Quantity = 1, Price = 24.99m },
                new OrderItem { OrderId = order1.Id, BookId = book9.Id,  Quantity = 1, Price = 21.99m },
                new OrderItem { OrderId = order2.Id, BookId = book11.Id, Quantity = 1, Price = 16.99m },
                new OrderItem { OrderId = order2.Id, BookId = book12.Id, Quantity = 1, Price = 15.99m },
                new OrderItem { OrderId = order3.Id, BookId = book5.Id,  Quantity = 1, Price = 19.99m },
                new OrderItem { OrderId = order3.Id, BookId = book7.Id,  Quantity = 1, Price = 22.99m },
                new OrderItem { OrderId = order4.Id, BookId = book11.Id, Quantity = 1, Price = 16.99m },
                new OrderItem { OrderId = order4.Id, BookId = book14.Id, Quantity = 1, Price = 18.99m },
                new OrderItem { OrderId = order5.Id, BookId = book14.Id, Quantity = 1, Price = 18.99m },
                new OrderItem { OrderId = order5.Id, BookId = book15.Id, Quantity = 1, Price = 19.99m },
                new OrderItem { OrderId = order6.Id, BookId = book3.Id,  Quantity = 1, Price = 29.99m }
            );
            await db.SaveChangesAsync();

            // ── Order Payments ──────────────────────────────────────────────────
            // Payments for delivered and shipped orders; skipped for pending/cancelled
            db.Payments.AddRange(
                new Payment { UserId = userJohn.Id,  OrderId = order1.Id, PaymentMethod = PaymentMethod.Card,          Amount = 46.98m, PaymentDate = new DateTime(2026, 1, 10), IsSuccessful = true, TransactionId = "txn_seed_001" },
                new Payment { UserId = userJane.Id,  OrderId = order2.Id, PaymentMethod = PaymentMethod.Card,          Amount = 32.98m, PaymentDate = new DateTime(2026, 2, 5),  IsSuccessful = true, TransactionId = "txn_seed_002" },
                new Payment { UserId = userMarko.Id, OrderId = order3.Id, PaymentMethod = PaymentMethod.CashOnDelivery, Amount = 42.98m, PaymentDate = new DateTime(2026, 3, 21), IsSuccessful = true, TransactionId = "txn_seed_003" },
                new Payment { UserId = userAna.Id,   OrderId = order4.Id, PaymentMethod = PaymentMethod.Card,          Amount = 35.98m, PaymentDate = new DateTime(2026, 4, 2),  IsSuccessful = true, TransactionId = "txn_seed_004" }
            );
            await db.SaveChangesAsync();

            // ── Event Reservations ──────────────────────────────────────────────
            // event1 (10.00/ticket), event2 (free), event3 (15.00/ticket),
            // event4 (20.00/ticket), event5 (free), event6 (5.00/ticket)
            var res1 = new EventReservation {
                UserId = userJohn.Id,  EventId = event1.Id,
                EventDateTime = new DateTime(2026, 6, 15, 18, 0, 0),
                ReservationDate = new DateTime(2026, 5, 10),
                Quantity = 2, TotalPrice = 20.00m,
                ReservationStatus = ReservationStatus.Confirmed,
                TicketQRCodeLink = "https://api.qrserver.com/v1/create-qr-code/?data=RES001&size=200x200"
            };
            var res2 = new EventReservation {
                UserId = userJane.Id,  EventId = event2.Id,
                EventDateTime = new DateTime(2026, 7, 10, 14, 0, 0),
                ReservationDate = new DateTime(2026, 6, 1),
                Quantity = 1, TotalPrice = 0.00m,
                ReservationStatus = ReservationStatus.Confirmed,
                TicketQRCodeLink = "https://api.qrserver.com/v1/create-qr-code/?data=RES002&size=200x200"
            };
            var res3 = new EventReservation {
                UserId = userMarko.Id, EventId = event3.Id,
                EventDateTime = new DateTime(2026, 8, 20, 10, 0, 0),
                ReservationDate = new DateTime(2026, 7, 5),
                Quantity = 2, TotalPrice = 30.00m,
                ReservationStatus = ReservationStatus.Confirmed,
                TicketQRCodeLink = "https://api.qrserver.com/v1/create-qr-code/?data=RES003&size=200x200"
            };
            var res4 = new EventReservation {
                UserId = userAna.Id,   EventId = event4.Id,
                EventDateTime = new DateTime(2026, 9, 5, 19, 30, 0),
                ReservationDate = new DateTime(2026, 8, 1),
                Quantity = 1, TotalPrice = 20.00m,
                ReservationStatus = ReservationStatus.Pending,
                TicketQRCodeLink = "https://api.qrserver.com/v1/create-qr-code/?data=RES004&size=200x200"
            };
            var res5 = new EventReservation {
                UserId = userLena.Id,  EventId = event5.Id,
                EventDateTime = new DateTime(2026, 6, 30, 20, 0, 0),
                ReservationDate = new DateTime(2026, 5, 20),
                Quantity = 2, TotalPrice = 0.00m,
                ReservationStatus = ReservationStatus.Confirmed,
                TicketQRCodeLink = "https://api.qrserver.com/v1/create-qr-code/?data=RES005&size=200x200"
            };
            var res6 = new EventReservation {
                UserId = userAna.Id,   EventId = event6.Id,
                EventDateTime = new DateTime(2026, 7, 25, 17, 0, 0),
                ReservationDate = new DateTime(2026, 6, 15),
                Quantity = 2, TotalPrice = 10.00m,
                ReservationStatus = ReservationStatus.Confirmed,
                TicketQRCodeLink = "https://api.qrserver.com/v1/create-qr-code/?data=RES006&size=200x200"
            };
            db.EventReservations.AddRange(res1, res2, res3, res4, res5, res6);
            await db.SaveChangesAsync();

            // ── Event Reservation Payments ──────────────────────────────────────
            // Only for paid events (TicketPrice > 0) with confirmed reservations
            db.Payments.AddRange(
                new Payment { UserId = userJohn.Id,  EventReservationId = res1.Id, PaymentMethod = PaymentMethod.Card, Amount = 20.00m, PaymentDate = new DateTime(2026, 5, 10), IsSuccessful = true, TransactionId = "txn_seed_005" },
                new Payment { UserId = userMarko.Id, EventReservationId = res3.Id, PaymentMethod = PaymentMethod.Card, Amount = 30.00m, PaymentDate = new DateTime(2026, 7, 5),  IsSuccessful = true, TransactionId = "txn_seed_006" },
                new Payment { UserId = userAna.Id,   EventReservationId = res6.Id, PaymentMethod = PaymentMethod.Card, Amount = 10.00m, PaymentDate = new DateTime(2026, 6, 15), IsSuccessful = true, TransactionId = "txn_seed_007" }
            );
            await db.SaveChangesAsync();

            // ── Reviews ─────────────────────────────────────────────────────────
            db.Reviews.AddRange(
                new Review { UserId = userJohn.Id,  BookId = book1.Id,  Rating = 5, Comment = "Amazing start to an iconic series! The world-building is extraordinary.", CreatedAt = new DateTime(2026, 1, 20) },
                new Review { UserId = userJohn.Id,  BookId = book3.Id,  Rating = 5, Comment = "Epic fantasy at its best. Complex characters and a rich world.",           CreatedAt = new DateTime(2026, 2, 5)  },
                new Review { UserId = userJane.Id,  BookId = book11.Id, Rating = 4, Comment = "A timeless classic. Elizabeth Bennet is one of literature's finest heroines.", CreatedAt = new DateTime(2026, 2, 20) },
                new Review { UserId = userJane.Id,  BookId = book14.Id, Rating = 5, Comment = "Beautifully melancholic. Murakami's prose is lyrical and haunting.",         CreatedAt = new DateTime(2026, 3, 1)  },
                new Review { UserId = userMarko.Id, BookId = book5.Id,  Rating = 5, Comment = "Brilliant mystery with a twist I never saw coming. Christie at her peak.",    CreatedAt = new DateTime(2026, 3, 25) },
                new Review { UserId = userMarko.Id, BookId = book7.Id,  Rating = 4, Comment = "Genuinely terrifying. King's character development is masterful.",            CreatedAt = new DateTime(2026, 4, 10) },
                new Review { UserId = userAna.Id,   BookId = book12.Id, Rating = 4, Comment = "Beautiful writing and relatable characters navigating love and society.",     CreatedAt = new DateTime(2026, 4, 20) },
                new Review { UserId = userLena.Id,  BookId = book14.Id, Rating = 5, Comment = "Emotional and poetic. This book stayed with me for weeks.",                  CreatedAt = new DateTime(2026, 5, 1)  },
                new Review { UserId = userJohn.Id,  EventId = event1.Id, Rating = 5, Comment = "An unforgettable evening at Vijećnica. Magical atmosphere!",               CreatedAt = new DateTime(2026, 6, 16) },
                new Review { UserId = userMarko.Id, EventId = event3.Id, Rating = 4, Comment = "Great atmosphere and wonderful panel discussions at the festival.",          CreatedAt = new DateTime(2026, 8, 22) }
            );
            await db.SaveChangesAsync();
        }
    }
}
