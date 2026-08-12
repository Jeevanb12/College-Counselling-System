<%@ page import="java.sql.*, com.vstand4u.DBConnection" %>
<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%
if(session.getAttribute("user") == null || !"ADMIN".equals(session.getAttribute("role"))) {
    response.sendRedirect("login.jsp");
    return;
}

String successMessage = null;
// Process internal inventory operations
if(request.getParameter("add_college") != null) {
    try {
        Connection con = DBConnection.getConnection();
        PreparedStatement ps = con.prepareStatement(
            "INSERT INTO colleges(college_name, course, cutoff, fee, district, type) VALUES(?,?,?,?,?,?)");
        ps.setString(1, request.getParameter("name"));
        ps.setString(2, request.getParameter("course"));
        ps.setInt(3, Integer.parseInt(request.getParameter("cutoff")));
        ps.setInt(4, Integer.parseInt(request.getParameter("fee")));
        ps.setString(5, request.getParameter("district"));
        ps.setString(6, request.getParameter("type"));
        ps.executeUpdate();
        con.close();
        successMessage = "New institution inventory index successfully committed!";
    } catch(Exception e){ successMessage = "Error inserting context: " + e.getMessage(); }
}
%>
<!DOCTYPE html>
<html>
<head>
    <title>System Administration Command Panel</title>
    <link rel="stylesheet" type="text/css" href="style.css?v=2.0">
</head>
<body>
    <div class="container wide" style="max-width: 1100px;">
        <div class="brand-title">Admin <span class="brand-accent">Control Center</span></div>
        <div class="brand-subtitle">Platform Master Asset & Inventory Maintenance Module</div>
        
        <% if(successMessage != null) { %><div class="alert alert-success"><%= successMessage %></div><% } %>

        <div class="app-layout" style="width:100%; margin: 20px 0; gap:20px;">
            <div class="sidebar" style="flex:1; text-align:left;">
                <h3 style="color:#ffffff; margin-top:0;">Add New College</h3>
                <form method="post">
                    <input type="hidden" name="add_college" value="true">
                    <div class="form-group"><label>College Name</label><input type="text" name="name" required></div>
                    <div class="form-group"><label>Course Code</label><input type="text" name="course" placeholder="e.g. CSE" required></div>
                    <div class="row">
                        <div class="col class form-group"><label>Cutoff</label><input type="number" name="cutoff" required></div>
                        <div class="col class form-group"><label>Annual Fee (₹)</label><input type="number" name="fee" required></div>
                    </div>
                    <div class="row">
                        <div class="col class form-group"><label>District</label><input type="text" name="district" required></div>
                        <div class="col class form-group"><label>Management Type</label>
                            <select name="type">
                                <option value="Government">Government</option>
                                <option value="Private">Private</option>
                                <option value="Aided">Aided</option>
                            </select></div>
                    </div>
                    <button type="submit" style="margin-top:10px;">Insert Asset Row</button>
                </form>
            </div>

            <div class="main-content container" style="flex:1.5; max-width:100%; background:#111827;">
                <h3 style="text-align:left; margin-top:0;">Registered System Users</h3>
                <div class="table-responsive" style="max-height:380px; overflow-y:auto;">
                    <table>
                        <thead>
                            <tr>
                                <th>ID</th>
                                <th>Name</th>
                                <th>Email</th>
                                <th>Stream Target</th>
                                <th>City</th>
                            </tr>
                        </thead>
                        <tbody>
                        <%
                        try {
                            Connection con = DBConnection.getConnection();
                            ResultSet rs = con.createStatement().executeQuery("SELECT * FROM users WHERE role='USER' ORDER BY id DESC");
                            while(rs.next()) {
                        %>
                            <tr>
                                Liked<td><%= rs.getInt("id") %></td>
                                <td><strong><%= rs.getString("name") %></strong></td>
                                <td><%= rs.getString("email") %></td>
                                <td><span style="color:#00e5a3;"><%= rs.getString("stream") %></span></td>
                                <td><%= rs.getString("city") %></td>
                            </tr>
                        <%  }
                            con.close();
                        } catch(Exception e){} %>
                        </tbody>
                    </table>
                </div>
            </div>
        </div>
        <div class="navbar-links"><a href="logout.jsp" class="nav-link" style="color:#ef4444;">Terminate Admin Session</a></div>
    </div>
</body>
</html>