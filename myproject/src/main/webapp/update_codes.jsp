<%@ page import="java.sql.*, java.util.*" %>
<%@ include file="db.jsp" %>
<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<!DOCTYPE html>
<html>
<head>
    <title>Database Unique Code Fixer</title>
    <link rel="stylesheet" type="text/css" href="style.css?v=2.9">
</head>
<body>
    <div class="container wide" style="max-width:800px; margin-top:50px; text-align:left;">
        <div class="brand-title">Database <span class="brand-accent">Code Re-Indexer</span></div>
        <div class="brand-subtitle">Executing SQL UPDATE across MySQL Database Table</div>

        <%
        Connection con = null;
        try {
            con = getDBConnection();
            if(con == null) {
                out.println("<div class='alert alert-danger'>Could not connect to MySQL database! Please check db.properties</div>");
            } else {
                // Ensure college_code column exists
                try {
                    con.createStatement().executeUpdate("ALTER TABLE colleges ADD COLUMN college_code VARCHAR(30) DEFAULT 'E101'");
                } catch(Exception ex){}

                // Fetch distinct college names
                Statement stmt = con.createStatement();
                ResultSet rs = stmt.executeQuery("SELECT college_name, MIN(course) as sample_course FROM colleges GROUP BY college_name ORDER BY MIN(id) ASC");

                List<String[]> collegesList = new ArrayList<>();
                int eng = 101;
                int med = 101;
                int arts = 101;

                while(rs.next()) {
                    String name = rs.getString("college_name");
                    String course = rs.getString("sample_course");
                    if(course == null) course = "";

                    String lowerN = name.toLowerCase();
                    String lowerC = course.toLowerCase();
                    String newCode = "";

                    if(lowerN.contains("med") || lowerN.contains("health") || lowerC.contains("mbbs") || lowerC.contains("bds") || lowerC.contains("bams")) {
                        newCode = "M" + (med++);
                    } else if(lowerN.contains("arts") || lowerN.contains("com") || lowerC.contains("ba") || lowerC.contains("bcom") || lowerC.contains("bba") || lowerC.contains("bca")) {
                        newCode = "A" + (arts++);
                    } else {
                        newCode = "E" + (eng++);
                    }

                    collegesList.add(new String[]{newCode, name});
                }
                rs.close();
                stmt.close();

                // Run SQL Update
                PreparedStatement ps = con.prepareStatement("UPDATE colleges SET college_code = ? WHERE college_name = ?");
                out.println("<div class='alert alert-success'><strong>SUCCESS! Updated the following unique codes in MySQL:</strong><br><br><ul>");
                for(String[] item : collegesList) {
                    ps.setString(1, item[0]);
                    ps.setString(2, item[1]);
                    int updatedRows = ps.executeUpdate();
                    out.println("<li>Assigned Code <strong style='color:#00e5a3;'>" + item[0] + "</strong> to <strong>" + item[1] + "</strong> (" + updatedRows + " course rows updated)</li>");
                }
                out.println("</ul></div>");
                ps.close();
                con.close();
            }
        } catch(Exception e) {
            out.println("<div class='alert alert-danger'>SQL Exception: " + e.getMessage() + "</div>");
        }
        %>

        <div style="margin-top:20px; text-align:center;">
            <a href="admin.jsp" class="btn" style="width:250px;">Return to Admin Panel</a>
        </div>
    </div>
</body>
</html>
