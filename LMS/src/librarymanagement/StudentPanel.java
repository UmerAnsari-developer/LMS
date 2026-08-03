package librarymanagement;

import java.awt.BorderLayout;
import java.awt.Color;
import java.awt.GridLayout;
import java.awt.event.MouseAdapter;
import java.awt.event.MouseEvent;
import java.sql.CallableStatement;
import java.sql.Connection;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.List;

import javax.swing.BorderFactory;
import javax.swing.ImageIcon;
import javax.swing.JDialog;
import javax.swing.JFrame;
import javax.swing.JLabel;
import javax.swing.JOptionPane;
import javax.swing.JPanel;
import javax.swing.JScrollPane;
import javax.swing.JTable;
import javax.swing.table.DefaultTableModel;

public class StudentPanel {

    StudentPanel() {
        String[] menuNames = {
                "     Student Information",
                "     View Books",
                "     Search Books",
                "     Return Book",
                "     Request Books ",
                "     Show Fine ",
                "     Log-out"
        };
        String[] menuIcons = {
                "Images\\Student_info.png",
                "Images\\View-book.png",
                "Images\\search-book.png",
                "Images\\return-book.png",
                "Images\\request-book.png",
                "Images\\Show-fine.png",
                "Images\\logout.png"
        };
        
        List<JLabel> menuList = HomeTemplate.createHomeTemplate(List.of(menuNames), List.of(menuIcons));
        JFrame parent = HomeTemplate.getMainFrame();
        menuList.get(0).addMouseListener(new MouseAdapter() {
            @Override
            public void mouseClicked(MouseEvent evt) {
                student_info(parent);
            }
        });

        menuList.get(menuNames.length - 1).addMouseListener(new MouseAdapter() {
            @Override
            public void mouseClicked(MouseEvent evt) {
                int result = CustomJoption.showCustomDialog(parent, "Do you want to logout?",1);
                if (result == 1) {
                    Login_Out.logoutDB(parent, "Student");
                    parent.dispose();
                    @SuppressWarnings("unused")
                    Homepage homepage = new Homepage();
                }
            }
        });
    }
    
