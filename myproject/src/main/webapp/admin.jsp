<%@ page import="java.sql.*, java.util.*" %>
<%@ include file="db.jsp" %>
<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%
String uidStr = request.getParameter("uid");
int adminUserId = 0;
String adminUser = null;

if(uidStr != null && !uidStr.trim().isEmpty()) {
    try {
        int parsedId = Integer.parseInt(uidStr);
        String nameFromSession = (String) session.getAttribute("user_" + parsedId);
        if(nameFromSession != null) {
            adminUserId = parsedId;
            adminUser = nameFromSession;
        }
    } catch(Exception e){}
}

if(adminUser == null) {
    adminUser = (String) session.getAttribute("admin_user");
    Integer aId = (Integer) session.getAttribute("admin_user_id");
    if(aId != null) adminUserId = aId;
}

if(adminUser == null && "ADMIN".equals(session.getAttribute("role"))) {
    adminUser = (String) session.getAttribute("user");
}

if(adminUser == null) {
    response.sendRedirect("login.jsp");
    return;
}

String successMessage = null;
String errorMessage = null;

// 1. Process Core Actions: Delete Entire Institution, Delete Specific Course, Edit Course
String action = request.getParameter("action");
if("delete_institution".equals(action)) {
    String colNameToDelete = request.getParameter("college_name");
    if(colNameToDelete != null && !colNameToDelete.trim().isEmpty()) {
        try {
            Connection con = getDBConnection();
            PreparedStatement psDel = con.prepareStatement("DELETE FROM colleges WHERE UPPER(TRIM(college_name)) = UPPER(TRIM(?))");
            psDel.setString(1, colNameToDelete);
            int rows = psDel.executeUpdate();
            psDel.close();
            con.close();
            successMessage = "Successfully deleted institution [" + colNameToDelete + "] and all its (" + rows + ") enrolled course records!";
        } catch(Exception e){ errorMessage = "Error deleting institution: " + e.getMessage(); }
    }
} else if("delete_course".equals(action)) {
    String courseIdStr = request.getParameter("course_id");
    if(courseIdStr != null) {
        try {
            int cId = Integer.parseInt(courseIdStr);
            Connection con = getDBConnection();
            PreparedStatement psDelC = con.prepareStatement("DELETE FROM colleges WHERE id = ?");
            psDelC.setInt(1, cId);
            psDelC.executeUpdate();
            psDelC.close();
            con.close();
            successMessage = "Successfully removed course entry from institution!";
        } catch(Exception e){ errorMessage = "Error removing course: " + e.getMessage(); }
    }
} else if("edit_course".equals(action)) {
    String courseIdStr = request.getParameter("course_id");
    String newCourseName = request.getParameter("new_course_name");
    String newCutoffStr = request.getParameter("new_cutoff");
    String newFeeStr = request.getParameter("new_fee");
    if(courseIdStr != null && newCourseName != null) {
        try {
            int cId = Integer.parseInt(courseIdStr);
            int cCutoff = Integer.parseInt(newCutoffStr);
            int cFee = Integer.parseInt(newFeeStr);
            Connection con = getDBConnection();
            PreparedStatement psUpdC = con.prepareStatement(
                "UPDATE colleges SET course = UPPER(TRIM(?)), cutoff = ?, fee = ? WHERE id = ?");
            psUpdC.setString(1, newCourseName.trim());
            psUpdC.setInt(2, cCutoff);
            psUpdC.setInt(3, cFee);
            psUpdC.setInt(4, cId);
            psUpdC.executeUpdate();
            psUpdC.close();
            con.close();
            successMessage = "Successfully updated course [" + newCourseName.toUpperCase() + "] parameters!";
        } catch(Exception e){ errorMessage = "Error updating course: " + e.getMessage(); }
    }
}

