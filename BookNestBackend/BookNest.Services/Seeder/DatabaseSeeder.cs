using BookNest.Model.Constants;
using BookNest.Services.Database;
using BookNest.Services.Database.Entities;
using BookNest.Services.Security;
using Microsoft.EntityFrameworkCore;

namespace BookNest.Services.Seeder
{
    public static class DatabaseSeeder
    {
        public static async Task SeedAsync(
            BookNestDbContext context,
            IPasswordHasher passwordHasher,
            CancellationToken ct = default)
        {
            if (await context.Roles.AnyAsync(ct))
                return;

            await SeedFixedDataAsync(context, ct);
            await SeedReferenceDataAsync(context, passwordHasher, ct);
        }

        private static async Task SeedFixedDataAsync(
            BookNestDbContext context,
            CancellationToken ct)
        {
            await InsertWithIdentityAsync(
                context,
                "Roles",
                async () =>
                {
                    context.Roles.AddRange(
                        new Role { Id = 1, Name = "Admin" },
                        new Role { Id = 2, Name = "User"  }
                    );
                    await context.SaveChangesAsync(ct);
                });

            await InsertWithIdentityAsync(
                context,
                "ReservationStatuses",
                async () =>
                {
                    context.ReservationStatuses.AddRange(
                        new ReservationStatus { Id = ReservationStatuses.Pending,   Name = "Pending"   },
                        new ReservationStatus { Id = ReservationStatuses.Confirmed, Name = "Confirmed" },
                        new ReservationStatus { Id = ReservationStatuses.Cancelled, Name = "Cancelled" }
                    );
                    await context.SaveChangesAsync(ct);
                });

            await InsertWithIdentityAsync(
                context,
                "OrderStatuses",
                async () =>
                {
                    context.OrderStatuses.AddRange(
                        new OrderStatus { Id = OrderStatuses.Pending,   Name = "Pending"   },
                        new OrderStatus { Id = OrderStatuses.Shipped,   Name = "Shipped"   },
                        new OrderStatus { Id = OrderStatuses.Delivered, Name = "Delivered" },
                        new OrderStatus { Id = OrderStatuses.Cancelled, Name = "Cancelled" }
                    );
                    await context.SaveChangesAsync(ct);
                });

            await InsertWithIdentityAsync(
                context,
                "PaymentMethods",
                async () =>
                {
                    context.PaymentMethods.AddRange(
                        new PaymentMethod { Id = PaymentMethods.CashOnDelivery, Name = "CashOnDelivery" },
                        new PaymentMethod { Id = PaymentMethods.Card,           Name = "Card"           }
                    );
                    await context.SaveChangesAsync(ct);
                });

            await InsertWithIdentityAsync(
                context,
                "EventTypes",
                async () =>
                {
                    context.EventTypes.AddRange(
                        new EventType { Id = EventTypes.Online,   Name = "Online"   },
                        new EventType { Id = EventTypes.InPerson, Name = "InPerson" }
                    );
                    await context.SaveChangesAsync(ct);
                });

            await InsertWithIdentityAsync(
                context,
                "ReadingStatuses",
                async () =>
                {
                    context.ReadingStatuses.AddRange(
                        new ReadingStatus { Id = ReadingStatuses.ToBeRead, Name = "ToBeRead" },
                        new ReadingStatus { Id = ReadingStatuses.Reading,  Name = "Reading"  },
                        new ReadingStatus { Id = ReadingStatuses.Read,     Name = "Read"     }
                    );
                    await context.SaveChangesAsync(ct);
                });

            await InsertWithIdentityAsync(
                context,
                "NotificationTypes",
                async () =>
                {
                    context.NotificationTypes.AddRange(
                        new NotificationType { Id = NotificationTypes.OrderStatusChanged,            Name = "OrderStatusChanged"            },
                        new NotificationType { Id = NotificationTypes.ReservationStatusChanged,      Name = "ReservationStatusChanged"      },
                        new NotificationType { Id = NotificationTypes.EventReminder,                 Name = "EventReminder"                 },
                        new NotificationType { Id = NotificationTypes.BookUnavailable,               Name = "BookUnavailable"               },
                        new NotificationType { Id = NotificationTypes.EventCancelled,                Name = "EventCancelled"                },
                        new NotificationType { Id = NotificationTypes.NewOrder,                      Name = "NewOrder"                      },
                        new NotificationType { Id = NotificationTypes.NewReservation,                Name = "NewReservation"                },
                        new NotificationType { Id = NotificationTypes.OrderCancelledByUser,          Name = "OrderCancelledByUser"          },
                        new NotificationType { Id = NotificationTypes.ReservationCancelledByUser,    Name = "ReservationCancelledByUser"    }
                    );
                    await context.SaveChangesAsync(ct);
                });
        }

