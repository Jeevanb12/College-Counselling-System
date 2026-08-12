<%@ page import="java.sql.*, java.util.*" %>
<%@ include file="db.jsp" %>
<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%
String uidStr = request.getParameter("uid");
int userId = 0;
String studentName = null;

if(uidStr != null && !uidStr.trim().isEmpty()) {
    try {
        int parsedId = Integer.parseInt(uidStr);
        String nameFromSession = (String) session.getAttribute("user_" + parsedId);
        if(nameFromSession != null) {
            userId = parsedId;
            studentName = nameFromSession;
        }
    } catch(Exception e){}
}

if(studentName == null) {
    studentName = (String) session.getAttribute("student_user");
    Integer sId = (Integer) session.getAttribute("student_user_id");
    if(sId != null) userId = sId;
}

if(studentName == null) {
    studentName = (String) session.getAttribute("user");
    Integer uId = (Integer) session.getAttribute("user_id");
    if(uId != null) userId = uId;
}

if(studentName == null || userId == 0) {
    response.sendRedirect("login.jsp");
    return;
}

String stream="", city="", phone="", email="";
try {
    Connection con = getDBConnection();
    PreparedStatement ps = con.prepareStatement("SELECT * FROM users WHERE id=?");
    ps.setInt(1, userId);
    ResultSet rs = ps.executeQuery();
    if(rs.next()){
        stream = rs.getString("stream"); city = rs.getString("city");
        phone = rs.getString("phone"); email = rs.getString("email");
    }
    con.close();
} catch(Exception e){}

// Dynamically fetch ALL distinct courses from colleges table with robust Java filtering
List<String> availableCourses = new ArrayList<>();
String dbErrorMessage = null;

try {
    Connection con = getDBConnection();
    if(con != null) {
        Statement st = con.createStatement();
        ResultSet rsC = st.executeQuery("SELECT DISTINCT UPPER(TRIM(course)) FROM colleges WHERE course IS NOT NULL AND TRIM(course) != ''");
        
        while(rsC.next()) {
            String c = rsC.getString(1);
            if(c != null) {
                c = c.trim();
                
                // Check if numeric (e.g. '1234')
                boolean isNumeric = true;
                for(int i = 0; i < c.length(); i++) {
                    if(!Character.isDigit(c.charAt(i))) {
                        isNumeric = false;
                        break;
                    }
                }
                
                if(!isNumeric && !c.isEmpty() && !availableCourses.contains(c)) {
                    // Filter courses based on user's stream
                    if(stream != null && stream.toLowerCase().contains("med")) {
                        if(c.equals("MBBS") || c.equals("BDS") || c.equals("BAMS") || c.equals("BHMS") || c.contains("MED") || c.contains("DENT")) {
                            availableCourses.add(c);
                        }
                    } else if(stream != null && stream.toLowerCase().contains("art")) {
                        if(c.equals("BA") || c.equals("BCOM") || c.equals("BBA") || c.equals("BCA") || c.contains("ART") || c.contains("COM")) {
                            availableCourses.add(c);
                        }
                    } else {
                        // Engineering stream: Include all non-medical, non-arts courses
                        if(!c.equals("MBBS") && !c.equals("BDS") && !c.equals("BAMS") && !c.equals("BHMS") &&
                           !c.equals("BA") && !c.equals("BCOM") && !c.equals("BBA") && !c.equals("BCA")) {
                            availableCourses.add(c);
                        }
                    }
                }
            }
        }
        rsC.close();
        st.close();
        con.close();
    }
} catch(Exception ex){
    dbErrorMessage = ex.getMessage();
}

