<%@ page import="java.sql.*, com.vstand4u.DBConnection" %>
<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%
if(session.getAttribute("user") == null) { response.sendRedirect("login.jsp"); return; }
int userId = (Integer) session.getAttribute("user_id");

String stream="", city="", phone="", email="";
try {
    Connection con = DBConnection.getConnection();
    PreparedStatement ps = con.prepareStatement("SELECT * FROM users WHERE id=?");
    ps.setInt(1, userId);
    ResultSet rs = ps.executeQuery();
    if(rs.next()){
        stream = rs.getString("stream"); city = rs.getString("city");
        phone = rs.getString("phone"); email = rs.getString("email");
    }
    con.close();
} catch(Exception e){}
%>
<!DOCTYPE html>
<html>
<head>
    <title>Dashboard - Counselling System</title>
    <link rel="stylesheet" type="text/css" href="style.css?v=2.2">
</head>
<body>
    <div class="app-layout">
        <div class="sidebar">
            <div style="width: 50px; height: 50px; background: #00e5a3; border-radius: 50%; margin: 0 auto 15px; display: flex; align-items: center; justify-content: center; color: #0b0f19; font-weight: bold; font-size: 20px;">
                <%= ((String)session.getAttribute("user")).substring(0,1).toUpperCase() %>
            </div>
            <h3 style="margin: 0; text-align: center;"><%= session.getAttribute("user") %></h3>
            <p style="color: #6b7280; font-size: 12px; text-align: center; margin-bottom: 20px;"><%= email %></p>
            
            <div class="form-group"><label>Stream</label><div style="color:#00e5a3; font-weight:600;"><%= stream %></div></div>
            <div class="form-group"><label>Phone</label><div style="color:#e5e7eb;"><%= phone %></div></div>
            <div class="form-group"><label>City</label><div style="color:#e5e7eb;"><%= city %></div></div>
            
            <div class="divider">Navigation</div>
            <a href="shortlist.jsp" class="btn btn-secondary btn-sm" style="width:100%; margin-bottom:10px;">My Saved Shortlist</a>
            <a href="history.jsp" class="btn btn-secondary btn-sm" style="width:100%;">View Search History</a>
        </div>

        <div class="main-content container" style="max-width: 100%;">
            <div class="brand-title" style="text-align:left;">Query <span class="brand-accent">Institutions</span></div>
            <p style="color: #6b7280; text-align:left; font-size:14px;">Select multiple target courses and define your score parameters.</p>
            
            <form action="result.jsp" method="post" style="margin-top:30px;">
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
                    <% if("Medical".equalsIgnoreCase(stream)) { %>
                        <label>Target Medical Specializations (Select Multiple)</label>
                        <div class="checkbox-grid">
                            <label class="checkbox-item"><input type="checkbox" name="course" value="MBBS" checked> MBBS (Medicine)</label>
                            <label class="checkbox-item"><input type="checkbox" name="course" value="BDS"> BDS (Dental)</label>
                            <label class="checkbox-item"><input type="checkbox" name="course" value="BAMS"> BAMS (Ayurveda)</label>
                            <label class="checkbox-item"><input type="checkbox" name="course" value="BHMS"> BHMS (Homeopathy)</label>
                        </div>
                    <% } else if("Arts".equalsIgnoreCase(stream)) { %>
                        <label>Target Arts & Commerce Specializations (Select Multiple)</label>
                        <div class="checkbox-grid">
                            <label class="checkbox-item"><input type="checkbox" name="course" value="BA" checked> BA (Arts)</label>
                            <label class="checkbox-item"><input type="checkbox" name="course" value="BCom"> BCom (Commerce)</label>
                            <label class="checkbox-item"><input type="checkbox" name="course" value="BBA"> BBA (Management)</label>
                            <label class="checkbox-item"><input type="checkbox" name="course" value="BCA"> BCA (Applications)</label>
                        </div>
                    <% } else { %>
                        <label>Target Engineering Specializations (Select Multiple)</label>
                        <div class="checkbox-grid">
                            <label class="checkbox-item"><input type="checkbox" name="course" value="CSE" checked> CSE</label>
                            <label class="checkbox-item"><input type="checkbox" name="course" value="ECE"> ECE</label>
                            <label class="checkbox-item"><input type="checkbox" name="course" value="IT"> IT</label>
                            <label class="checkbox-item"><input type="checkbox" name="course" value="MECH"> MECH</label>
                        </div>
                    <% } %>
                </div>
                
                <button type="submit" style="margin-top: 15px;">Search Matching Colleges</button>
            </form>
            <div class="navbar-links"><a href="logout.jsp" class="nav-link" style="color:#ef4444;">Logout Session</a></div>
        </div>
    </div>
</body>
</html>