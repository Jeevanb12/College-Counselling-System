# College Counselling & Admission Matching System

An interactive Java Web Application designed to assist prospective students in finding matching higher education institutions based on entrance exam scores, academic streams, and specialized course preferences.

## 🚀 Key Features

- **Student Portal**:
  - Account registration and login with stream preferences (Engineering, Medical, Arts).
  - Dynamic score entry slider tailored per stream.
  - Multi-select course filtering (e.g., CSE, ECE, MBBS, BDS, BBA, BCom).
  - Cutoff matching engine returning institutional matches based on cutoff scores, fees, district, and management type.
  - Personal college shortlisting and search history log.

- **Admin Control Center**:
  - Add and manage college inventory (cutoff scores, annual fees, district, management type).
  - View registered user analytics and profiles.

---

## 🛠️ Technology Stack

- **Backend**: Java Servlets, JSP (JavaServer Pages), JDBC
- **Database**: MySQL (`counselling` database)
- **Web Server**: Apache Tomcat v10.1
- **Build Management**: Apache Maven (`pom.xml`)
- **Frontend**: HTML5, Custom Dark-Theme CSS

---

## 🗄️ Database Setup (MySQL)

Create a MySQL database named `counselling` and initialize the required tables:

```sql
CREATE DATABASE IF NOT EXISTS counselling;
USE counselling;

-- Users table
CREATE TABLE IF NOT EXISTS users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    password VARCHAR(100) NOT NULL,
    phone VARCHAR(20),
    city VARCHAR(50),
    stream VARCHAR(50),
    role VARCHAR(20) DEFAULT 'USER'
);

-- Colleges table
CREATE TABLE IF NOT EXISTS colleges (
    id INT AUTO_INCREMENT PRIMARY KEY,
    college_name VARCHAR(150) NOT NULL,
    course VARCHAR(50) NOT NULL,
    cutoff INT NOT NULL,
    fee INT NOT NULL,
    district VARCHAR(50) NOT NULL,
    type VARCHAR(50) NOT NULL
);
```

---

## 💻 How to Run Locally

1. **Clone Repository**:
   ```bash
   git clone <your-repository-url>
   ```
2. **Import into IDE**:
   - Open Eclipse IDE / IntelliJ IDEA.
   - Import as an existing Maven Project.
3. **Configure Database Connection**:
   - Ensure MySQL is running on `localhost:3306` with username `root` and password `1234` (or update DB credentials in JSPs).
4. **Deploy to Tomcat**:
   - Add the project (`myproject`) to Apache Tomcat 10.1 Server and start the server.
   - Open your browser at `http://localhost:8080/myproject/`.

---

## 📄 License
This project is open-source and available under the MIT License.