// 2. Core Database Migration, Cleanup & Auto-Fix Engine
try {
    Connection con = getDBConnection();
    if(con != null) {
        con.setAutoCommit(true);
        
        // Ensure column exists
        try {
            con.createStatement().executeUpdate("ALTER TABLE colleges ADD COLUMN college_code VARCHAR(30) DEFAULT 'E101'");
        } catch(Exception ex){}

        // Clean up orphaned or junk test course entries (e.g. '1234', 'IT' if requested)
        try {
            if(request.getParameter("clean_it") != null || request.getParameter("force_fix") != null) {
                con.createStatement().executeUpdate("DELETE FROM colleges WHERE UPPER(course) = 'IT' OR course REGEXP '^[0-9]+$'");
            }
        } catch(Exception ex){}

        // Clean up duplicate course rows for the same college_code + course
        try {
            con.createStatement().executeUpdate(
                "DELETE c1 FROM colleges c1 INNER JOIN colleges c2 " +
                "WHERE c1.id > c2.id AND c1.college_code = c2.college_code AND UPPER(c1.course) = UPPER(c2.course)");
        } catch(Exception ex){}

        // Assign a UNIQUE Base Number (101, 102, 103...) to EVERY DISTINCT College Name
        Statement stmt = con.createStatement();
        ResultSet rsNames = stmt.executeQuery(
            "SELECT college_name FROM colleges GROUP BY college_name ORDER BY MIN(id) ASC");

        Map<String, String> collegeNameToBaseNum = new LinkedHashMap<>();
        int baseCounter = 101;

        while(rsNames.next()) {
            String colName = rsNames.getString("college_name");
            if(colName != null) {
                String key = colName.trim().toLowerCase();
                if(!collegeNameToBaseNum.containsKey(key)) {
                    collegeNameToBaseNum.put(key, String.valueOf(baseCounter++));
                }
            }
        }
        rsNames.close();
        stmt.close();

        // Loop through all database rows and generate Prefix + Unique Base Number (e.g. E101, A102, M103)
        Statement stmtRows = con.createStatement();
        ResultSet rsRows = stmtRows.executeQuery("SELECT id, college_name, course, college_code FROM colleges ORDER BY id ASC");
        
        List<Object[]> updates = new ArrayList<>();

        while(rsRows.next()) {
            int rowId = rsRows.getInt("id");
            String name = rsRows.getString("college_name");
            String course = rsRows.getString("course");
            String existingCode = rsRows.getString("college_code");
            
            if(name == null) name = "College " + rowId;
            if(course == null) course = "";

            String key = name.trim().toLowerCase();
            String baseNum = collegeNameToBaseNum.containsKey(key) ? collegeNameToBaseNum.get(key) : "101";

            String prefix = "E";
            String lowerN = name.toLowerCase();
            String lowerC = course.toLowerCase();

            if(lowerN.contains("med") || lowerN.contains("health") || lowerC.contains("mbbs") || lowerC.contains("bds") || lowerC.contains("bams")) {
                prefix = "M";
            } else if(lowerN.contains("arts") || lowerN.contains("com") || lowerC.contains("ba") || lowerC.contains("bcom") || lowerC.contains("bba") || lowerC.contains("bca")) {
                prefix = "A";
            }

            String finalCode = prefix + baseNum;
            if(existingCode == null || existingCode.equals("E101") || request.getParameter("force_fix") != null) {
                updates.add(new Object[]{finalCode, rowId});
            }
        }
        rsRows.close();
        stmtRows.close();

        // Execute UPDATE by Primary Key ID in MySQL
        if(!updates.isEmpty()) {
            PreparedStatement psUpd = con.prepareStatement("UPDATE colleges SET college_code = ? WHERE id = ?");
            for(Object[] up : updates) {
                psUpd.setString(1, (String) up[0]);
                psUpd.setInt(2, (Integer) up[1]);
                psUpd.executeUpdate();
            }
            psUpd.close();
        }
        
        if(request.getParameter("force_fix") != null) {
            successMessage = "Database cleaned successfully! Purged test entries and assigned unique codes.";
        }
        con.close();
    }
} catch(Exception e){
    errorMessage = "Migration Note: " + e.getMessage();
}

