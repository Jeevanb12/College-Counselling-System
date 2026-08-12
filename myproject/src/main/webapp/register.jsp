<%@ page import="java.sql.*, com.vstand4u.DBConnection" %>
<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<!DOCTYPE html>
<html>
<head>
    <title>Patient Sign up - Counselling System</title>
    <link rel="stylesheet" type="text/css" href="style.css?v=2.0">
    <script>
        function checkPasswordStrength() {
            var pass = document.getElementById('passInput').value;
            var meter = document.getElementById('meterBar');
            var width = 0; var color = "#374151";
            
            if (pass.length >= 4) width += 25;
            if (/[A-Z]/.test(pass)) width += 25;
            if (/[0-9]/.test(pass)) width += 25;
            if (/[^A-Za-z0-9]/.test(pass)) width += 25;
            
            if(width <= 25) color = "#e74c3c";
            else if(width <= 75) color = "#f1c40f";
            else color = "#2ecc71";
            
            meter.style.width = width + '%';
            meter.style.backgroundColor = color;
        }
    </script>
</head>
<body>
    <div class="container">
        <div class="brand-title">College<span class="brand-accent">Counselling</span></div>
        <div class="brand-subtitle">Admission Matching Engine</div>
        
        <div class="tab-container">
            <a href="login.jsp" class="tab">Sign in</a>
            <a href="register.jsp" class="tab active">Sign up</a>
        </div>
        
        <%
        String errorMsg = null;
        if(request.getParameter("email") != null) {
            try {
                Connection con = DBConnection.getConnection();
                
                // 1. Pre-check if email already exists
                PreparedStatement checkPs = con.prepareStatement("SELECT id FROM users WHERE email=?");
                checkPs.setString(1, request.getParameter("email"));
                if(checkPs.executeQuery().next()) {
                    errorMsg = "This email address is already taken!";
                } else {
                    // 2. Insert new user record and request the auto-generated ID back
                    PreparedStatement ps = con.prepareStatement(
                        "INSERT INTO users(name,email,password,stream,city,phone,role) VALUES(?,?,?,?,?,?,'USER')",
                        Statement.RETURN_GENERATED_KEYS
                    );
                    ps.setString(1, request.getParameter("name"));
                    ps.setString(2, request.getParameter("email"));
                    ps.setString(3, request.getParameter("password"));
                    ps.setString(4, request.getParameter("stream"));
                    ps.setString(5, request.getParameter("city"));
                    ps.setString(6, request.getParameter("phone"));
                    ps.executeUpdate();
                    
                    // 3. Extract the new ID created by MySQL
                    ResultSet generatedKeys = ps.getGeneratedKeys();
                    if(generatedKeys.next()) {
                        int newUserId = generatedKeys.getInt(1);
                        
                        // 4. Save BOTH attributes to session safely
                        session.setAttribute("user", request.getParameter("name"));
                        session.setAttribute("user_id", newUserId); 
                        session.setAttribute("role", "USER");
                        
                        con.close();
                        response.sendRedirect("dashboard.jsp");
                        return;
                    } else {
                        // Fallback check: If database didn't return key instantly, query it manually by email
                        PreparedStatement fallbackPs = con.prepareStatement("SELECT id FROM users WHERE email=?");
                        fallbackPs.setString(1, request.getParameter("email"));
                        ResultSet fallbackRs = fallbackPs.executeQuery();
                        if(fallbackRs.next()) {
                            session.setAttribute("user", request.getParameter("name"));
                            session.setAttribute("user_id", fallbackRs.getInt("id"));
                            session.setAttribute("role", "USER");
                            
                            con.close();
                            response.sendRedirect("dashboard.jsp");
                            return;
                        } else {
                            errorMsg = "Account insertion profile handshake failed.";
                        }
                    }
                }
                con.close();
            } catch(Exception e) { 
                errorMsg = "System Fault: " + e.getMessage(); 
            }
        }
        if(errorMsg != null) { 
        %>
            <div class="alert alert-danger"><%= errorMsg %></div>
        <% } %>

        <form method="post">
            <div class="form-group">
                <label>Full Name</label>
                <input type="text" name="name" required placeholder="Arjun Sharma">
            </div>
            <div class="row">
                <div class="col form-group">
                    <label>Email Address</label>
                    <input type="email" name="email" required placeholder="arjun@example.com">
                </div>
                <div class="col form-group">
                    <label>Phone Number</label>
                    <input type="text" name="phone" required placeholder="9876543210">
                </div>
            </div>
            <div class="row">
                <div class="col form-group">
                    <label>Academic Stream</label>
                    <select name="stream">
                        <option value="Engineering">Engineering</option>
                        <option value="Medical">Medical</option>
                        <option value="Arts">Arts</option>
                    </select>
                </div>
                <div class="col form-group">
                    <label>City</label>
                    <input type="text" name="city" required placeholder="Davanagere">
                </div>
            </div>
            <div class="divider">security credentials</div>
            <div class="form-group">
                <label>Password</label>
                <input type="password" id="passInput" name="password" onkeyup="checkPasswordStrength()" required placeholder="••••••">
                <div class="strength-meter" id="meterBar"></div>
            </div>
            <button type="submit">Create account & sign in</button>
        </form>
    </div>
</body>
</html>