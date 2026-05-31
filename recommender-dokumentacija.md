# BookNest - dokumentacija sistema preporuke

## 1. Opis sistema

BookNest je aplikacija za pregled i kupovinu knjiga, kao i pregled i rezervaciju književnih događaja. U okviru aplikacije implementirana su četiri sistema preporuke čiji je cilj da korisnicima predlože knjige i događaje koji odgovaraju njihovim interesima i prethodnim aktivnostima.

Sistemi preporuke olakšavaju pronalazak relevantnog sadržaja bez potrebe da korisnik ručno pregledava cjelokupnu ponudu knjiga i događaja.

## 2. Korišteni pristupi

Implementirana su dva različita pristupa preporukama:

- **User-based Collaborative Filtering** — analizira zajedničke interakcije korisnika sa sadržajem i na osnovu toga pronalazi sličan sadržaj koji korisnik još nije imao prilike vidjeti.
- **Content-based Filtering** — analizira karakteristike sadržaja (kategorije) sa kojim je korisnik prethodno imao interakciju i preporučuje sličan sadržaj iz istih kategorija.

## 3. Sistemi preporuke

### 3.1 Top picks for you — preporuke knjiga (Collaborative Filtering)

Prikazuje se na **home screenu** pod sekcijom „Top picks for you".

Algoritam koristi kupljene knjige korisnika, knjige dodane u favorite i knjige dodane na TBR listu kao osnovu za pronalazak sličnih korisnika.

Koraci:

1. Učitava sve knjige sa kojima je prijavljeni korisnik imao interakciju (kupovina, favoriti, TBR lista).
2. Pronalazi druge korisnike koji su imali interakciju sa istim knjigama (kroz narudžbe, favorite ili TBR listu).
3. Učitava knjige sa kojima su ti slični korisnici imali interakciju, a prijavljeni korisnik nije.
4. Rangira kandidate po formuli i vraća top 6 rezultata.

Formula rangiranja:

`score = (prosječna ocjena × 0.6) + (min(broj recenzija, 50) / 50 × 0.4)`

Razlog preporuke koji se prikazuje korisniku:

`Users with similar taste also liked this book, with average rating X.X/5`

---

### 3.2 Maybe you are interested in — preporuke događaja (Collaborative Filtering)

Prikazuje se na **home screenu** pod sekcijom „Maybe you are interested in".

Algoritam koristi rezervacije događaja prijavljenog korisnika kako bi pronašao slične korisnike i događaje koje oni reserviraju.

Koraci:

1. Učitava sve događaje koje je prijavljeni korisnik rezervisao.
2. Pronalazi druge korisnike koji su rezervisali iste događaje.
3. Učitava događaje koje su ti slični korisnici rezervisali, a prijavljeni korisnik nije.
4. Filtrira samo aktivne buduće događaje i sortira po blizini datuma (bliži datum = viši prioritet).
5. Vraća top 6 rezultata.

Razlog preporuke koji se prikazuje korisniku:

`Users with similar interests reserved this event, happening in X day(s).`

---

### 3.3 Recommended for you — preporuke knjiga (Content-based Filtering)

Prikazuje se na **shop screenu** pod sekcijom „Recommended for you".

Algoritam analizira kategorije knjiga sa kojima je korisnik imao interakciju i preporučuje knjige iz istih kategorija.

Koraci:

1. Učitava sve knjige sa kojima je prijavljeni korisnik imao interakciju (kupovina, favoriti, TBR lista).
2. Izvlači preferovane kategorije tih knjiga (npr. Adventure, Romance, Biography).
3. Pronalazi ostale knjige koje spadaju u te kategorije, a korisnik s njima nije imao interakciju.
4. Rangira kandidate po formuli i vraća top 6 rezultata.

Formula rangiranja:

`score = (prosječna ocjena × 0.5) + (min(broj recenzija, 50) / 50 × 0.3) + (preklapanje kategorija × 0.2)`

Razlog preporuke koji se prikazuje korisniku:

`Matches your interest in Adventure, Romance, rated X.X/5 by X reader(s).`

---

### 3.4 Based on your reservations — preporuke događaja (Content-based Filtering)

Prikazuje se na **events screenu** pod sekcijom „Based on your reservations".

Algoritam analizira kategorije događaja koje je korisnik rezervisao i preporučuje slične događaje iz istih kategorija.

Koraci:

1. Učitava sve događaje koje je prijavljeni korisnik rezervisao.
2. Izvlači preferovane kategorije tih događaja (npr. Book Club, Book Promotions, Read & Relax).
3. Pronalazi ostale aktivne buduće događaje u tim kategorijama koje korisnik nije rezervisao.
4. Sortira po blizini datuma i vraća top 6 rezultata.

Razlog preporuke koji se prikazuje korisniku:

`Matches your interest in Book Club, happening in X day(s).`

---

## 4. Interakcije korisnika

### Knjige

| Interakcija | Koristi se u |
| --- | --- |
| Kupovina knjige (narudžba) | Collaborative filtering, Content-based filtering |
| Dodavanje knjige u favorite | Collaborative filtering, Content-based filtering |
| Dodavanje knjige na TBR listu | Collaborative filtering, Content-based filtering |
| Ocjena knjige (1–5) | Faktor rangiranja u oba sistema |

### Događaji

| Interakcija | Koristi se u |
| --- | --- |
| Rezervacija događaja | Collaborative filtering, Content-based filtering |

## 5. Uslovi prikaza preporuka

Svaki sistem preporuke ima preduslov koji mora biti ispunjen kako bi se preporuke prikazale.

| Sistem preporuke | Ekran | Preduslov |
| --- | --- | --- |
| Top picks for you | Home | Korisnik mora imati bar jednu kupljenu knjigu, favorit ili TBR unos; drugi korisnici moraju imati interakcije sa istim knjigama |
| Maybe you are interested in | Home | Korisnik mora imati bar jednu rezervaciju; drugi korisnici moraju imati rezervacije za iste događaje |
| Recommended for you | Shop | Korisnik mora imati bar jednu kupljenu knjigu, favorit ili TBR unos |
| Based on your reservations | Events | Korisnik mora imati bar jednu rezervaciju |

Ako preduslov nije ispunjen, sekcija se ne prikazuje.

## 6. Tehnička implementacija

Sistemi preporuke implementirani su u servisnom sloju backend aplikacije:

`BookNestBackend/BookNest.Services/Services/BookService.cs` — preporuke knjiga

`BookNestBackend/BookNest.Services/Services/EventService.cs` — preporuke događaja

Servisi koriste Entity Framework Core za učitavanje potrebnih podataka iz baze i AutoMapper za mapiranje entiteta u response DTO objekte.

### API endpointi

| Endpoint | Opis |
| --- | --- |
| `GET /api/Book/recommended` | Collaborative filtering preporuke knjiga |
| `GET /api/Book/recommended-content` | Content-based filtering preporuke knjiga |
| `GET /api/Event/recommended` | Collaborative filtering preporuke događaja |
| `GET /api/Event/recommended-content` | Content-based filtering preporuke događaja |

Svi endpointi zahtijevaju autentifikaciju. Broj rezultata može se kontrolisati query parametrom `count` (podrazumijevana vrijednost je 6).

Podaci se klijentskim aplikacijama vraćaju kao lista `BookRecommendationResponse` ili `EventRecommendationResponse` objekata, koji sadrže informacije o knjizi ili događaju i razlog preporuke (`Reason`).
