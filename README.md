# BookNest

A platform for discovering books and literary events, with personalized recommendations.

Developed as part of Software Development 2 course (Razvoj Softvera II).

---

## 📖 About

BookNest is a comprehensive platform designed for book lovers who want to browse and purchase books, discover literary events, and receive personalized recommendations based on their reading habits.

Built with an ASP.NET Core backend and Flutter frontend (supporting both desktop and mobile platforms), the application provides a complete system for managing a digital bookstore and event reservation system. Administrators manage the platform through a dedicated desktop application, while users interact through a mobile application.

The platform integrates Stripe for secure payment processing, RabbitMQ for asynchronous messaging, Azure Blob Storage for image management, SignalR for real-time notifications, and Docker for containerized deployment.

---

## ✨ Features

### 📱 Mobile Application — User Features

**Recommendations**
- **Top picks for you** — Collaborative filtering book recommendations based on similar users' activity
- **Maybe you are interested in** — Collaborative filtering event recommendations based on similar users' reservations
- **Recommended for you** — Content-based book recommendations by preferred book categories
- **Based on your reservations** — Content-based event recommendations by preferred event categories

**Books**
- Browse and search books by category
- Leave reviews and comments on books
- Add books to cart, favourites, or TBR list (with statuses: Read, To Be Read, Reading)
- Checkout from cart with Stripe payment

**Events**
- Browse and search events by category
- Reserve event tickets with Stripe payment
- Receive a QR code ticket after successful payment

**Profile**
- View and edit personal profile, including profile picture
- View order history with option to cancel orders (with cancellation reason)
- View reservation history with QR code display and option to cancel reservations (with cancellation reason)
- Notification settings — choose whether to receive status notifications from administrators
- Password reset via email (Forgot password)
- Logout

**Notifications**
- Order status change notifications from administrator
- Reservation status change notifications from administrator
- Upcoming event reminders sent by administrator

---

### 🖥️ Desktop Application — Administrator Features

**User Management**
- Search, edit and delete users
- Upload and update user profile pictures

**Book Management**
- Full CRUD for books, authors and book categories
- Browse and search books by category

**Event Management**
- Full CRUD for events, organizers and event categories
- Browse and search events by category

**Order Management**
- View all orders and change order status
- Status changes trigger automatic notifications to users

**Reservation Management**
- View all reservations and change reservation status
- Status changes trigger automatic notifications to users
- Send upcoming event reminders to users

**Location Management**
- Full CRUD for cities and countries

---

### 🔔 Notification System

- **Password Reset** — email with reset code sent to user
- **Order Status** — notification when administrator changes order status
- **Reservation Status** — notification when administrator changes reservation status
- **Event Reminder** — reminder for upcoming events, sent manually by administrator

---

### 🎯 Recommendation System

For a detailed technical description of all four recommendation systems, see [`recommender-dokumentacija.md`](./recommender-dokumentacija.md).

---

### 💳 Payment Integration

- **Stripe Processing** — Secure payment handling for book purchases and event ticket reservations
- **QR Code** — Generated automatically after successful event payment as entry access

---

## 🛠️ Built With

| Technology | Purpose |
| --- | --- |
| .NET 8 | Backend Web API |
| Flutter | Cross-Platform Frontend |
| SQL Server | Database |
| Docker | Containerization |
| RabbitMQ | Message Broker |
| Stripe | Payment Processing |
| Azure Blob Storage | Image Storage |
| SignalR | Real-time Notifications |
| Entity Framework Core | ORM & Migrations |

---

## 🚀 Getting Started

### Prerequisites

- Docker Desktop installed and running
- Android Emulator (for mobile app testing)
- Windows OS (for desktop application)
- Archive extraction tool supporting password-protected `.zip` files

### Installation

#### Backend Setup

**1. Clone the Repository**

```bash
git clone https://github.com/hanahadzihusejnovic/BookNest-RS2.git
cd BookNest
```

**2. Set Up Environment Configuration**

Locate the `.env-tajne.zip` archive in the root folder and extract the `.env` file to the same location using the password provided on DLWMS.

The extracted `.env` file must be placed at:

```
BookNest/.env
```

**3. Start Backend Services**

```bash
docker compose up --build
```

Wait for all services to build and start successfully. The API will be available once all containers are healthy and the database seeder completes.

#### Frontend Setup

**Desktop Application**

