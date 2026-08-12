<%@ page import="java.sql.*, com.vstand4u.DBConnection" %>
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
        if(request.getParameter("email") != null) {
            try {
                Connection con = DBConnection.getConnection();
                PreparedStatement ps = con.prepareStatement("SELECT * FROM users WHERE email=? AND password=?");
                ps.setString(1, request.getParameter("email"));
                ps.setString(2, request.getParameter("password"));
                ResultSet rs = ps.executeQuery();
                
                if(rs.next()) {
                    session.setAttribute("user", rs.getString("name"));
                    session.setAttribute("user_id", rs.getInt("id"));
                    session.setAttribute("role", rs.getString("role"));
                    
                    if("ADMIN".equals(rs.getString("role"))) {
                        response.sendRedirect("admin.jsp");
                    } else {
                        response.sendRedirect("dashboard.jsp");
                    }
                    return;
                } else { %>
                    <div class="alert alert-danger">Invalid login credentials.</div>
                <% }
                con.close();
            } catch(Exception e) { %><div class="alert alert-danger"><%= e.getMessage() %></div><% }
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