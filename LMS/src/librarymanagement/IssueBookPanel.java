package librarymanagement;

import java.awt.Color;
import java.awt.Component;
import java.awt.Cursor;
import java.awt.Dimension;
import java.awt.FlowLayout;
import java.awt.Font;
import java.awt.GridBagConstraints;
import java.awt.GridBagLayout;
import java.awt.Insets;
import java.awt.event.MouseEvent;
import java.sql.CallableStatement;
import java.sql.Connection;
import java.sql.ResultSet;
import java.util.ArrayList;
import java.util.List;

import javax.swing.BorderFactory;
import javax.swing.Box;
import javax.swing.BoxLayout;
import javax.swing.ImageIcon;
import javax.swing.JDialog;
import javax.swing.JFrame;
import javax.swing.JLabel;
import javax.swing.JPanel;
import javax.swing.JTextField;
import javax.swing.SwingConstants;
import javax.swing.border.LineBorder;

public class IssueBookPanel {

    @SuppressWarnings("unused")

    public static void showCustomDialog(Component parentComponent, String[] text, ImageIcon[] icon, String str) {

        // Create the dialog
        JDialog dialog = new JDialog((JFrame) parentComponent, true);
        dialog.setLayout(null); // Use null layout for absolute positioning
        // dialog.setUndecorated(true);
        dialog.setBounds(370, 105, 750, 550);
        dialog.getContentPane().setBackground(new Color(222, 184, 135));

        JPanel upperJPanel = new JPanel(new FlowLayout());
        upperJPanel.setBounds(10, 5, 710, 100);
        upperJPanel.setBackground(new Color(255, 255, 255));
        dialog.add(upperJPanel);

        JLabel isb = new JLabel();
        isb.setIcon(icon[0]);
        isb.setSize(400, 120);
        isb.setText(str);
        isb.setForeground(new Color(0, 0, 0));
        isb.setFont(new Font("Arial", Font.BOLD, 18));
        upperJPanel.add(isb);

        JPanel rightLowerJPanel = new JPanel(new GridBagLayout());
        rightLowerJPanel.setBounds(325, 110, 395, 395);
        rightLowerJPanel.setBackground(Color.cyan);
        dialog.add(rightLowerJPanel);

        rightLowerJPanel.setLayout(new GridBagLayout());
        GridBagConstraints gbc = new GridBagConstraints();

        gbc.insets = new Insets(10, 5, 5, 5);
        gbc.anchor = GridBagConstraints.NORTHWEST;
        gbc.fill = GridBagConstraints.HORIZONTAL;
        gbc.weightx = 1;

        List<JTextField> textfield = new ArrayList<>();
        for (int i = 0; i < text.length; i++) {

            // LABEL
            gbc.gridx = 0;
            gbc.gridy = i;
            gbc.weighty = 0;
            rightLowerJPanel.add(new JLabel(text[i]), gbc);

            // TEXT FIELD
            JTextField tf = new JTextField();
            tf.setPreferredSize(new Dimension(250, 28));
            textfield.add(tf);

            gbc.gridx = 1;
            gbc.gridy = i;
            rightLowerJPanel.add(tf, gbc);
        }

        // FILLER ROW — pushes everything to TOP
        gbc.gridx = 0;
        gbc.gridy = text.length;
        gbc.weighty = 1;
        rightLowerJPanel.add(Box.createVerticalGlue(), gbc);

        JLabel issueLabel = new JLabel(icon[5]);
        issueLabel.setCursor(new Cursor(Cursor.HAND_CURSOR));
        // center the button across both columns
        gbc.gridx = 0;
        gbc.gridy = text.length;   // next row after all fields
        gbc.gridwidth = 2;         // span across label + textfield columns
        gbc.weighty = 0;
        gbc.fill = GridBagConstraints.NONE;
        gbc.anchor = GridBagConstraints.EAST;
        rightLowerJPanel.add(issueLabel, gbc);

        JLabel msg = new JLabel("Maximum book issue per student is 4");
        msg.setForeground(Color.RED);
        msg.setFont(new Font("Arial", Font.BOLD, 16));
        gbc.gridx = 0;
        gbc.gridy = text.length + 1; // row after issue button
        gbc.gridwidth = 2;            // span across label + textfield columns
        gbc.weighty = 0;
        gbc.fill = GridBagConstraints.NONE;
        gbc.anchor = GridBagConstraints.WEST;
        rightLowerJPanel.add(msg, gbc);

        // MAIN PANEL (VERTICAL LAYOUT)
        JPanel leftLowerJPanel = new JPanel();
        leftLowerJPanel.setBackground(Color.lightGray);
        leftLowerJPanel.setLayout(new BoxLayout(leftLowerJPanel, BoxLayout.Y_AXIS));
        leftLowerJPanel.setBounds(10, 110, 310, 395);
        dialog.add(leftLowerJPanel);

        // -------------------- 1. Student Icon + Text --------------------
        JLabel studentIcon = new JLabel();
        studentIcon.setIcon(icon[1]);
        studentIcon.setText("Enter Enrollment NO");
        studentIcon.setFont(new Font("Arial", Font.BOLD, 18));
        studentIcon.setAlignmentX(Component.CENTER_ALIGNMENT);
        studentIcon.setVerticalTextPosition(SwingConstants.BOTTOM);
        studentIcon.setHorizontalTextPosition(SwingConstants.CENTER);
        studentIcon.setBorder(BorderFactory.createEmptyBorder(20, 0, 10, 0));
        leftLowerJPanel.add(studentIcon);

        // -------------------- 2. TextField --------------------
        JTextField enrollmentTextField = new JTextField();
        enrollmentTextField.setPreferredSize(new Dimension(280, 35));  // WIDTH x HEIGHT
        enrollmentTextField.setMaximumSize(new Dimension(280, 35));
        enrollmentTextField.setMinimumSize(new Dimension(280, 35));
        enrollmentTextField.setAlignmentX(Component.CENTER_ALIGNMENT);
        enrollmentTextField.setHorizontalAlignment(SwingConstants.CENTER);
        enrollmentTextField.setBorder(new LineBorder(Color.BLACK, 2, true));
        leftLowerJPanel.add(enrollmentTextField);

        // Add space below text field
        leftLowerJPanel.add(Box.createVerticalStrut(15));

        // -------------------- 3. Search Button (Below Textfield) --------------------
        JLabel searchLabel = new JLabel();
        searchLabel.setIcon(icon[2]);
        searchLabel.setCursor(new Cursor(Cursor.HAND_CURSOR));
        searchLabel.setAlignmentX(Component.CENTER_ALIGNMENT);
        searchLabel.setBorder(BorderFactory.createEmptyBorder(20, 0, 0, 0));

        JFrame parent = HomeTemplate.getMainFrame();
        // Functioning of Panel
        // Add Mouse Listener to Search Student
        searchLabel.addMouseListener(new java.awt.event.MouseAdapter() {
            @Override
            public void mousePressed(MouseEvent e) {
                searchLabel.setIcon(new ImageIcon("Images\\Search_student-hover.png"));
                String enrollmentNo = enrollmentTextField.getText();
                if (enrollmentNo.isEmpty()) {
                    CustomJoption.showCustomDialog(parent, "Please enter Enrollment No",1);
                    searchLabel.setIcon(new ImageIcon("Images\\Search_student.png"));
                } else {
                   int result = dbOpeartion(enrollmentTextField, parent, textfield);
                     if (result == 0) {
                            enrollmentTextField.setText("");
                            textfield.forEach(tf -> tf.setText(""));
                     }
                    
                }
            }

            @Override
            public void mouseReleased(MouseEvent e) {
                searchLabel.setIcon(new ImageIcon("Images\\Search_student.png"));

            }
        });
        leftLowerJPanel.add(searchLabel);

        JPanel bottomButtonPanel = new JPanel();
        bottomButtonPanel.setLayout(new FlowLayout(FlowLayout.CENTER, 40, 0));
        bottomButtonPanel.setOpaque(false);
        bottomButtonPanel.setBorder(BorderFactory.createEmptyBorder(20, 0, 0, 0));

        JLabel refreshLabel = new JLabel(icon[3]);
        refreshLabel.setCursor(new Cursor(Cursor.HAND_CURSOR));
        refreshLabel.setAlignmentX(Component.RIGHT_ALIGNMENT);
        refreshLabel.setBorder(BorderFactory.createEmptyBorder(40, 0, 0, 0));
        bottomButtonPanel.add(refreshLabel);

        JLabel exitLabel = new JLabel(icon[4]);
        exitLabel.setCursor(new Cursor(Cursor.HAND_CURSOR));
        exitLabel.setAlignmentX(Component.LEFT_ALIGNMENT);
        exitLabel.setBorder(BorderFactory.createEmptyBorder(40, 0, 0, 0));
        bottomButtonPanel.add(exitLabel);
        leftLowerJPanel.add(bottomButtonPanel);

        dialog.add(upperJPanel);
        dialog.setVisible(true);

    }