// Guaranteed fallbacks so student dashboard NEVER displays empty box
if(availableCourses.isEmpty()) {
    if(stream != null && stream.toLowerCase().contains("med")) {
        availableCourses.add("MBBS"); availableCourses.add("BDS");
    } else if(stream != null && stream.toLowerCase().contains("art")) {
        availableCourses.add("BA"); availableCourses.add("BCOM");
    } else {
        availableCourses.add("CSE"); availableCourses.add("ECE"); availableCourses.add("MECH"); availableCourses.add("CIVIL");
    }
}
%>
<!DOCTYPE html>
<html>
<head>
    <title>Dashboard - Counselling System</title>
    <link rel="stylesheet" type="text/css" href="style.css?v=4.0">
    <script>
        // Enforce Per-Tab User Session Isolation via sessionStorage
        (function() {
            var tabUid = sessionStorage.getItem("tab_user_id");
            if(tabUid) {
                var urlParams = new URLSearchParams(window.location.search);
                var pageUid = urlParams.get("uid");
                if (pageUid !== tabUid) {
                    urlParams.set("uid", tabUid);
                    window.location.replace(window.location.pathname + "?" + urlParams.toString());
                }
            }
        })();
    </script>
</head>
<body>
    <div class="app-layout">
        <div class="sidebar">
            <div style="width: 50px; height: 50px; background: #00e5a3; border-radius: 50%; margin: 0 auto 15px; display: flex; align-items: center; justify-content: center; color: #0b0f19; font-weight: bold; font-size: 20px;">
                <%= studentName.substring(0,1).toUpperCase() %>
            </div>
            <h3 style="margin: 0; text-align: center;"><%= studentName %></h3>
            <p style="color: #6b7280; font-size: 12px; text-align: center; margin-bottom: 20px;"><%= email %></p>
            
            <div class="form-group"><label>Stream</label><div style="color:#00e5a3; font-weight:600;"><%= stream %></div></div>
            <div class="form-group"><label>Phone</label><div style="color:#e5e7eb;"><%= phone %></div></div>
            <div class="form-group"><label>City</label><div style="color:#e5e7eb;"><%= city %></div></div>
            
            <div class="divider">Navigation</div>
            <a href="shortlist.jsp?uid=<%= userId %>" class="btn btn-secondary btn-sm" style="width:100%; margin-bottom:10px;">My Saved Shortlist</a>
            <a href="history.jsp?uid=<%= userId %>" class="btn btn-secondary btn-sm" style="width:100%;">View Search History</a>
        </div>

        <div class="main-content container" style="max-width: 100%;">
            <div class="brand-title" style="text-align:left;">Query <span class="brand-accent">Institutions</span></div>
            <p style="color: #6b7280; text-align:left; font-size:14px;">Select multiple target courses and define your score parameters.</p>
            
            <% if(dbErrorMessage != null) { %>
                <div class="alert alert-danger" style="font-size:12px; padding:8px 12px; margin-bottom:15px;">Note: <%= dbErrorMessage %></div>
            <% } %>

            <form action="result.jsp" method="post" style="margin-top:30px;">
                <input type="hidden" name="uid" value="<%= userId %>">
                <div class="form-group">
                    <label>Obtained Entrance Marks: <span id="rangeVal" style="color:#00e5a3; font-size:14px; font-weight:bold;"><%= "Medical".equalsIgnoreCase(stream) ? "350" : "180" %></span></label>
                    <div class="range-container">
                        <% if("Medical".equalsIgnoreCase(stream)) { %>
                            <input type="range" name="marks" min="0" max="720" value="350" oninput="document.getElementById('rangeVal').innerText=this.value">
                        <% } else { %>
                            <input type="range" name="marks" min="0" max="400" value="180" oninput="document.getElementById('rangeVal').innerText=this.value">
                        <% } %>
                    </div>
                </div>
                
                <div class="form-group">
                    <label>Target <%= stream %> Specializations (Select Multiple)</label>
                    <div class="checkbox-grid">
                    <% 
                    boolean first = true;
                    for(String cName : availableCourses) { 
                    %>
                        <label class="checkbox-item">
                            <input type="checkbox" name="course" value="<%= cName %>" <%= first ? "checked" : "" %>> <%= cName %>
                        </label>
                    <% 
                        first = false;
                    } 
                    %>
                    </div>
                </div>
                
                <button type="submit" style="margin-top: 15px;">Search Matching Colleges</button>
            </form>
            <div class="navbar-links"><a href="logout.jsp?uid=<%= userId %>" class="nav-link" style="color:#ef4444;">Logout Session</a></div>
        </div>
    </div>
</body>
</html>