    public static void student_info(JFrame parent) {

    JDialog dialog = new JDialog(parent, "Student Information", true);
    dialog.setBounds(400,105,750, 550);
    dialog.setIconImage(new ImageIcon("Images\\Student_info.png").getImage());
    dialog.setLayout(new BorderLayout());

    /* ----------------------------------------------------
       TOP PANEL – STUDENT DETAILS (NOW WITH EXTRA FIELDS)
       ---------------------------------------------------- */
    JPanel topPanel = new JPanel(new GridLayout(8, 2, 10, 10));
    topPanel.setBorder(BorderFactory.createEmptyBorder(10, 10, 10, 10));
    topPanel.setBackground(Color.WHITE);

    // -------- Dummy Data --------
    String studentId = "";
    String enrollmentNo = "";
    String name = "";
    String email = "";
    String phone = "";
    String address = "";
    String password = "";    // hide password
    String courseSem = "";

    topPanel.add(new JLabel("Student ID:"));
    topPanel.add(new JLabel(studentId));

    topPanel.add(new JLabel("Enrollment No:"));
    topPanel.add(new JLabel(enrollmentNo));

    topPanel.add(new JLabel("Name:"));
    topPanel.add(new JLabel(name));

    topPanel.add(new JLabel("Email:"));
    topPanel.add(new JLabel(email));

    topPanel.add(new JLabel("Phone:"));
    topPanel.add(new JLabel(phone));

    topPanel.add(new JLabel("Address:"));
    topPanel.add(new JLabel("<html>" + address + "</html>"));

    topPanel.add(new JLabel("Password:"));
    topPanel.add(new JLabel(password));

    topPanel.add(new JLabel("Course / Semester:"));
    topPanel.add(new JLabel(courseSem));

    dialog.add(topPanel, BorderLayout.NORTH);

    /* ----------------------------------------------------
       TABLE – ISSUED BOOKS
       ---------------------------------------------------- */
    String[] columns = {"Book ID", "Title", "Issue Date", "Return Date"};

    // ---------------- TABLE (Fully Locked & Non-editable) ---------------- //

DefaultTableModel model = new DefaultTableModel(columns, 0) {
    @Override
    public boolean isCellEditable(int row, int column) {
        return false; // Disable editing
    }
};

JTable table = new JTable(model);

// Disable row dragging / selection
table.setRowSelectionAllowed(false);
table.setColumnSelectionAllowed(false);
table.setCellSelectionEnabled(false);

// Disable column reordering
table.getTableHeader().setReorderingAllowed(false);

// Disable column resizing
table.getTableHeader().setResizingAllowed(false);

// Optional: make background nice
table.setFillsViewportHeight(true);
table.setBackground(Color.WHITE);

// Add table to scroll pane
JScrollPane scrollPane = new JScrollPane(table);
dialog.add(scrollPane, BorderLayout.CENTER);

// ---------------- Dummy Data ---------------- //
loadStudentInfoAndIssuedBooks(
        (JLabel) topPanel.getComponent(1),
        (JLabel) topPanel.getComponent(3),
        (JLabel) topPanel.getComponent(5),
        (JLabel) topPanel.getComponent(7),
        (JLabel) topPanel.getComponent(9),
        (JLabel) topPanel.getComponent(11),
        (JLabel) topPanel.getComponent(13),
        (JLabel) topPanel.getComponent(15),
        model
);


dialog.setVisible(true);
}

public static void loadStudentInfoAndIssuedBooks(
        JLabel lblId, JLabel lblEnroll, JLabel lblName, JLabel lblEmail,
        JLabel lblPhone, JLabel lblAddress, JLabel lblPassword, JLabel lblCourseSem,
        DefaultTableModel bookTableModel
) {
    try (Connection con = DatabaseConnectivity.connectionProvider();
         CallableStatement cs = con.prepareCall("{CALL get_logged_in_student_full_info()}")) 
    {
        boolean hasResult = cs.execute();
        int resultIndex = 1;

        // Clear old rows
        bookTableModel.setRowCount(0);

        while (hasResult) {

            ResultSet rs = cs.getResultSet();

            /* ---------------------------------------------
               RESULT SET #1 → STUDENT DETAILS
            --------------------------------------------- */
            if (resultIndex == 1) {
                if (rs.next()) {
                    lblId.setText(rs.getString("student_id"));
                    lblEnroll.setText(rs.getString("enrollment_no"));
                    lblName.setText(rs.getString("name"));
                    lblEmail.setText(rs.getString("email"));
                    lblPhone.setText(rs.getString("phone"));
                    lblAddress.setText(rs.getString("address"));
                    lblPassword.setText(rs.getString("password"));
                    lblCourseSem.setText(rs.getString("course_semester"));
                }
            }

            /* ---------------------------------------------
               RESULT SET #2 → ISSUED BOOK HISTORY
            --------------------------------------------- */
            else if (resultIndex == 2) {

                while (rs.next()) {

                    Object[] row = {
                            
                            rs.getInt("book_id"),
                            rs.getString("title"),
                            rs.getString("issue_date"),
                            rs.getString("return_date")
                    };

                    bookTableModel.addRow(row);
                }
            }

            resultIndex++;
            hasResult = cs.getMoreResults();
        }

    } catch (SQLException ex) {

        JOptionPane.showMessageDialog(null,
                "Database Error:\n" + ex.getMessage(),
                "Error", JOptionPane.ERROR_MESSAGE);

    } catch (Exception ex) {

        JOptionPane.showMessageDialog(null,
                "Unexpected Error:\n" + ex.getMessage(),
                "Error", JOptionPane.ERROR_MESSAGE);

    }
}


}