    public static int  dbOpeartion(JTextField enrollmentTextField, JFrame parent, List<JTextField> textField) {
        int n[]={0};
        String enrollmentNo = enrollmentTextField.getText();

        if (enrollmentNo.isEmpty()) {
            CustomJoption.showCustomDialog(parent, "Please enter Enrollment No",0);
        }

        try (Connection con = DatabaseConnectivity.connectionProvider(); 
             CallableStatement cs = con.prepareCall("{CALL get_student_full_details(?,?)}")) {

            cs.setString(1, enrollmentNo);
            cs.registerOutParameter(2, java.sql.Types.VARCHAR);
            
            boolean hasResult = cs.execute();
            String message = cs.getString(2);
            
            if (message.equals("OK") && hasResult) {
                try (ResultSet rs = cs.getResultSet()) {
                    if (rs.next()) {
                        // READ RESULT VALUES
                        n[0] = 1;
                        String name = rs.getString("name");
                        String email = rs.getString("email");
                        String course = rs.getString("department_name");
                        String sem = rs.getString("semester");
                        String phone = rs.getString("contact");
                        
                        // SET INTO TEXTFIELDS
                        textField.get(0).setText(name);
                        textField.get(1).setText(course);
                        textField.get(2).setText(sem);
                        textField.get(3).setText(phone);
                        textField.get(4).setText(email);
                        
                    }
                }
            }
            else {
                CustomJoption.showCustomDialog(parent, message,1);
                n[0] = 0;
            }
            
        } catch (Exception ex) {
            CustomJoption.showCustomDialog(parent, "Error Occured",1);
            System.err.println(ex.getMessage());

        }
        return n[0];
    }

    // public static void main(String[] args) {

    //     String[] text = {"Student Name", "Course", "Semester", "Student Contact",
    //         "Student Email", "Book Name", "Book ID"};
    //     ImageIcon[] icon = {
    //         new ImageIcon("Images\\Animated-Images\\IssueBooks.gif"),
    //         new ImageIcon("Images\\Student.png"),
    //         new ImageIcon("Images\\Search_student.png"),
    //         new ImageIcon("Images\\refresh.png"),
    //         new ImageIcon("Images\\Exit.png"),
    //         new ImageIcon("Images\\Issue.png")};
    //     JFrame frame = new JFrame();
    //     frame.setVisible(true);
    //     showCustomDialog(frame, text, icon, "Issue Book");

    // }
}
