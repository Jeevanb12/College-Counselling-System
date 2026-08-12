<%@ page import="java.sql.*" %>
<%@ include file="db.jsp" %>
<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%
String uidStr = request.getParameter("uid");
int userId = 0;
if(uidStr != null && !uidStr.trim().isEmpty()) {
    try { userId = Integer.parseInt(uidStr); } catch(Exception e){}
}
if(userId == 0 && session.getAttribute("user_id") != null) {
    userId = (Integer) session.getAttribute("user_id");
}
if(userId == 0 && session.getAttribute("student_user_id") != null) {
    userId = (Integer) session.getAttribute("student_user_id");
}
if(userId == 0) { response.sendRedirect("login.jsp"); return; }

// AJAX dynamic insertion handling segment
String action = request.getParameter("action");
if("add".equals(action)) {
    try {
        Connection con = getDBConnection();
        PreparedStatement ps = con.prepareStatement("INSERT IGNORE INTO shortlist(user_id, college_id) VALUES(?,?)");
        ps.setInt(1, userId); ps.setInt(2, Integer.parseInt(request.getParameter("college_id")));
        ps.executeUpdate(); con.close();
    } catch(Exception e){}
    return; // Exit execution loop early for async responses
}

// Remove selection parameter request handling
if("delete".equals(action)) {
    try {
        Connection con = getDBConnection();
        PreparedStatement ps = con.prepareStatement("DELETE FROM shortlist WHERE user_id=? AND college_id=?");
        ps.setInt(1, userId); ps.setInt(2, Integer.parseInt(request.getParameter("college_id")));
        ps.executeUpdate(); con.close();
    } catch(Exception e){}
}
%>
<!DOCTYPE html>
<html>
<head>
    <title>My Shortlist - Comparison View</title>
    <link rel="stylesheet" type="text/css" href="style.css?v=2.0">
    <style>
        @media print {
            body { background: white; color: black; }
            .container { max-width: 100%; border: none; box-shadow: none; background: white; color: black; }
            button, .nav-link, th:last-child, td:last-child { display: none !important; }
            th { background: #f0f0f0 !important; color: black !important; }
            td, th { border: 1px solid #ccc !important; }
        }
    </style>
</head>
<body>
    <div class="container wide">
        <div class="brand-title">Saved <span class="brand-accent">Shortlist</span></div>
        <div class="brand-subtitle">Side-by-Side Institutional Comparison Grid</div>
        
        <div style="text-align: right; margin-bottom: 20px;">
            <button class="btn btn-secondary btn-sm" onclick="window.print()">Download Report as PDF</button>
        </div>

        <div class="table-responsive">
            <table>
                <thead>
                    <tr>
                        <th>College Name</th>
                        <th>Course Stream</th>
                        <th>District Location</th>
                        <th>Category</th>
                        <th>Cutoff Standard</th>
                        <th>Annual Tuition Fee</th>
                        <th>Action</th>
                    </tr>
                </thead>
                <tbody>
                <%
                try {
                    Connection con = getDBConnection();
                    PreparedStatement ps = con.prepareStatement(
                        "SELECT c.* FROM colleges c JOIN shortlist s ON c.id = s.college_id WHERE s.user_id=?");
                    ps.setInt(1, userId);
                    ResultSet rs = ps.executeQuery();
                    boolean empty = true;
                    while(rs.next()) {
                        empty = false;
                %>
                    <tr>
                        <td><strong><%= rs.getString("college_name") %></strong></td>
                        <td><span style="color:#00e5a3;"><%= rs.getString("course") %></span></td>
                        <td><%= rs.getString("district") %></td>
                        <td><%= rs.getString("type") %></td>
                        <td><%= rs.getInt("cutoff") %></td>
                        <td>₹<%= rs.getInt("fee") %></td>
                        <td><a href="shortlist.jsp?action=delete&college_id=<%= rs.getInt("id") %>" class="btn btn-danger btn-sm" style="text-transform:none;">Remove</a></td>
                    </tr>
                <%  }
                    if(empty) { %><tr><td colspan="7">No options saved to your custom portfolio folder yet.</td></tr><% }
                    con.close();
                } catch(Exception e){}%>
                </tbody>
            </table>
        </div>
        <div class="navbar-links"><a href="dashboard.jsp" class="nav-link">← Return to Dashboard</a></div>
    </div>
</body>
</html>