        private static async Task SeedReferenceDataAsync(
            BookNestDbContext context,
            IPasswordHasher passwordHasher,
            CancellationToken ct)
        {
            var countryBiH = new Country { Name = "Bosnia and Herzegovina" };
            var countrySerbia = new Country { Name = "Serbia" };
            var countryCroatia = new Country { Name = "Croatia" };
            context.Countries.AddRange(countryBiH, countrySerbia, countryCroatia);
            await context.SaveChangesAsync(ct);

            var citySarajevo = new City { Name = "Sarajevo", CountryId = countryBiH.Id };
            var cityMostar   = new City { Name = "Mostar",   CountryId = countryBiH.Id };
            var cityKonjic   = new City { Name = "Konjic",   CountryId = countryBiH.Id };
            var cityBelgrade = new City { Name = "Belgrade",  CountryId = countrySerbia.Id };
            var cityNoviSad  = new City { Name = "Novi Sad",  CountryId = countrySerbia.Id };
            var cityNis      = new City { Name = "Niš",       CountryId = countrySerbia.Id };
            var cityZagreb   = new City { Name = "Zagreb",    CountryId = countryCroatia.Id };
            var citySplit    = new City { Name = "Split",     CountryId = countryCroatia.Id };
            var cityRijeka   = new City { Name = "Rijeka",    CountryId = countryCroatia.Id };
            context.Cities.AddRange(
                citySarajevo, cityMostar, cityKonjic,
                cityBelgrade, cityNoviSad, cityNis,
                cityZagreb, citySplit, cityRijeka);
            await context.SaveChangesAsync(ct);

            var catAdventure = new Category { Name = "Adventure" };
            var catBiography = new Category { Name = "Biography"  };
            var catRomance   = new Category { Name = "Romance"    };
            context.Categories.AddRange(catAdventure, catBiography, catRomance);
            await context.SaveChangesAsync(ct);

            var evCatBookClub     = new EventCategory { Name = "Book Club",      Description = "Gatherings of book lovers to read and discuss selected titles together." };
            var evCatPromotions   = new EventCategory { Name = "Book Promotions", Description = "Official book launch events and promotional sessions with authors." };
            var evCatReadAndRelax = new EventCategory { Name = "Read & Relax",    Description = "Laid-back reading sessions in a cozy, welcoming atmosphere." };
            context.EventCategories.AddRange(evCatBookClub, evCatPromotions, evCatReadAndRelax);
            await context.SaveChangesAsync(ct);

            var authorMcFadden = new Author
            {
                FirstName = "Frieda", LastName = "McFadden",
                DateOfBirth = new DateTime(1980, 5, 15),
                Biography = "Frieda McFadden is a New York Times and USA Today bestselling author of psychological thrillers. She worked as a physician specializing in brain injury for many years before turning to writing full-time.",
                ImageUrl = "https://booknestimages.blob.core.windows.net/author-images/Author_The_Housemaid's_Secret.png"
            };

            var authorBorison = new Author
            {
                FirstName = "B.K.", LastName = "Borison",
                DateOfBirth = new DateTime(1990, 3, 22),
                Biography = "B.K. Borison is a New York Times bestselling author of contemporary romance novels known for her witty banter, heartfelt emotion, and charming small-town settings.",
                ImageUrl = "https://booknestimages.blob.core.windows.net/author-images/Authors_And_Now_Back_To_You.png"
            };

            var authorSerpell = new Author
            {
                FirstName = "Namwali", LastName = "Serpell",
                DateOfBirth = new DateTime(1980, 7, 8),
                Biography = "Namwali Serpell is a Zambian writer and Harvard professor. She won the Caine Prize for African Writing and is the author of The Old Drift, a sweeping novel spanning three generations of Zambian history.",
                ImageUrl = "https://booknestimages.blob.core.windows.net/author-images/Authors_On_Morrison.png"
            };

            var authorAdams = new Author
            {
                FirstName = "Ann", LastName = "Adams",
                DateOfBirth = new DateTime(1985, 11, 3),
                Biography = "Ann Adams is a romance author celebrated for her sports-themed love stories that combine athletic passion, competitive spirit, and heartfelt connection.",
                ImageUrl = "https://booknestimages.blob.core.windows.net/author-images/Authors_Racing_Hearts.png"
            };

            var authorBarnes = new Author
            {
                FirstName = "Jennifer Lynn", LastName = "Barnes",
                DateOfBirth = new DateTime(1983, 1, 20),
                Biography = "Jennifer Lynn Barnes is a #1 New York Times bestselling author of young adult thrillers and mysteries. She holds a PhD in developmental psychology and is a professor of writing at the University of Oklahoma.",
                ImageUrl = "https://booknestimages.blob.core.windows.net/author-images/Authors_The_Final_Gambit.png"
            };

            var authorRoberts = new Author
            {
                FirstName = "Dorothy E.", LastName = "Roberts",
                DateOfBirth = new DateTime(1956, 9, 12),
                Biography = "Dorothy E. Roberts is a Penn Integrates Knowledge Professor at the University of Pennsylvania and one of America's leading scholars on race, gender, and the law.",
                ImageUrl = "https://booknestimages.blob.core.windows.net/author-images/Authors_The_Mixed_Marriage_Project.png"
            };

            var authorGriffin = new Author
            {
                FirstName = "Rachel", LastName = "Griffin",
                DateOfBirth = new DateTime(1993, 6, 25),
                Biography = "Rachel Griffin is a New York Times bestselling author of romantic fantasy novels, best known for The Nature of Witches series.",
                ImageUrl = "https://booknestimages.blob.core.windows.net/author-images/Authors_The_Sun_And_The_Starmaker.png"
            };

            var authorBrower = new Author
            {
                FirstName = "Kate Andersen", LastName = "Brower",
                DateOfBirth = new DateTime(1978, 2, 14),
                Biography = "Kate Andersen Brower is an award-winning journalist and New York Times bestselling author known for her in-depth portraits of American political life.",
                ImageUrl = "https://booknestimages.blob.core.windows.net/author-images/Authors_We_The_Women.png"
            };

            context.Authors.AddRange(
                authorMcFadden, authorBorison, authorSerpell, authorAdams,
                authorBarnes, authorRoberts, authorGriffin, authorBrower);
            await context.SaveChangesAsync(ct);

            var org1 = new Organizer { FirstName = "Emma",    LastName = "Wilson",  ContactEmail = "emma.wilson@booknest.com",   PhoneNumber = "+38761100001" };
            var org2 = new Organizer { FirstName = "James",   LastName = "Carter",  ContactEmail = "james.carter@booknest.com",  PhoneNumber = "+38762200002" };
            var org3 = new Organizer { FirstName = "Sarah",   LastName = "Johnson", ContactEmail = "sarah.johnson@booknest.com", PhoneNumber = "+38763300003" };
            var org4 = new Organizer { FirstName = "Michael", LastName = "Brown",   ContactEmail = "michael.brown@booknest.com", PhoneNumber = "+38761400004" };
            var org5 = new Organizer { FirstName = "Laura",   LastName = "Davis",   ContactEmail = "laura.davis@booknest.com",   PhoneNumber = "+38762500005" };
            var org6 = new Organizer { FirstName = "Robert",  LastName = "Taylor",  ContactEmail = "robert.taylor@booknest.com", PhoneNumber = "+38763600006" };
            var org7 = new Organizer { FirstName = "Emily",   LastName = "Moore",   ContactEmail = "emily.moore@booknest.com",   PhoneNumber = "+38761700007" };
            var org8 = new Organizer { FirstName = "Daniel",  LastName = "White",   ContactEmail = "daniel.white@booknest.com",  PhoneNumber = "+38762800008" };
            var org9 = new Organizer { FirstName = "Olivia",  LastName = "Harris",  ContactEmail = "olivia.harris@booknest.com", PhoneNumber = "+38763900009" };
            context.Organizers.AddRange(org1, org2, org3, org4, org5, org6, org7, org8, org9);
            await context.SaveChangesAsync(ct);

            var userAdmin = new User
            {
                FirstName = "Desktop", LastName = "Admin",
                EmailAddress = "admin@booknest.com",
                Username = "desktop",
                PasswordHash = passwordHasher.Hash("test"),
                DateOfBirth = new DateTime(1985, 6, 15),
                Address = "Titova 1",
                CityId = citySarajevo.Id,
                CountryId = countryBiH.Id,
                PhoneNumber = "+38761000001"
            };

            var userMobile = new User
            {
                FirstName = "Mobile", LastName = "User",
                EmailAddress = "mobile@booknest.com",
                Username = "mobile",
                PasswordHash = passwordHasher.Hash("test"),
                DateOfBirth = new DateTime(1995, 3, 10),
                Address = "Ferhadija 12",
                CityId = citySarajevo.Id,
                CountryId = countryBiH.Id,
                ImageUrl = "https://booknestimages.blob.core.windows.net/user-images/user_profile.png"
            };

            var user2 = new User
            {
                FirstName = "User", LastName = "Two",
                EmailAddress = "user2@booknest.com",
                Username = "user2",
                PasswordHash = passwordHasher.Hash("test"),
                DateOfBirth = new DateTime(1992, 7, 22),
                Address = "Knez Mihailova 5",
                CityId = cityBelgrade.Id,
                CountryId = countrySerbia.Id,
                ImageUrl = "https://booknestimages.blob.core.windows.net/user-images/user_profile.png"
            };

            var user3 = new User
            {
                FirstName = "User", LastName = "Three",
                EmailAddress = "user3@booknest.com",
                Username = "user3",
                PasswordHash = passwordHasher.Hash("test"),
                DateOfBirth = new DateTime(1998, 11, 5),
                Address = "Ilica 10",
                CityId = cityZagreb.Id,
                CountryId = countryCroatia.Id,
                ImageUrl = "https://booknestimages.blob.core.windows.net/user-images/user_profile.png"
            };

            context.Users.AddRange(userAdmin, userMobile, user2, user3);
            await context.SaveChangesAsync(ct);

            context.UserRoles.AddRange(
                new UserRole { UserId = userAdmin.Id,  RoleId = 1 },
                new UserRole { UserId = userMobile.Id, RoleId = 2 },
                new UserRole { UserId = user2.Id,      RoleId = 2 },
                new UserRole { UserId = user3.Id,      RoleId = 2 }
            );
            await context.SaveChangesAsync(ct);

            context.Carts.AddRange(
                new Cart { UserId = userAdmin.Id  },
                new Cart { UserId = userMobile.Id },
                new Cart { UserId = user2.Id      },
                new Cart { UserId = user3.Id      }
            );
            await context.SaveChangesAsync(ct);

            var bookFinalGamebit = new Book
            {
                Title = "The Final Gambit",
                AuthorId = authorBarnes.Id,
                Description = "In the final book of the Inheritance Games trilogy, Avery Grambs has just weeks until she inherits billions—but trouble arrives in the form of a visitor who needs her help, drawing her and the Hawthorne brothers into a dangerous game against an unknown and powerful player.",
                PublicationDate = new DateTime(2022, 8, 30),
                CoverImageUrl = "https://booknestimages.blob.core.windows.net/book-covers/adventure/Adventure_The_Final_Gambit.png",
                PageCount = 400, Price = 22.99m, Stock = 30
            };

            var bookHawthorneLegacy = new Book
            {
                Title = "The Hawthorne Legacy",
                AuthorId = authorBarnes.Id,
                Description = "The thrilling sequel to The Inheritance Games. Heiress Avery Grambs must uncover why billionaire Tobias Hawthorne left his entire fortune to her—while navigating intrigue, romance, and danger from adversaries who will stop at nothing to see her out of the picture.",
                PublicationDate = new DateTime(2021, 9, 7),
                CoverImageUrl = "https://booknestimages.blob.core.windows.net/book-covers/adventure/Adventure_The_Hawthorne_Legacy.png",
                PageCount = 380, Price = 21.99m, Stock = 25
            };

            var bookHousemaidSecret = new Book
            {
                Title = "The Housemaid's Secret",
                AuthorId = authorMcFadden.Id,
                Description = "A psychological thriller by Frieda McFadden. Working as a housekeeper in a stunning penthouse, she has a terrible feeling about the woman behind closed doors—but she can't risk losing this job. When the door finally opens, what she sees inside changes everything.",
                PublicationDate = new DateTime(2023, 2, 15),
                CoverImageUrl = "https://booknestimages.blob.core.windows.net/book-covers/adventure/Adventure_The_Housemaid's_Secret.png",
                PageCount = 311, Price = 19.99m, Stock = 40
            };

            var bookOnMorrison = new Book
            {
                Title = "On Morrison",
                AuthorId = authorSerpell.Id,
                Description = "An illuminating exploration of the work of Toni Morrison by novelist and Harvard professor Namwali Serpell. A journey through Morrison's entire oeuvre—fiction, criticism, dramatic works, and poetry—with contextual guidance, archival discoveries, and original close readings.",
                PublicationDate = new DateTime(2026, 2, 17),
                CoverImageUrl = "https://booknestimages.blob.core.windows.net/book-covers/biography/Biography_On_Morrison.png",
                PageCount = 384, Price = 24.99m, Stock = 20
            };

            var bookMixedMarriage = new Book
            {
                Title = "The Mixed Marriage Project",
                AuthorId = authorRoberts.Id,
                Description = "A spirited memoir of love, race, and family by Dorothy E. Roberts. Growing up in segregated 1960s Chicago in an interracial home, Roberts reflects on her father's lifelong research into Black-white marriages—and the discovery that changes everything she thought she knew.",
                PublicationDate = new DateTime(2026, 2, 10),
                CoverImageUrl = "https://booknestimages.blob.core.windows.net/book-covers/biography/Biography_The_Mixed_Marriage_Project.png",
                PageCount = 320, Price = 23.99m, Stock = 15
            };

            var bookWeTheWomen = new Book
            {
                Title = "We the Women",
                AuthorId = authorBrower.Id,
                Description = "A vivid portrait of unsung American women from 1776 to today who changed the course of history. Kate Andersen Brower presents a fresh look at American history through the eyes of fierce women who demanded the country live up to the promises of the Declaration of Independence.",
                PublicationDate = new DateTime(2026, 2, 24),
                CoverImageUrl = "https://booknestimages.blob.core.windows.net/book-covers/biography/Biography_We_The_Women.png",
                PageCount = 401, Price = 25.99m, Stock = 18
            };

            var bookAndNowBackToYou = new Book
            {
                Title = "And Now, Back to You",
                AuthorId = authorBorison.Id,
                Description = "Two competing meteorologists are forced to find common ground in this opposites-attract romance inspired by When Harry Met Sally. When Jackson and Delilah are partnered against their will to cover the snowstorm of the century, an undiscovered chemistry burns beneath their clashes.",
                PublicationDate = new DateTime(2026, 2, 24),
                CoverImageUrl = "https://booknestimages.blob.core.windows.net/book-covers/romance/Romace_And_Now_Back_To_You.png",
                PageCount = 464, Price = 20.99m, Stock = 35
            };

            var bookSunAndStarmaker = new Book
            {
                Title = "The Sun and the Starmaker",
                AuthorId = authorGriffin.Id,
                Description = "From the New York Times bestselling author of The Nature of Witches comes a whimsical romantic fantasy. Aurora Finch never imagined she'd meet the mysterious Starmaker—until a fateful encounter in the frostbitten woods changes everything.",
                PublicationDate = new DateTime(2026, 2, 17),
                CoverImageUrl = "https://booknestimages.blob.core.windows.net/book-covers/romance/Romance_The_Sun_And_The_Starmaker.png",
                PageCount = 448, Price = 21.99m, Stock = 30
            };

            var bookRacingHearts = new Book
            {
                Title = "Racing Hearts",
                AuthorId = authorAdams.Id,
                Description = "When a competitive rower's losing streak threatens her Olympic dreams, she must train for the summer with a new hometown coach in this irresistible opposites-attract romance. Kath must choose between her perfect plan and finding out if letting go is the key to winning.",
                PublicationDate = new DateTime(2026, 2, 10),
                CoverImageUrl = "https://booknestimages.blob.core.windows.net/book-covers/romance/Romance_Racing_Hearts.png",
                PageCount = 352, Price = 18.99m, Stock = 28
            };

            context.Books.AddRange(
                bookFinalGamebit, bookHawthorneLegacy, bookHousemaidSecret,
                bookOnMorrison, bookMixedMarriage, bookWeTheWomen,
                bookAndNowBackToYou, bookSunAndStarmaker, bookRacingHearts);
            await context.SaveChangesAsync(ct);

            context.BookCategories.AddRange(
                new BookCategory { BookId = bookFinalGamebit.Id,    CategoryId = catAdventure.Id },
                new BookCategory { BookId = bookHawthorneLegacy.Id, CategoryId = catAdventure.Id },
                new BookCategory { BookId = bookHousemaidSecret.Id, CategoryId = catAdventure.Id },
                new BookCategory { BookId = bookOnMorrison.Id,      CategoryId = catBiography.Id },
                new BookCategory { BookId = bookMixedMarriage.Id,   CategoryId = catBiography.Id },
                new BookCategory { BookId = bookWeTheWomen.Id,      CategoryId = catBiography.Id },
                new BookCategory { BookId = bookAndNowBackToYou.Id, CategoryId = catRomance.Id   },
                new BookCategory { BookId = bookSunAndStarmaker.Id, CategoryId = catRomance.Id   },
                new BookCategory { BookId = bookRacingHearts.Id,    CategoryId = catRomance.Id   }
            );
            await context.SaveChangesAsync(ct);

            var eventMysteryReadersCircle = new Event
            {
                Name = "Mystery Readers Circle",
                Description = "Join fellow mystery lovers for an evening of discussion, theory, and suspense. This month we explore the best whodunits of the year over drinks and great conversation.",
                EventCategoryId = evCatBookClub.Id, OrganizerId = org1.Id,
                EventDate = new DateTime(2026, 6, 19), EventTime = new TimeSpan(18, 0, 0),
                EventTypeId = EventTypes.InPerson,
                Address = "Vijećnica, Obala Kulina bana 4",
                CityId = citySarajevo.Id, CountryId = countryBiH.Id,
                TicketPrice = 10.00m, Capacity = 10, IsActive = true, ReservedSeats = 0,
                ImageUrl = "https://booknestimages.blob.core.windows.net/event-images/bookClub/BookClub_Mystery_Readers_Circle.png"
            };

            var eventSciFiBookClub = new Event
            {
                Name = "SciFi Book Club",
                Description = "An online gathering for science fiction enthusiasts to discuss the latest and greatest in sci-fi literature. This session focuses on space opera and dystopian fiction.",
                EventCategoryId = evCatBookClub.Id, OrganizerId = org2.Id,
                EventDate = new DateTime(2026, 6, 22), EventTime = new TimeSpan(19, 0, 0),
                EventTypeId = EventTypes.Online,
                TicketPrice = 0.00m, Capacity = 15, IsActive = true, ReservedSeats = 0,
                ImageUrl = "https://booknestimages.blob.core.windows.net/event-images/bookClub/BookClub_SciFi_Book_Club.png"
            };

            var eventGreatGatsby = new Event
            {
                Name = "The Great Gatsby Reading Club",
                Description = "Revisit the jazz age and the American dream in this intimate reading club session dedicated to F. Scott Fitzgerald's timeless classic. Come dressed in your best 1920s style!",
                EventCategoryId = evCatBookClub.Id, OrganizerId = org3.Id,
                EventDate = new DateTime(2026, 6, 25), EventTime = new TimeSpan(17, 0, 0),
                EventTypeId = EventTypes.InPerson,
                Address = "Stari Most, Mostar",
                CityId = cityMostar.Id, CountryId = countryBiH.Id,
                TicketPrice = 8.00m, Capacity = 10, IsActive = true, ReservedSeats = 0,
                ImageUrl = "https://booknestimages.blob.core.windows.net/event-images/bookClub/BookClub_The_Great_Gatsby.png"
            };

            var eventCleopatra = new Event
            {
                Name = "Cleopatra Book Promotion",
                Description = "An exclusive promotion event celebrating the launch of a stunning new biography of Cleopatra. Meet the author, hear behind-the-scenes stories, and get your copy signed.",
                EventCategoryId = evCatPromotions.Id, OrganizerId = org4.Id,
                EventDate = new DateTime(2026, 6, 28), EventTime = new TimeSpan(11, 0, 0),
                EventTypeId = EventTypes.InPerson,
                Address = "Trg bana Josipa Jelačića 1",
                CityId = cityZagreb.Id, CountryId = countryCroatia.Id,
                TicketPrice = 0.00m, Capacity = 20, IsActive = true, ReservedSeats = 0,
                ImageUrl = "https://booknestimages.blob.core.windows.net/event-images/bookPromotions/BookPromotions_Cleopatra.png"
            };

            var eventFourthPrincess = new Event
            {
                Name = "The Fourth Princess Launch",
                Description = "Join us online for the official launch of The Fourth Princess, a gripping royal thriller. The author will discuss the inspiration behind the story, followed by a live Q&A session.",
                EventCategoryId = evCatPromotions.Id, OrganizerId = org5.Id,
                EventDate = new DateTime(2026, 7, 1), EventTime = new TimeSpan(16, 0, 0),
                EventTypeId = EventTypes.Online,
                TicketPrice = 12.00m, Capacity = 15, IsActive = true, ReservedSeats = 0,
                ImageUrl = "https://booknestimages.blob.core.windows.net/event-images/bookPromotions/BookPromotions_The_Fourth_Princess.png"
            };

            var eventWeavingshaw = new Event
            {
                Name = "Weavingshaw Book Promotion",
                Description = "An online celebration for the release of Weavingshaw, a debut fantasy novel set in a world of woven magic and ancient secrets. Don't miss the author interview and giveaway!",
                EventCategoryId = evCatPromotions.Id, OrganizerId = org6.Id,
                EventDate = new DateTime(2026, 7, 4), EventTime = new TimeSpan(14, 0, 0),
                EventTypeId = EventTypes.Online,
                TicketPrice = 0.00m, Capacity = 15, IsActive = true, ReservedSeats = 0,
                ImageUrl = "https://booknestimages.blob.core.windows.net/event-images/bookPromotions/BookPromotions_Weavingshaw.png"
            };

            var eventCozyCorner = new Event
            {
                Name = "Cozy Corner Afternoon",
                Description = "A relaxed afternoon of reading in a warm and welcoming space. Bring your current read, a blanket, and enjoy hot drinks in great company. Perfect for unwinding after a long week.",
                EventCategoryId = evCatReadAndRelax.Id, OrganizerId = org7.Id,
                EventDate = new DateTime(2026, 7, 7), EventTime = new TimeSpan(15, 0, 0),
                EventTypeId = EventTypes.InPerson,
                Address = "Knez Mihailova 5",
                CityId = cityBelgrade.Id, CountryId = countrySerbia.Id,
                TicketPrice = 5.00m, Capacity = 10, IsActive = true, ReservedSeats = 0,
                ImageUrl = "https://booknestimages.blob.core.windows.net/event-images/read&Relax/Read&Relax_Cozy_Corner_Afternoon.png"
            };

            var eventReadByRiver = new Event
            {
                Name = "Read By The River",
                Description = "Enjoy a peaceful afternoon of reading beside the river. Bring your favourite book and settle in for a few hours of quiet reading surrounded by nature and like-minded book lovers.",
                EventCategoryId = evCatReadAndRelax.Id, OrganizerId = org8.Id,
                EventDate = new DateTime(2026, 7, 10), EventTime = new TimeSpan(14, 0, 0),
                EventTypeId = EventTypes.InPerson,
                Address = "Obala Kulina bana 2",
                CityId = citySarajevo.Id, CountryId = countryBiH.Id,
                TicketPrice = 0.00m, Capacity = 15, IsActive = true, ReservedSeats = 0,
                ImageUrl = "https://booknestimages.blob.core.windows.net/event-images/read&Relax/Read&Relax_Read_By_The_River.png"
            };

            var eventSundayMorningRead = new Event
            {
                Name = "Sunday Morning Read",
                Description = "Start your Sunday right with a virtual read-along session. Join readers from all over for a slow, mindful morning of reading, sharing thoughts, and enjoying your morning coffee.",
                EventCategoryId = evCatReadAndRelax.Id, OrganizerId = org9.Id,
                EventDate = new DateTime(2026, 7, 13), EventTime = new TimeSpan(10, 0, 0),
                EventTypeId = EventTypes.Online,
                TicketPrice = 7.00m, Capacity = 20, IsActive = true, ReservedSeats = 0,
                ImageUrl = "https://booknestimages.blob.core.windows.net/event-images/read&Relax/Read&Relax_Sunday_Morning_Read.png"
            };

            context.Events.AddRange(
                eventMysteryReadersCircle, eventSciFiBookClub, eventGreatGatsby,
                eventCleopatra, eventFourthPrincess, eventWeavingshaw,
                eventCozyCorner, eventReadByRiver, eventSundayMorningRead);
            await context.SaveChangesAsync(ct);

            context.Favorites.AddRange(
                new Favorite { UserId = userMobile.Id, BookId = bookHousemaidSecret.Id },
                new Favorite { UserId = userMobile.Id, BookId = bookRacingHearts.Id    },
                new Favorite { UserId = userMobile.Id, BookId = bookFinalGamebit.Id    },
                new Favorite { UserId = user2.Id,      BookId = bookOnMorrison.Id      },
                new Favorite { UserId = user2.Id,      BookId = bookAndNowBackToYou.Id },
                new Favorite { UserId = user3.Id,      BookId = bookSunAndStarmaker.Id },
                new Favorite { UserId = user3.Id,      BookId = bookWeTheWomen.Id      }
            );
            await context.SaveChangesAsync(ct);

            context.TBRLists.AddRange(
                new TBRList { UserId = userMobile.Id, BookId = bookHawthorneLegacy.Id, ReadingStatusId = ReadingStatuses.Read     },
                new TBRList { UserId = userMobile.Id, BookId = bookAndNowBackToYou.Id, ReadingStatusId = ReadingStatuses.Reading  },
                new TBRList { UserId = userMobile.Id, BookId = bookMixedMarriage.Id,   ReadingStatusId = ReadingStatuses.ToBeRead },
                new TBRList { UserId = user2.Id,      BookId = bookOnMorrison.Id,      ReadingStatusId = ReadingStatuses.Reading  },
                new TBRList { UserId = user2.Id,      BookId = bookWeTheWomen.Id,      ReadingStatusId = ReadingStatuses.ToBeRead },
                new TBRList { UserId = user3.Id,      BookId = bookSunAndStarmaker.Id, ReadingStatusId = ReadingStatuses.Read     },
                new TBRList { UserId = user3.Id,      BookId = bookRacingHearts.Id,    ReadingStatusId = ReadingStatuses.Reading  }
            );
            await context.SaveChangesAsync(ct);

            var ship1 = new Shipping { Address = "Ferhadija 12",     CityId = citySarajevo.Id, CountryId = countryBiH.Id,     PostalCode = "71000", ShippedDate = new DateTime(2026, 3, 5)  };
            var ship2 = new Shipping { Address = "Knez Mihailova 5", CityId = cityBelgrade.Id, CountryId = countrySerbia.Id,  PostalCode = "11000", ShippedDate = new DateTime(2026, 3, 20) };
            var ship3 = new Shipping { Address = "Ilica 10",         CityId = cityZagreb.Id,   CountryId = countryCroatia.Id, PostalCode = "10000"  };
            var ship4 = new Shipping { Address = "Ferhadija 12",     CityId = citySarajevo.Id, CountryId = countryBiH.Id,     PostalCode = "71000"  };
            context.Shippings.AddRange(ship1, ship2, ship3, ship4);
            await context.SaveChangesAsync(ct);

            var order1 = new Order { UserId = userMobile.Id, OrderDate = new DateTime(2026, 3, 1),  ShippedDate = new DateTime(2026, 3, 5),  OrderStatusId = OrderStatuses.Delivered, TotalPrice = 41.98m, ShippingId = ship1.Id };
            var order2 = new Order { UserId = user2.Id,      OrderDate = new DateTime(2026, 3, 15), ShippedDate = new DateTime(2026, 3, 20), OrderStatusId = OrderStatuses.Shipped,   TotalPrice = 44.98m, ShippingId = ship2.Id };
            var order3 = new Order { UserId = user3.Id,      OrderDate = new DateTime(2026, 4, 10),                                          OrderStatusId = OrderStatuses.Pending,   TotalPrice = 42.98m, ShippingId = ship3.Id };
            var order4 = new Order { UserId = userMobile.Id, OrderDate = new DateTime(2026, 5, 1),                                           OrderStatusId = OrderStatuses.Pending,   TotalPrice = 19.99m, ShippingId = ship4.Id };
            context.Orders.AddRange(order1, order2, order3, order4);
            await context.SaveChangesAsync(ct);

            context.OrderItems.AddRange(
                new OrderItem { OrderId = order1.Id, BookId = bookHousemaidSecret.Id, Quantity = 1, Price = 19.99m },
                new OrderItem { OrderId = order1.Id, BookId = bookRacingHearts.Id,    Quantity = 1, Price = 18.99m },
                new OrderItem { OrderId = order2.Id, BookId = bookOnMorrison.Id,      Quantity = 1, Price = 24.99m },
                new OrderItem { OrderId = order2.Id, BookId = bookWeTheWomen.Id,      Quantity = 1, Price = 25.99m },
                new OrderItem { OrderId = order3.Id, BookId = bookSunAndStarmaker.Id, Quantity = 1, Price = 21.99m },
                new OrderItem { OrderId = order3.Id, BookId = bookAndNowBackToYou.Id, Quantity = 1, Price = 20.99m },
                new OrderItem { OrderId = order4.Id, BookId = bookHousemaidSecret.Id, Quantity = 1, Price = 19.99m }
            );
            await context.SaveChangesAsync(ct);

            context.Payments.AddRange(
                new Payment { UserId = userMobile.Id, OrderId = order1.Id, PaymentMethodId = PaymentMethods.Card,            Amount = 41.98m, PaymentDate = new DateTime(2026, 3, 1),  IsSuccessful = true, TransactionId = "txn_seed_001" },
                new Payment { UserId = user2.Id,      OrderId = order2.Id, PaymentMethodId = PaymentMethods.CashOnDelivery,   Amount = 44.98m, PaymentDate = new DateTime(2026, 3, 20), IsSuccessful = true, TransactionId = "txn_seed_002" }
            );
            await context.SaveChangesAsync(ct);

            var res1 = new EventReservation
            {
                UserId = userMobile.Id, EventId = eventMysteryReadersCircle.Id,
                EventDateTime = new DateTime(2026, 6, 19, 18, 0, 0),
                ReservationDate = new DateTime(2026, 5, 20),
                Quantity = 1, TotalPrice = 10.00m,
                ReservationStatusId = ReservationStatuses.Confirmed,
                TicketQRCodeLink = "https://api.qrserver.com/v1/create-qr-code/?data=RES-BOOKNEST-001&size=200x200"
            };

            var res2 = new EventReservation
            {
                UserId = user2.Id, EventId = eventSciFiBookClub.Id,
                EventDateTime = new DateTime(2026, 6, 22, 19, 0, 0),
                ReservationDate = new DateTime(2026, 5, 22),
                Quantity = 1, TotalPrice = 0.00m,
                ReservationStatusId = ReservationStatuses.Confirmed,
                TicketQRCodeLink = "https://api.qrserver.com/v1/create-qr-code/?data=RES-BOOKNEST-002&size=200x200"
            };

            var res3 = new EventReservation
            {
                UserId = user3.Id, EventId = eventCleopatra.Id,
                EventDateTime = new DateTime(2026, 6, 28, 11, 0, 0),
                ReservationDate = new DateTime(2026, 5, 25),
                Quantity = 2, TotalPrice = 0.00m,
                ReservationStatusId = ReservationStatuses.Pending,
                TicketQRCodeLink = "https://api.qrserver.com/v1/create-qr-code/?data=RES-BOOKNEST-003&size=200x200"
            };

            var res4 = new EventReservation
            {
                UserId = user2.Id, EventId = eventMysteryReadersCircle.Id,
                EventDateTime = new DateTime(2026, 6, 19, 18, 0, 0),
                ReservationDate = new DateTime(2026, 5, 21),
                Quantity = 1, TotalPrice = 10.00m,
                ReservationStatusId = ReservationStatuses.Confirmed,
                TicketQRCodeLink = "https://api.qrserver.com/v1/create-qr-code/?data=RES-BOOKNEST-004&size=200x200"
            };

            var res5 = new EventReservation
            {
                UserId = user3.Id, EventId = eventMysteryReadersCircle.Id,
                EventDateTime = new DateTime(2026, 6, 19, 18, 0, 0),
                ReservationDate = new DateTime(2026, 5, 23),
                Quantity = 1, TotalPrice = 10.00m,
                ReservationStatusId = ReservationStatuses.Confirmed,
                TicketQRCodeLink = "https://api.qrserver.com/v1/create-qr-code/?data=RES-BOOKNEST-005&size=200x200"
            };

            context.EventReservations.AddRange(res1, res2, res3, res4, res5);
            await context.SaveChangesAsync(ct);

            eventMysteryReadersCircle.ReservedSeats += res1.Quantity + res4.Quantity + res5.Quantity;
            eventSciFiBookClub.ReservedSeats += res2.Quantity;
            eventCleopatra.ReservedSeats += res3.Quantity;
            await context.SaveChangesAsync(ct);

            context.Payments.AddRange(
                new Payment { UserId = userMobile.Id, EventReservationId = res1.Id, PaymentMethodId = PaymentMethods.Card,           Amount = 10.00m, PaymentDate = new DateTime(2026, 5, 20), IsSuccessful = true, TransactionId = "txn_seed_003" },
                new Payment { UserId = user2.Id,      EventReservationId = res2.Id, PaymentMethodId = PaymentMethods.CashOnDelivery,  Amount = 0.00m,  PaymentDate = new DateTime(2026, 5, 22), IsSuccessful = true, TransactionId = "txn_seed_004" },
                new Payment { UserId = user3.Id,      EventReservationId = res3.Id, PaymentMethodId = PaymentMethods.CashOnDelivery,  Amount = 0.00m,  PaymentDate = new DateTime(2026, 5, 25), IsSuccessful = true, TransactionId = "txn_seed_005" },
                new Payment { UserId = user2.Id,      EventReservationId = res4.Id, PaymentMethodId = PaymentMethods.Card,           Amount = 10.00m, PaymentDate = new DateTime(2026, 5, 21), IsSuccessful = true, TransactionId = "txn_seed_006" },
                new Payment { UserId = user3.Id,      EventReservationId = res5.Id, PaymentMethodId = PaymentMethods.Card,           Amount = 10.00m, PaymentDate = new DateTime(2026, 5, 23), IsSuccessful = true, TransactionId = "txn_seed_007" }
            );
            await context.SaveChangesAsync(ct);

            context.Reviews.AddRange(
                new Review { UserId = userMobile.Id, BookId = bookHousemaidSecret.Id, Rating = 5, Comment = "A gripping thriller I couldn't put down. Frieda McFadden is a master of suspense!",      CreatedAt = new DateTime(2026, 3, 10) },
                new Review { UserId = userMobile.Id, BookId = bookRacingHearts.Id,    Rating = 4, Comment = "Sweet and fun romance with great sports energy. Loved the chemistry between the leads.", CreatedAt = new DateTime(2026, 3, 12) },
                new Review { UserId = user2.Id,      BookId = bookOnMorrison.Id,      Rating = 5, Comment = "A brilliant and accessible exploration of Toni Morrison's genius. Highly recommended.",   CreatedAt = new DateTime(2026, 4, 1)  },
                new Review { UserId = user2.Id,      BookId = bookAndNowBackToYou.Id,  Rating = 4, Comment = "Charming opposites-attract story with snappy dialogue and a lovely slow burn.",          CreatedAt = new DateTime(2026, 4, 5)  },
                new Review { UserId = user3.Id,      BookId = bookSunAndStarmaker.Id, Rating = 5, Comment = "Absolutely magical! The world-building is stunning and the romance is swoon-worthy.",     CreatedAt = new DateTime(2026, 4, 20) },
                new Review { UserId = user3.Id,      BookId = bookWeTheWomen.Id,      Rating = 4, Comment = "Eye-opening and inspiring. A must-read for anyone interested in women's history.",        CreatedAt = new DateTime(2026, 4, 22) }
            );
            await context.SaveChangesAsync(ct);
        }

        private static async Task InsertWithIdentityAsync(
            BookNestDbContext context,
            string tableName,
            Func<Task> insertAction)
        {
            await context.Database.OpenConnectionAsync();

            try
            {
                await context.Database.ExecuteSqlRawAsync($"SET IDENTITY_INSERT {tableName} ON");

                try
                {
                    await insertAction();
                }
                finally
                {
                    await context.Database.ExecuteSqlRawAsync($"SET IDENTITY_INSERT {tableName} OFF");
                }
            }
            finally
            {
                await context.Database.CloseConnectionAsync();
            }
        }
    }
}
