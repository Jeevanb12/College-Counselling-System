<%@ page import="java.sql.*" %>
<%@ include file="db.jsp" %>
<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<!DOCTYPE html>
<html>
<head>
    <title>Sign In - Counselling System</title>
    <link rel="stylesheet" type="text/css" href="style.css?v=2.0">
</head>
<body>
    <div class="container">
        <div class="brand-title">College<span class="brand-accent">Counselling</span></div>
        <div class="brand-subtitle">Admission Matching Engine</div>
        
        <div class="tab-container">
            <a href="login.jsp" class="tab active">Sign in</a>
            <a href="register.jsp" class="tab">Sign up</a>
        </div>
        
        <%
        String redirectTarget = null;
        int authenticatedId = 0;
        String authenticatedName = null;
        String authenticatedRole = null;

        if(request.getParameter("email") != null) {
            try {
                Connection con = getDBConnection();
                PreparedStatement ps = con.prepareStatement("SELECT * FROM users WHERE email=? AND password=?");
                ps.setString(1, request.getParameter("email"));
                ps.setString(2, request.getParameter("password"));
                ResultSet rs = ps.executeQuery();
                
                if(rs.next()) {
                    authenticatedRole = rs.getString("role");
                    authenticatedName = rs.getString("name");
                    authenticatedId = rs.getInt("id");

                    // Store unique per-user session keys for multi-tab support!
                    session.setAttribute("user_" + authenticatedId, authenticatedName);
                    session.setAttribute("role_" + authenticatedId, authenticatedRole);
                    session.setAttribute("latest_user_id", authenticatedId);
                    session.setAttribute("latest_user_name", authenticatedName);
                    session.setAttribute("latest_role", authenticatedRole);

                    if("ADMIN".equals(authenticatedRole)) {
                        session.setAttribute("admin_user", authenticatedName);
                        session.setAttribute("admin_user_id", authenticatedId);
                        session.setAttribute("admin_role", "ADMIN");
                        redirectTarget = "admin.jsp?uid=" + authenticatedId;
                    } else {
                        session.setAttribute("student_user", authenticatedName);
                        session.setAttribute("student_user_id", authenticatedId);
                        session.setAttribute("user", authenticatedName);
                        session.setAttribute("user_id", authenticatedId);
                        session.setAttribute("role", "USER");
                        redirectTarget = "dashboard.jsp?uid=" + authenticatedId;
                    }
                    con.close();
                } else { %>
                    <div class="alert alert-danger">Invalid login credentials.</div>
                <% }
                con.close();
            } catch(Exception e) { %><div class="alert alert-danger"><%= e.getMessage() %></div><% }
        }

        if(redirectTarget != null) {
        %>
            <script>
                // Store user identity in Tab-Isolated sessionStorage
                sessionStorage.setItem("tab_user_id", "<%= authenticatedId %>");
                sessionStorage.setItem("tab_user_name", "<%= authenticatedName %>");
                sessionStorage.setItem("tab_role", "<%= authenticatedRole %>");
                window.location.href = "<%= redirectTarget %>";
            </script>
        <%
            return;
        }
        %>
        <form method="post">
            <div class="form-group"><label>Email Address</label><input type="email" name="email" required></div>
            <div class="form-group"><label>Password</label><input type="password" name="password" required></div>
            <button type="submit">Sign In</button>
        </form>
    </div>
</body>
</html>