// 3. Process Form Submission for Adding/Updating College Course
if(request.getParameter("add_college") != null) {
    try {
        Connection con = getDBConnection();
        String code = request.getParameter("college_code");
        if(code == null || code.trim().isEmpty()) {
            code = "E101";
        }
        code = code.trim().toUpperCase();
        
        String name = request.getParameter("name");
        String course = request.getParameter("course").trim().toUpperCase();
        int cutoff = Integer.parseInt(request.getParameter("cutoff"));
        int fee = Integer.parseInt(request.getParameter("fee"));
        String district = request.getParameter("district");
        String type = request.getParameter("type");

        // Check if course already exists for this college code
        PreparedStatement checkPs = con.prepareStatement(
            "SELECT id FROM colleges WHERE college_code = ? AND UPPER(course) = ?");
        checkPs.setString(1, code);
        checkPs.setString(2, course);
        ResultSet rsCheck = checkPs.executeQuery();

        if(rsCheck.next()) {
            int existingId = rsCheck.getInt("id");
            rsCheck.close();
            checkPs.close();

            // Update existing course entry instead of creating a duplicate!
            PreparedStatement updatePs = con.prepareStatement(
                "UPDATE colleges SET cutoff = ?, fee = ?, district = ?, type = ?, college_name = ? WHERE id = ?");
            updatePs.setInt(1, cutoff);
            updatePs.setInt(2, fee);
            updatePs.setString(3, district);
            updatePs.setString(4, type);
            updatePs.setString(5, name);
            updatePs.setInt(6, existingId);
            updatePs.executeUpdate();
            updatePs.close();
            successMessage = "Updated existing course [" + course + "] under Code [" + code + "] for " + name + "!";
        } else {
            rsCheck.close();
            checkPs.close();

            // Insert new course entry
            PreparedStatement ps = con.prepareStatement(
                "INSERT INTO colleges(college_code, college_name, course, cutoff, fee, district, type) VALUES(?,?,?,?,?,?,?)");
            ps.setString(1, code);
            ps.setString(2, name);
            ps.setString(3, course);
            ps.setInt(4, cutoff);
            ps.setInt(5, fee);
            ps.setString(6, district);
            ps.setString(7, type);
            ps.executeUpdate();
            ps.close();
            successMessage = "Successfully committed course asset [" + course + "] under Code [" + code + "] for " + name + "!";
        }
        con.close();
    } catch(Exception e){ errorMessage = "Error committing course asset: " + e.getMessage(); }
}

// 4. Fetch Dashboard Analytics Data & Group Colleges Strictly by College Name
int totalColleges = 0;
int totalCourses = 0;
int totalStudents = 0;

class CollegeGroup {
    String name;
    String district;
    String type;
    Set<String> activeCodes = new LinkedHashSet<>();
    List<Map<String, String>> courses = new ArrayList<>();
}

Map<String, CollegeGroup> collegeMap = new LinkedHashMap<>();

