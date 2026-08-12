<%@ page import="java.sql.*" %>
<%@ include file="db.jsp" %>

<%
Connection con = getDBConnection();

String code = request.getParameter("college_code");
if(code == null || code.trim().isEmpty()) code = "E301";

PreparedStatement ps = con.prepareStatement(
    "INSERT INTO colleges(college_code, college_name, course, cutoff, fee, district, type) VALUES(?,?,?,?,?,?,?)");

ps.setString(1, code.trim().toUpperCase());
ps.setString(2, request.getParameter("name"));
ps.setString(3, request.getParameter("course").trim().toUpperCase());
ps.setInt(4, Integer.parseInt(request.getParameter("cutoff")));
ps.setInt(5, request.getParameter("fee") != null ? Integer.parseInt(request.getParameter("fee")) : 50000);
ps.setString(6, request.getParameter("district") != null ? request.getParameter("district") : "Bengaluru");
ps.setString(7, request.getParameter("type") != null ? request.getParameter("type") : "Government");

ps.executeUpdate();
con.close();

out.println("College Asset Added!");
%>