1. Extract the build archive from the GitHub Release
2. Open the `Release` folder
3. Run `booknest_desktop.exe`

**Mobile Application**

1. Launch Android Emulator or connect a physical device
2. From the GitHub Release, locate `app-release.apk`
3. Uninstall any previous version of the app
4. Transfer and install the `.apk` file to the emulator or device
5. Launch BookNest from the device

---

## 🔐 Login Credentials

### Administrator Account (Desktop)

| Field | Value |
| --- | --- |
| Username | `desktop` |
| Password | `test` |

Permissions: Full platform management — users, books, events, authors, organizers, categories, orders, reservations, locations.

### User Account (Mobile)

| Field | Value |
| --- | --- |
| Username | `mobile` |
| Password | `test` |

Permissions: Book browsing and purchasing, event reservation, favourites, TBR list, reviews, profile management, notifications.

### Additional Mobile User Accounts

| Username | Password |
| --- | --- |
| `user2` | `test` |
| `user3` | `test` |

These seeded accounts support recommendation-system demonstration data.

---

## 💳 Stripe Test Payment Details

The application supports payments through Stripe integration. For testing purposes, use the following test card credentials:

| Field | Value |
| --- | --- |
| Card Number | `4242 4242 4242 4242` |
| Expiration Date | Any future date (e.g. `12/34`) |
| CVC | Any 3-digit number (e.g. `123`) |
| ZIP Code | Any valid code (e.g. `10000`) |

> ⚠️ These credentials only work in Stripe's test environment and will not process real payments.

---

## 🔧 Microservices Architecture

### RabbitMQ Message Broker

The application uses RabbitMQ as a message broker for asynchronous communication and automated email notifications between the API and the Subscriber service.

#### Benefits

- **Asynchronous Processing** — Non-blocking email operations
- **Scalability** — Handles high volumes of notifications
- **Reliability** — Message queue ensures delivery
- **Decoupling** — Separation of concerns between API and subscriber services

---

## 📁 Project Structure

```
BookNest/
│
├── 📂 BookNestBackend/
│   ├── 📂 BookNest.API/          # API layer — controllers, middleware, hubs
│   ├── 📂 BookNest.Services/     # Business logic, seeder, mapping
│   ├── 📂 BookNest.Model/        # Domain models, requests, responses
│   └── 📂 BookNest.Subscriber/   # RabbitMQ subscriber — email notifications
│   └── 📄 .dockerignore
│
├── 📂 BookNestFrontend/
│   ├── 📂 booknest_mobile/       # Flutter mobile application (Android)
│   └── 📂 booknest_desktop/      # Flutter desktop application (Windows)
│
├── 🐳 docker-compose.yml
├── 📄 .gitignore
├── 📄 recommender-dokumentacija.md
└── 📄 README.md
```

---

## 🐳 Docker Services

| Service | Description | Port |
| --- | --- | --- |
| `booknest-api` | ASP.NET Core Web API | `7110` |
| `sqlserver` | SQL Server database | `1433` |
| `rabbitmq` | RabbitMQ message broker | `5672` |
| `booknest-subscriber` | Email notification worker | — |

**RabbitMQ Management UI** is available at `http://localhost:15672`

### Docker Commands

Start all services:

```bash
docker compose up --build
```

Stop all services:

```bash
docker compose down
```

View logs:

```bash
docker compose logs -f
```

View logs for a specific service:

```bash
docker logs booknest-api --tail 100
```

---

## 🚢 GitHub Release

Build files are distributed via GitHub Releases and are not committed to the repository.

Each release contains a single ZIP archive (`fit-build-2026-05-31.zip`) with the following structure:

```
fit-build-2026-05-31.zip
├── booknest_mobile/app-release.apk
└── booknest_desktop/Release/
                        ├── booknest_desktop.exe
                        ├── data/
                        └── required DLL files

```

> The `.env` file is not included in the release. It is provided separately as `.env-tajne.zip` located in the root of the repository. The password is submitted separately on DLWMS.

---

## 🎓 Academic Context

This project was developed as a semester assignment for the Software Development 2 (Razvoj Softvera 2) course at the Faculty of Information Technologies, University of Mostar.

**Course Focus:**

- Full-stack application development
- Microservices architecture
- Containerization with Docker
- Message-driven architecture
- Payment integration
- Cross-platform development
- Recommendation systems