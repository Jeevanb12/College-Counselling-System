package com.vstand4u;

import java.io.InputStream;
import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.SQLException;
import java.util.Properties;

public class DBConnection {

    private static String dbUrl = "jdbc:mysql://localhost:3306/counselling";
    private static String dbUser = "root";
    private static String dbPass = "";

    static {
        try {
            // Load driver class
            Class.forName("com.mysql.cj.jdbc.Driver");
            
            // Attempt to load credentials from db.properties if available
            InputStream input = DBConnection.class.getClassLoader().getResourceAsStream("db.properties");
            if (input != null) {
                Properties prop = new Properties();
                prop.load(input);
                if (prop.getProperty("db.url") != null) dbUrl = prop.getProperty("db.url");
                if (prop.getProperty("db.user") != null) dbUser = prop.getProperty("db.user");
                if (prop.getProperty("db.pass") != null) dbPass = prop.getProperty("db.pass");
            } else {
                // Environment variables override
                if (System.getenv("DB_URL") != null) dbUrl = System.getenv("DB_URL");
                if (System.getenv("DB_USER") != null) dbUser = System.getenv("DB_USER");
                if (System.getenv("DB_PASS") != null) dbPass = System.getenv("DB_PASS");
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    public static Connection getConnection() throws SQLException {
        return DriverManager.getConnection(dbUrl, dbUser, dbPass);
    }
}