try {
    Connection con = getDBConnection();
    
    // Total Registered Students Count
    ResultSet rsUsers = con.createStatement().executeQuery("SELECT COUNT(*) FROM users WHERE role='USER'");
    if(rsUsers.next()) totalStudents = rsUsers.getInt(1);
    
    // Fetch All Colleges & Group Strictly by College Name
    ResultSet rsColleges = con.createStatement().executeQuery("SELECT * FROM colleges ORDER BY id ASC");
    while(rsColleges.next()) {
        totalCourses++;
        String cCode = rsColleges.getString("college_code");
        if(cCode == null || cCode.trim().isEmpty()) cCode = "E101";
        cCode = cCode.trim().toUpperCase();
        
        String cName = rsColleges.getString("college_name");
        String key = cName.trim().toLowerCase();

        if(!collegeMap.containsKey(key)) {
            CollegeGroup cg = new CollegeGroup();
            cg.name = cName;
            cg.district = rsColleges.getString("district");
            cg.type = rsColleges.getString("type");
            collegeMap.put(key, cg);
        }
        
        collegeMap.get(key).activeCodes.add(cCode);
        
        Map<String, String> courseData = new HashMap<>();
        courseData.put("id", String.valueOf(rsColleges.getInt("id")));
        courseData.put("code", cCode);
        courseData.put("course", rsColleges.getString("course"));
        courseData.put("cutoff", String.valueOf(rsColleges.getInt("cutoff")));
        courseData.put("fee", String.valueOf(rsColleges.getInt("fee")));
        collegeMap.get(key).courses.add(courseData);
    }
    totalColleges = collegeMap.size();
    con.close();
} catch(Exception e){}
%>
<!DOCTYPE html>
<html>
<head>
    <title>Admin Control Center - Counselling System</title>
    <link rel="stylesheet" type="text/css" href="style.css?v=6.0">
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
    <style>
        .stats-grid {
            display: grid;
            grid-template-columns: repeat(3, 1fr);
            gap: 20px;
            margin-bottom: 25px;
        }
        .stat-card {
            background: #1f2937;
            border: 1px solid #374151;
            border-radius: 12px;
            padding: 20px;
            text-align: left;
            box-shadow: 0 4px 15px rgba(0,0,0,0.3);
        }
        .stat-number {
            font-size: 28px;
            font-weight: 800;
            color: #00e5a3;
            margin-top: 5px;
        }
        .stat-label {
            font-size: 11px;
            text-transform: uppercase;
            letter-spacing: 1px;
            color: #9ca3af;
        }
        .badges-container {
            display: inline-flex;
            flex-direction: row;
            align-items: center;
            flex-wrap: wrap;
            gap: 6px;
        }
        .code-badge {
            display: inline-flex;
            align-items: center;
            justify-content: center;
            background: rgba(0, 229, 163, 0.15);
            color: #00e5a3;
            border: 1px solid #00e5a3;
            padding: 3px 8px;
            border-radius: 6px;
            font-family: monospace;
            font-weight: bold;
            font-size: 12px;
            line-height: 1;
            white-space: nowrap;
        }
        .code-badge.med {
            background: rgba(239, 68, 68, 0.15);
            color: #ef4444;
            border-color: #ef4444;
        }
        .code-badge.arts {
            background: rgba(59, 130, 246, 0.15);
            color: #3b82f6;
            border-color: #3b82f6;
        }
        .form-group label {
            display: block;
            margin-bottom: 6px;
            font-size: 12px;
            font-weight: 600;
            color: #9ca3af;
            text-transform: uppercase;
        }
        .form-group input, .form-group select {
            height: 44px !important;
            padding: 8px 14px !important;
            font-size: 13px !important;
            line-height: 1.4 !important;
            box-sizing: border-box !important;
            border-radius: 8px !important;
            vertical-align: middle !important;
        }
        .course-chip {
            display: inline-flex;
            align-items: center;
            gap: 10px;
            background: #1f2937;
            border: 1px solid #374151;
            padding: 8px 14px;
            border-radius: 8px;
            margin: 4px;
            font-size: 12px;
        }
        .course-chip-title {
            color: #00e5a3;
            font-weight: bold;
            font-size: 13px;
        }
        .action-btn {
            background: #374151;
            color: #ffffff;
            border: none;
            padding: 5px 10px;
            border-radius: 6px;
            font-size: 11px;
            cursor: pointer;
            width: auto;
            text-transform: none;
            display: inline-flex;
            align-items: center;
            gap: 4px;
            transition: all 0.2s ease;
        }
        .action-btn:hover { background: #4b5563; }
        .action-btn.delete-btn { background: rgba(239, 68, 68, 0.2); color: #ef4444; border: 1px solid #ef4444; }
        .action-btn.delete-btn:hover { background: #ef4444; color: #ffffff; }
        .action-btn.edit-btn { background: rgba(59, 130, 246, 0.2); color: #3b82f6; border: 1px solid #3b82f6; }
        .action-btn.edit-btn:hover { background: #3b82f6; color: #ffffff; }

        .course-details-row {
            display: none;
            background: #0d131f;
        }

        /* Scrollable Container with Smooth Auto-Scroll */
        .table-scroll-container {
            max-height: 400px;
            overflow-y: auto;
            overflow-x: auto;
            scroll-behavior: smooth;
            border-radius: 8px;
        }

        /* Modal Overlay Styling */
        .modal-overlay {
            display: none;
            position: fixed;
            top: 0; left: 0; width: 100%; height: 100%;
            background: rgba(0,0,0,0.75);
            backdrop-filter: blur(5px);
            z-index: 9999;
            align-items: center;
            justify-content: center;
        }
        .modal-card {
            background: #1f2937;
            border: 1px solid #374151;
            border-radius: 12px;
            padding: 25px;
            width: 400px;
            box-shadow: 0 10px 30px rgba(0,0,0,0.5);
            text-align: left;
        }
    </style>
    <script>
        // Database Map of existing College Codes -> College Details
        var dbCodeMap = {
            <% 
            int idxMap = 0;
            for(Map.Entry<String, CollegeGroup> entry : collegeMap.entrySet()) {
                CollegeGroup cg = entry.getValue();
                for(String code : cg.activeCodes) {
            %>
                "<%= code %>": { name: "<%= cg.name.replace("\"", "\\\"") %>", district: "<%= cg.district %>", type: "<%= cg.type %>" }<%= (idxMap++ < totalCourses - 1) ? "," : "" %>
            <% 
                }
            } %>
        };

        function handleCollegeCodeInput() {
            var inputVal = document.getElementById('collegeCodeInput').value.trim().toUpperCase();
            var nameInput = document.getElementById('collegeNameInput');
            var districtInput = document.getElementById('districtInput');
            var typeSelect = document.getElementById('typeSelect');
            var hiddenTypeInput = document.getElementById('hiddenTypeInput');

            if(!inputVal) {
                nameInput.value = "";
                nameInput.readOnly = false;
                districtInput.value = "";
                districtInput.readOnly = false;
                typeSelect.disabled = false;
                typeSelect.style.opacity = "1";
                typeSelect.style.cursor = "pointer";
                return;
            }

            var prefix = inputVal.charAt(0);
            var num = inputVal.replaceAll(/[^0-9]/g, '');

            if(prefix === 'E' || prefix === 'M' || prefix === 'A') {
                document.getElementById('streamSelect').value = prefix;
            }

            var matchedCode = null;
            if(dbCodeMap[inputVal]) {
                matchedCode = inputVal;
            } else {
                for(var c in dbCodeMap) {
                    if(c.replaceAll(/[^0-9]/g, '') === num) {
                        matchedCode = c;
                        break;
                    }
                }
            }

            if(matchedCode) {
                var info = dbCodeMap[matchedCode];
                nameInput.value = info.name;
                nameInput.readOnly = true;

                districtInput.value = info.district;
                districtInput.readOnly = true;
                
                typeSelect.value = info.type;
                typeSelect.disabled = true;
                typeSelect.style.opacity = "0.6";
                typeSelect.style.cursor = "not-allowed";
                
                hiddenTypeInput.value = info.type;
            } else {
                nameInput.readOnly = false;
                districtInput.readOnly = false;
                typeSelect.disabled = false;
                typeSelect.style.opacity = "1";
                typeSelect.style.cursor = "pointer";
            }
        }

        function handleStreamChange() {
            var inputVal = document.getElementById('collegeCodeInput').value.trim().toUpperCase();
            var streamVal = document.getElementById('streamSelect').value;
            var num = inputVal.replaceAll(/[^0-9]/g, '');

            if(!num) num = "101";

            var updatedCode = streamVal + num;
            document.getElementById('collegeCodeInput').value = updatedCode;
            handleCollegeCodeInput();
        }

        function toggleCourses(rowId) {
            var row = document.getElementById('details_' + rowId);
            if(row.style.display === 'table-row') {
                row.style.display = 'none';
            } else {
                row.style.display = 'table-row';
                // Smoothly auto-scroll the table container so the expanded courses are fully visible!
                setTimeout(function(){
                    var container = document.getElementById('tableScrollContainer');
                    if(container) {
                        var rowBottom = row.offsetTop + row.offsetHeight;
                        var containerVisibleBottom = container.scrollTop + container.clientHeight;
                        if(rowBottom > containerVisibleBottom) {
                            container.scrollTop = rowBottom - container.clientHeight + 20;
                        }
                    }
                }, 50);
            }
        }

        // Action Modal Functions
        function openEditModal(cId, cName, cutoff, fee) {
            document.getElementById('modalCourseId').value = cId;
            document.getElementById('modalCourseName').value = cName;
            document.getElementById('modalCutoff').value = cutoff;
            document.getElementById('modalFee').value = fee;
            document.getElementById('editCourseModal').style.display = 'flex';
        }

        function closeEditModal() {
            document.getElementById('editCourseModal').style.display = 'none';
        }

        function confirmDeleteInstitution(collegeName) {
            if(confirm("⚠️ ARE YOU SURE you want to DELETE institution [" + collegeName + "]?\n\nThis will purge the college and ALL its enrolled courses!")) {
                window.location.href = "admin.jsp?action=delete_institution&college_name=" + encodeURIComponent(collegeName);
            }
        }

        function confirmDeleteCourse(courseId, courseName) {
            if(confirm("Are you sure you want to remove course [" + courseName + "] from this college?")) {
                window.location.href = "admin.jsp?action=delete_course&course_id=" + courseId;
            }
        }
    </script>
</head>
<body>
    <!-- Edit Course Modal -->
    <div id="editCourseModal" class="modal-overlay">
        <div class="modal-card">
            <h3 style="color:#00e5a3; margin-top:0; border-bottom:1px solid #374151; padding-bottom:10px;">✏️ Edit Course Details</h3>
            <form method="post" action="admin.jsp">
                <input type="hidden" name="action" value="edit_course">
                <input type="hidden" id="modalCourseId" name="course_id">
                
                <div class="form-group" style="margin-bottom:15px;">
                    <label>Course Name / Code</label>
                    <input type="text" id="modalCourseName" name="new_course_name" required placeholder="e.g. CSE, ECE, MECH">
                </div>
                <div class="form-group" style="margin-bottom:15px;">
                    <label>Cutoff Marks</label>
                    <input type="number" id="modalCutoff" name="new_cutoff" required placeholder="180">
                </div>
                <div class="form-group" style="margin-bottom:15px;">
                    <label>Annual Fee (₹)</label>
                    <input type="number" id="modalFee" name="new_fee" required placeholder="50000">
                </div>
                
                <div style="display:flex; gap:10px; justify-content:flex-end; margin-top:20px;">
                    <button type="button" class="action-btn" onclick="closeEditModal()" style="background:#374151;">Cancel</button>
                    <button type="submit" class="action-btn" style="background:#00e5a3; color:#0b0f19; font-weight:bold;">Save Changes</button>
                </div>
            </form>
        </div>
    </div>

    <div class="container wide" style="max-width: 1150px;">
        <div style="display:flex; justify-content:space-between; align-items:center; margin-bottom:15px;">
            <div style="text-align:left;">
                <div class="brand-title">Admin <span class="brand-accent">Control Center</span></div>
                <div class="brand-subtitle" style="margin-bottom:0;">Institution & Course Asset Management Module</div>
            </div>
            <div>
                <a href="admin.jsp?force_fix=true&clean_it=true" class="btn btn-secondary btn-sm" style="text-decoration:none;">⚡ Re-Index Database Codes</a>
            </div>
        </div>
        
        <% if(successMessage != null) { %><div class="alert alert-success"><%= successMessage %></div><% } %>
        <% if(errorMessage != null) { %><div class="alert alert-danger"><%= errorMessage %></div><% } %>

        <!-- Dashboard Stat Cards -->
        <div class="stats-grid">
            <div class="stat-card">
                <div class="stat-label">Enrolled Institutions</div>
                <div class="stat-number"><%= totalColleges %></div>
            </div>
            <div class="stat-card">
                <div class="stat-label">Total Offered Courses</div>
                <div class="stat-number"><%= totalCourses %></div>
            </div>
            <div class="stat-card">
                <div class="stat-card-content">
                    <div class="stat-label">Registered Students</div>
                    <div class="stat-number" style="color:#3b82f6;"><%= totalStudents %></div>
                </div>
            </div>
        </div>

        <div class="app-layout" style="width:100%; margin: 20px 0; gap:20px;">
            <!-- Add College & Course Form -->
            <div class="sidebar" style="flex:1.1; text-align:left;">
                <h3 style="color:#ffffff; margin-top:0; border-bottom: 1px solid #1f2937; padding-bottom: 10px;">Enroll Institution / Add Course</h3>
                
                <form method="post">
                    <input type="hidden" name="add_college" value="true">
                    
                    <div class="row" style="align-items:flex-end;">
                        <div class="col form-group" style="margin-bottom:15px;">
                            <label>College Code (e.g. E101, M101)</label>
                            <input type="text" id="collegeCodeInput" name="college_code" placeholder="e.g. E101" required onkeyup="handleCollegeCodeInput()">
                        </div>
                        <div class="col form-group" style="margin-bottom:15px;">
                            <label>Stream Selection</label>
                            <select id="streamSelect" name="stream_prefix" onchange="handleStreamChange()">
                                <option value="E">Engineering (E)</option>
                                <option value="M">Medical (M)</option>
                                <option value="A">Arts & Commerce (A)</option>
                            </select>
                        </div>
                    </div>

                    <div class="form-group" style="margin-bottom:15px;">
                        <label>College Name</label>
                        <input type="text" id="collegeNameInput" name="name" placeholder="Sri Sairam College of Engineering" required>
                    </div>

                    <div class="row" style="align-items:flex-end;">
                        <div class="col form-group" style="margin-bottom:15px;">
                            <label>Course Code</label>
                            <input type="text" name="course" placeholder="e.g. CSE, ECE, MBBS" required>
                        </div>
                        <div class="col form-group" style="margin-bottom:15px;">
                            <label>Cutoff Marks</label>
                            <input type="number" name="cutoff" placeholder="180" required>
                        </div>
                    </div>

                    <div class="form-group" style="margin-bottom:15px;">
                        <label>Annual Fee (₹)</label>
                        <input type="number" name="fee" placeholder="50000" required>
                    </div>

                    <div class="row" style="align-items:flex-end;">
                        <div class="col form-group" style="margin-bottom:15px;">
                            <label>District Location</label>
                            <input type="text" id="districtInput" name="district" placeholder="Bengaluru" required>
                        </div>
                        <div class="col form-group" style="margin-bottom:15px;">
                            <label>Management Type</label>
                            <input type="hidden" id="hiddenTypeInput" name="type" value="Government">
                            <select id="typeSelect" onchange="document.getElementById('hiddenTypeInput').value=this.value">
                                <option value="Government">Government</option>
                                <option value="Private">Private</option>
                                <option value="Aided">Aided</option>
                            </select>
                        </div>
                    </div>
                    <button type="submit" style="margin-top:10px;">Commit Course Entry</button>
                </form>
            </div>

            <!-- Colleges Directory & Offered Courses -->
            <div class="main-content container" style="flex:1.9; max-width:100%; background:#111827;">
                <h3 style="text-align:left; margin-top:0; border-bottom: 1px solid #1f2937; padding-bottom: 10px;">Enrolled Institutions Directory</h3>
                
                <div id="tableScrollContainer" class="table-responsive table-scroll-container">
                    <table>
                        <thead>
                            <tr>
                                <th>College Name</th>
                                <th>Active Codes</th>
                                <th>District</th>
                                <th>Type</th>
                                <th>Actions</th>
                            </tr>
                        </thead>
                        <tbody>
                        <%
                        int rowCounter = 0;
                        if(collegeMap.isEmpty()) {
                        %>
                            <tr><td colspan="5" style="text-align:center; color:#9ca3af; padding:20px;">No institutions enrolled yet. Use the left form to add your first college!</td></tr>
                        <%
                        } else {
                            for(Map.Entry<String, CollegeGroup> entry : collegeMap.entrySet()) {
                                rowCounter++;
                                CollegeGroup cg = entry.getValue();
                        %>
                            <tr>
                                <td><strong><%= cg.name %></strong></td>
                                <td>
                                    <div class="badges-container">
                                    <% for(String activeCode : cg.activeCodes) { 
                                        String badgeClass = "";
                                        if(activeCode.startsWith("M")) badgeClass = "med";
                                        else if(activeCode.startsWith("A")) badgeClass = "arts";
                                    %>
                                        <span class="code-badge <%= badgeClass %>"><%= activeCode %></span>
                                    <% } %>
                                    </div>
                                </td>
                                <td><%= cg.district %></td>
                                <td><%= cg.type %></td>
                                <td>
                                    <div style="display:flex; gap:6px; align-items:center;">
                                        <button type="button" class="action-btn" onclick="toggleCourses(<%= rowCounter %>)">Courses (<%= cg.courses.size() %>) ▾</button>
                                        <button type="button" class="action-btn delete-btn" onclick="confirmDeleteInstitution('<%= cg.name.replace("'", "\\'") %>')">🗑️ Delete</button>
                                    </div>
                                </td>
                            </tr>
                            <tr id="details_<%= rowCounter %>" class="course-details-row">
                                <td colspan="5" style="padding:15px 20px; border-bottom: 2px solid #374151;">
                                    <div style="font-size:12px; font-weight:bold; color:#9ca3af; margin-bottom:8px;">
                                        COURSES OFFERED BY <%= cg.name.toUpperCase() %>:
                                    </div>
                                    <div style="display:flex; flex-wrap:wrap; gap:8px;">
                                    <% for(Map<String, String> cMap : cg.courses) { 
                                        String cId = cMap.get("id");
                                        String cCode = cMap.get("code");
                                        String cCourse = cMap.get("course");
                                        String cCutoff = cMap.get("cutoff");
                                        String cFee = cMap.get("fee");

                                        String bCls = "";
                                        if(cCode.startsWith("M")) bCls = "med";
                                        else if(cCode.startsWith("A")) bCls = "arts";
                                    %>
                                        <div class="course-chip">
                                            <span class="code-badge <%= bCls %>" style="font-size:11px;"><%= cCode %></span>
                                            <span class="course-chip-title"><%= cCourse %></span>
                                            <span style="color:#9ca3af;">Cutoff: <strong style="color:#ffffff;"><%= cCutoff %></strong></span>
                                            <span style="color:#9ca3af;">Fee: <strong style="color:#00e5a3;">₹<%= cFee %></strong></span>
                                            
                                            <button type="button" class="action-btn edit-btn" style="padding:2px 6px; font-size:10px;" onclick="openEditModal('<%= cId %>', '<%= cCourse %>', '<%= cCutoff %>', '<%= cFee %>')">✏️ Edit</button>
                                            <button type="button" class="action-btn delete-btn" style="padding:2px 6px; font-size:10px;" onclick="confirmDeleteCourse('<%= cId %>', '<%= cCourse %>')">❌</button>
                                        </div>
                                    <% } %>
                                    </div>
                                </td>
                            </tr>
                        <%  } 
                        } %>
                        </tbody>
                    </table>
                </div>

                <!-- User Account Roster -->
                <div class="divider" style="margin-top:30px;">Registered Platform Students</div>
                <div class="table-responsive" style="max-height:200px; overflow-y:auto;">
                    <table>
                        <thead>
                            <tr>
                                <th>ID</th>
                                <th>Student Name</th>
                                <th>Email</th>
                                <th>Stream</th>
                                <th>City</th>
                            </tr>
                        </thead>
                        <tbody>
                        <%
                        try {
                            Connection con = getDBConnection();
                            ResultSet rsUsers = con.createStatement().executeQuery("SELECT * FROM users WHERE role='USER' ORDER BY id DESC");
                            boolean usersFound = false;
                            while(rsUsers.next()) {
                                usersFound = true;
                        %>
                            <tr>
                                <td><%= rsUsers.getInt("id") %></td>
                                <td><strong><%= rsUsers.getString("name") %></strong></td>
                                <td><%= rsUsers.getString("email") %></td>
                                <td><span style="color:#00e5a3;"><%= rsUsers.getString("stream") %></span></td>
                                <td><%= rsUsers.getString("city") %></td>
                            </tr>
                        <%  }
                            if(!usersFound) {
                        %>
                            <tr><td colspan="5" style="text-align:center; color:#9ca3af;">No registered students yet.</td></tr>
                        <%  }
                            con.close();
                        } catch(Exception e){} %>
                        </tbody>
                    </table>
                </div>

            </div>
        </div>
        <div class="navbar-links"><a href="logout.jsp?uid=<%= adminUserId %>" class="nav-link" style="color:#ef4444;">Terminate Admin Session</a></div>
    </div>
</body>
</html>