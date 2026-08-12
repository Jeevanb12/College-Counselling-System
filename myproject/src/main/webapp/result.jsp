<%@ page import="java.sql.*, java.util.*, com.vstand4u.DBConnection" %>
<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%
if(session.getAttribute("user") == null) { response.sendRedirect("login.jsp"); return; }
int userId = (Integer) session.getAttribute("user_id");

// Fallback validation checks to break loops if parameters are completely missing
if(request.getParameter("marks") == null) {
    response.sendRedirect("dashboard.jsp");
    return;
}

int marks = Integer.parseInt(request.getParameter("marks"));
String[] rawCourses = request.getParameterValues("course");

// If no checkboxes were ticked, default to search all options instead of crashing or looping
if(rawCourses == null) {
    rawCourses = new String[]{"CSE", "ECE", "IT", "MECH"};
}

String coursesJoined = String.join(",", rawCourses);

// Log lookup to transaction table
try {
    Connection con = DBConnection.getConnection();
    PreparedStatement histPs = con.prepareStatement("INSERT INTO search_history(user_id, marks, courses) VALUES(?,?,?)");
    histPs.setInt(1, userId); histPs.setInt(2, marks); histPs.setString(3, coursesJoined);
    histPs.executeUpdate();
    con.close();
} catch(Exception e){}
%>
<!DOCTYPE html>
<html>
<head>
    <title>Analysis Results</title>
    <link rel="stylesheet" type="text/css" href="style.css?v=2.1">
    <script>
        function filterByDistrict() {
            var dist = document.getElementById('distFilter').value.toLowerCase();
            var rows = document.getElementById('resultBody').getElementsByTagName('tr');
            for(var i=0; i<rows.length; i++) {
                var cell = rows[i].getElementsByTagName('td')[2];
                if(cell) {
                    rows[i].style.display = (dist === "" || cell.innerText.toLowerCase() === dist) ? "" : "none";
                }
            }
        }
        function sortTable(colIndex) {
            var table = document.getElementById("resultTable");
            var rows = Array.from(table.rows).slice(1);
            var ascending = table.getAttribute("data-sort-dir") !== "asc";
            
            rows.sort((tr1, tr2) => {
                var val1 = tr1.cells[colIndex].innerText;
                var val2 = tr2.cells[colIndex].innerText;
                return isNaN(val1) ? val1.localeCompare(val2) : parseFloat(val1) - parseFloat(val2);
            });
            if (!ascending) rows.reverse();
            
            rows.forEach(row => table.appendChild(row));
            table.setAttribute("data-sort-dir", ascending ? "asc" : "desc");
        }
        function saveToShortlist(btn, collegeId) {
            var xhr = new XMLHttpRequest();
            xhr.open("POST", "shortlist.jsp?action=add&college_id=" + collegeId, true);
            xhr.onreadystatechange = function() {
                if(xhr.readyState == 4 && xhr.status == 200) {
                    btn.innerText = "Saved!";
                    btn.disabled = true;
                    btn.style.background = "#27ae60";
                }
            };
            xhr.send();
        }
    </script>
</head>
<body>
    <div class="container wide">
        <div class="brand-title">Matched <span class="brand-accent">Institutions</span></div>
        <div class="brand-subtitle">Score Threshold: <%= marks %> | Target Streams: <%= coursesJoined %></div>

        <div style="display:flex; justify-content:space-between; gap:20px; margin: 30px 0 15px;">
            <div style="width:250px;">
                <select id="distFilter" onchange="filterByDistrict()">
                    <option value="">All Districts</option>
                    <option value="Bengaluru">Bengaluru</option>
                    <option value="Davanagere">Davanagere</option>
                </select>
            </div>
            <div style="display:flex; gap:10px;">
                <button class="btn btn-secondary btn-sm" onclick="sortTable(0)">Sort By Name</button>
                <button class="btn btn-secondary btn-sm" onclick="sortTable(4)">Sort By Cutoff</button>
            </div>
        </div>

        <div class="table-responsive">
            <table id="resultTable">
                <thead>
                    <tr>
                        <th>College Name</th>
                        <th>Stream</th>
                        <th>District</th>
                        <th>Management</th>
                        <th>Cutoff</th>
                        <th>Score Gap</th>
                        <th>Annual Fee</th>
                        <th>Admissions Probability</th>
                        <th>Actions</th>
                    </tr>
                </thead>
                <tbody id="resultBody">
                <%
                try {
                    Connection con = DBConnection.getConnection();
                    
                    // Generate dynamic placement holders matching checked array inputs
                    List<String> conditions = new ArrayList<String>();
                    for(int i=0; i<rawCourses.length; i++) {
                        conditions.add("course = ?");
                    }
                    String courseQueryPart = String.join(" OR ", conditions);
                    
                    String query = "SELECT * FROM colleges WHERE (" + courseQueryPart + ") AND cutoff <= ? ORDER BY cutoff DESC";
                    PreparedStatement ps = con.prepareStatement(query);
                    
                    int idx = 1;
                    for(String c : rawCourses) {
                        ps.setString(idx++, c);
                    }
                    ps.setInt(idx, marks);
                    
                    ResultSet rs = ps.executeQuery();
                    boolean entriesExist = false;
                    while(rs.next()) {
                        entriesExist = true;
                        int id = rs.getInt("id");
                        int cutoff = rs.getInt("cutoff");
                        int gap = marks - cutoff;
                        
                        String chance = "Low"; String badge = "chance-low";
                        if(gap >= 20) { chance = "High"; badge = "chance-high"; }
                        else if(gap >= 0) { chance = "Medium"; badge = "chance-medium"; }
                %>
                    <tr>
                        <td><strong><%= rs.getString("college_name") %></strong></td>
                        <td><span style="color:#00e5a3;"><%= rs.getString("course") %></span></td>
                        <td><%= rs.getString("district") %></td>
                        <td><%= rs.getString("type") %></td>
                        <td><%= cutoff %></td>
                        <td style="color:<%= gap >= 20 ? "#2ecc71" : "#f1c40f" %>;">+<%= gap %></td>
                        <td>₹<%= rs.getInt("fee") %></td>
                        <td><span class="chance-badge <%= badge %>"><%= chance %></span></td>
                        <td><button class="btn btn-sm" onclick="saveToShortlist(this, <%= id %>)">Save</button></td>
                    </tr>
                <%  }
                    if(!entriesExist) {
                %>
                    <tr><td colspan="9" style="text-align:center; padding: 30px; color:#9ca3af;">No colleges match your current cutoff range criteria.</td></tr>
                <%
                    }
                    con.close();
                } catch(Exception e) { %><tr><td colspan="9">System Error: <%= e.getMessage() %></td></tr><% } %>
                </tbody>
            </table>
        </div>
        <button onclick="location.href='dashboard.jsp'" class="btn-secondary" style="margin-top:25px; width:200px;">Modify Filters</button>
    </div>
</body>
</html>