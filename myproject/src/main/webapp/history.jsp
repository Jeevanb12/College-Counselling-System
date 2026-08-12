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
%>
<!DOCTYPE html>
<html>
<head>
    <title>Search History Logs</title>
    <link rel="stylesheet" type="text/css" href="style.css?v=2.0">
</head>
<body>
    <div class="container wide" style="max-width:700px;">
        <div class="brand-title">Search <span class="brand-accent">History</span></div>
        <div class="brand-subtitle">Past Performance Queries Logged</div>

        <div class="table-responsive" style="margin-top:30px;">
            <table>
                <thead>
                    <tr>
                        <th>Query Timestamp</th>
                        <th>Logged Marks</th>
                        <th>Target Streams</th>
                        <th>Macro Execution</th>
                    </tr>
                </thead>
                <tbody>
                <%
                try {
                    Connection con = getDBConnection();
                    PreparedStatement ps = con.prepareStatement("SELECT * FROM search_history WHERE user_id=? ORDER BY searched_at DESC");
                    ps.setInt(1, userId);
                    ResultSet rs = ps.executeQuery();
                    boolean found = false;
                    while(rs.next()) {
                        found = true;
                        String courses = rs.getString("courses");
                        int marks = rs.getInt("marks");
                        
                        // Construct string concatenation parameters for redirection macros
                        String urlParam = "marks=" + marks;
                        for(String c : courses.split(",")) { urlParam += "&course=" + c; }
                %>
                    <tr>
                        <td><%= rs.getTimestamp("searched_at") %></td>
                        <td><strong><%= marks %></strong></td>
                        <td><span style="color:#00e5a3;"><%= courses %></span></td>
                        <td><a href="result.jsp?<%= urlParam %>" class="btn btn-sm" style="text-decoration:none;">Re-Run Query</a></td>
                    </tr>
                <%  }
                    if(!found) { %><tr><td colspan="4">No historical records are logged for your account context yet.</td></tr><% }
                    con.close();
                } catch(Exception e){} %>
                </tbody>
            </table>
        </div>
        <div class="navbar-links"><a href="dashboard.jsp" class="nav-link">← Return to Dashboard</a></div>
    </div>
</body>
</html>