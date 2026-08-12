<%@ page import="java.sql.*, java.io.*, java.util.*" %>
<%!
    // Helper method to dynamically load DB Connection from db.properties or environment
    public Connection getDBConnection() {
        String dbUrl = "jdbc:mysql://localhost:3306/counselling";
        String dbUser = "root";
        String dbPass = "";
        
        try {
            Class.forName("com.mysql.cj.jdbc.Driver");
            
            // Try loading from classpath or local resources
            InputStream input = Thread.currentThread().getContextClassLoader().getResourceAsStream("db.properties");
            if (input == null) {
                File f = new File("A:/Meriton/myproject/src/main/resources/db.properties");
                if (f.exists()) {
                    input = new FileInputStream(f);
                }
            }
            if (input != null) {
                Properties prop = new Properties();
                prop.load(input);
                if (prop.getProperty("db.url") != null && !prop.getProperty("db.url").trim().isEmpty()) dbUrl = prop.getProperty("db.url").trim();
                if (prop.getProperty("db.user") != null && !prop.getProperty("db.user").trim().isEmpty()) dbUser = prop.getProperty("db.user").trim();
                if (prop.getProperty("db.pass") != null) dbPass = prop.getProperty("db.pass").trim();
                input.close();
            } else {
                // Fallback default password for local environment if properties file missing
                dbPass = "1234";
            }
        } catch (Exception e) {
            dbPass = "1234";
        }
        
        try {
            return DriverManager.getConnection(dbUrl, dbUser, dbPass);
        } catch (Exception e) {
            try {
                return DriverManager.getConnection("jdbc:mysql://localhost:3306/counselling", "root", "1234");
            } catch (Exception ex) {
                return null;
            }
        }
    }
%>
