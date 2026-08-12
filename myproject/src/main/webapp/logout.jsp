<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%
String uidStr = request.getParameter("uid");
String role = request.getParameter("role");

if(uidStr != null && !uidStr.trim().isEmpty()) {
    try {
        int uId = Integer.parseInt(uidStr);
        session.removeAttribute("user_" + uId);
        session.removeAttribute("role_" + uId);
    } catch(Exception e){}
}

if("ADMIN".equalsIgnoreCase(role)) {
    session.removeAttribute("admin_user");
    session.removeAttribute("admin_user_id");
    session.removeAttribute("admin_role");
} else {
    session.removeAttribute("student_user");
    session.removeAttribute("student_user_id");
    session.removeAttribute("user");
    session.removeAttribute("user_id");
    session.removeAttribute("role");
}

response.sendRedirect("login.jsp");
%>