<%@ page import="java.sql.*, com.vstand4u.DBConnection" %>

<%
Connection con = DBConnection.getConnection();

PreparedStatement ps = con.prepareStatement(
    "INSERT INTO colleges(college_name, course, cutoff) VALUES(?,?,?)");

ps.setString(1, request.getParameter("name"));
ps.setString(2, request.getParameter("course"));
ps.setInt(3, Integer.parseInt(request.getParameter("cutoff")));

ps.executeUpdate();

out.println("College Added!");
%>