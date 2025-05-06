
# 🎉 Elastik Event App

A full-featured Event Management Application built using **Flutter** for the frontend and **ASP.NET MVC** with **MSSQL** for the backend. The app supports event creation, user registration, admin management, participant availability, commenting, notifications, and more — all with clean architecture and SOLID principles.

---

## 📱 Features

### 👥 User Portal (Flutter)
- 🔐 Login and Registration
- 📅 Browse and register for events
- 📌 View and update availability
- 💬 Comment on events

### 🛠️ Admin Portal (ASP.NET MVC)
- ✅ Admin login
- 🧾 Create, update, delete events
- 👤 Manage users and participants
- 📊 View charts and analytics
- ⚙️ Customize registration fields

---

## 💻 Tech Stack

| Layer       | Technology               |
|-------------|---------------------------|
| Frontend    | Flutter (Dart)            |
| Backend     | ASP.NET MVC (C#)          |
| Database    | MSSQL (SSMS)              |
| ORM         | Entity Framework          |
| Auth        | JWT / ASP.NET Identity    |
| PDF Export  | iTextSharp / Syncfusion   |
| Charts      | Charts in Flutter / MVC   |

---

## 🚀 Setup Instructions

### 📦 Backend (ASP.NET MVC)
1. Clone the repo:
   ```bash
   git clone https://github.com/ElsatikEventsApp/elastik-event-backend.git
   cd elastik-event-backend
   ```
2. Set up the database in SQL Server Management Studio.
3. Configure the connection string in `appsettings.json`.
4. Run migrations (if using EF):
   ```bash
   Update-Database
   ```
5. Build and run the server:
   ```bash
   dotnet run
   ```

### 📱 Frontend (Flutter)
1. Clone the frontend repo:
   ```bash
   git clone https://github.com/ElsatikEventsApp/elastik-event-app.git
   cd elastik-event-app
   ```
2. Install dependencies:
   ```bash
   flutter pub get
   ```
3. Update `baseUrl` in the API service to match your backend.
4. Run the app:
   ```bash
   flutter run
   ```

---

## 🧪 Testing

- **Backend**: Use Postman to test endpoints (`/api/auth`, `/api/events`, etc.).
- **Frontend**: Manual testing using device/emulator.

---

## 🧼 Clean Code Practices

- ✅ Follows SOLID principles
- ✅ Clean architecture: Separation of concerns across layers
- ✅ Reusable services and UI components
- ✅ Exception handling and validation

---

## 🙌 Contributors

- **Pranav Bharti** - [LinkedIn](https://www.linkedin.com/in/pranav-bharti)

---

## 📄 License

This project is licensed under the MIT License.
