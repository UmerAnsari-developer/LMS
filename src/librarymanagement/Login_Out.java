package librarymanagement;

import java.awt.BorderLayout;
import java.awt.Color;
import java.awt.Component;
import java.awt.Cursor;
import java.awt.Dimension;
import java.awt.Font;
import java.awt.GridBagConstraints;
import java.awt.GridBagLayout;
import java.awt.Insets;
import java.awt.event.FocusAdapter;
import java.awt.event.FocusEvent;
import java.awt.event.MouseAdapter;
import java.awt.event.MouseEvent;
import java.sql.CallableStatement;
import java.sql.Connection;
import java.sql.SQLException;
import java.sql.Types;
import java.util.ArrayList;
import java.util.List;

import javax.swing.BorderFactory;
import javax.swing.Box;
import javax.swing.ImageIcon;
import javax.swing.JDialog;
import javax.swing.JFrame;
import javax.swing.JLabel;
import javax.swing.JPanel;
import javax.swing.JPasswordField;
import javax.swing.JScrollPane;
import javax.swing.JTextArea;
import javax.swing.JTextField;
import javax.swing.Timer;
import javax.swing.border.LineBorder;

@SuppressWarnings("unused")
public class Login_Out {

    public static void closeDialog(JFrame parent, String message) {
        int result = CustomJoption.showCustomDialog(parent, message,1);
        if (result == 1) {
            parent.dispose();
        }
    }

    @SuppressWarnings("CallToPrintStackTrace")
    public static void logoutDB(JFrame frame, String role) {
        // For Admin and Librarian and Student Logout
        try (Connection con = DatabaseConnectivity.connectionProvider(); CallableStatement cs = con.prepareCall("{CALL record_user_logout(?)}")) {
            cs.setString(1, role);
            cs.execute();
        } catch (Exception e) {
            CustomJoption.showCustomDialog(frame, "Error: " + e.getMessage(),0);
            e.printStackTrace();
        }
    }

    @SuppressWarnings("CallToPrintStackTrace")
    public static String loginDBCall(JFrame frame, String username, String password, String query) {
        String message = "";
        try (
                Connection con = DatabaseConnectivity.connectionProvider(); CallableStatement cs = con.prepareCall(query);) {
            cs.setString(1, username);
            cs.setString(2, password);
            cs.registerOutParameter(3, Types.VARCHAR);
            cs.execute();
            message = cs.getString(3);
            switch (message) {
                case "Admin Login Successful." -> {
                    CustomJoption.showCustomDialog(frame, message,0);
                    AdminPanel admin = new AdminPanel();
                    frame.dispose();
                }
                case "Librarian Login Successful." -> {
                    CustomJoption.showCustomDialog(frame, message,0);
                    LibrarianPanel librarian = new LibrarianPanel();
                    frame.dispose();
                }
                case "Student Login Successful." -> {
                    CustomJoption.showCustomDialog(frame, message,0);
                    StudentPanel student = new StudentPanel();
                    frame.dispose();
                }
                case "Invalid Credentials!!!" -> {
                    return message;
                }
                case "User_id did not found!!!" -> {
                    return message;
                }
                case "Invalid password!!!" -> {
                    return message;
                }
                default ->
                    closeDialog(frame, "Error in Login: ");
            }

        } catch (Exception e) {
            // TODO: handle exception
            closeDialog(frame, "Error: " + e.getMessage());
            System.out.println("Exception in loginDBCall: " + e.getMessage());
            e.printStackTrace();
        }

        return message;
    }

    public static String loginDB(JFrame frame, String username, String password, String role) {
        // For Admin and Librarian Login And Student Login

        if (username.isEmpty() && password.isEmpty()) {
            return "Please fill all the fields.";
        } else if (username.isEmpty()) {
            return "Please enter username.";
        } else if (password.isEmpty()) {
            return "Please enter password.";
        }
        String query1 = "{CALL admin_login(?,?,?)}";
        String query2 = "{CALL librarian_login(?,?,?)}";
        String query3 = "{CALL student_login_sp(?,?,?)}";
        String message = "";
        switch (role) {
            case "Admin" ->
                message = loginDBCall(frame, username, password, query1);
            case "Librarian" ->
                message = loginDBCall(frame, username, password, query2);
            case "Student" ->
                message = loginDBCall(frame, username, password, query3);
        }

        return message;
    }

    public static void loginDialog(Component parentComponent, String str, String role) {

        // Create the dialog
        JDialog dialog = new JDialog((JFrame) parentComponent, true);
        dialog.setIconImage(new ImageIcon("Images\\login1.png").getImage());
        dialog.setLayout(null); // Use null layout for absolute positioning
        dialog.setBounds(370, 105, 500, 450);

        loginPanelGenerator(dialog, str, role);
        dialog.setVisible(true);
    }

    public static List<JTextField> loginPanelGenerator(JDialog dialog, String titleMessage, String role) {
        JPanel parent = new JPanel();
        parent.setLayout(null);
        parent.setBounds(0, 0, 500, 450);
        parent.setBackground(Color.darkGray);

        JLabel titleLabel = new JLabel(titleMessage);
        titleLabel.setFont(new Font("Verdana", Font.BOLD, 20));
        titleLabel.setForeground(new Color(74, 137, 220));
        titleLabel.setBounds(110, 40, 485, 35);
        parent.add(titleLabel);

        JPanel userPanel = new JPanel();
        userPanel.setLayout(null);
        userPanel.setBounds(80, 100, 300, 60);
        userPanel.setBorder(new LineBorder(new Color(74, 137, 220), 2));
        userPanel.setBackground(Color.WHITE);
        parent.add(userPanel);

        JLabel userIcon = new JLabel();
        userIcon.setBounds(9, 5, 40, 50);
        userIcon.setIcon(new ImageIcon("Images\\username1.png"));
        JTextField usertf = new JTextField();
        usertf.setBounds(55, 5, 240, 50);
        usertf.setBorder(null);
        usertf.setFont(new Font("verdana", Font.ITALIC, 16));
        usertf.setBackground(Color.WHITE);
        usertf.requestFocusInWindow();
        userPanel.add(usertf);
        userPanel.add(userIcon);

        JPanel passwPanel = new JPanel();
        passwPanel.setLayout(null);
        passwPanel.setBounds(80, 200, 300, 60);
        passwPanel.setBorder(new LineBorder(new Color(74, 137, 220), 2));
        passwPanel.setBackground(Color.WHITE);
        parent.add(passwPanel);
        JLabel passIcon = new JLabel();
        passIcon.setBounds(9, 5, 40, 50);
        passIcon.setIcon(new ImageIcon("Images\\Pass.png"));
        passwPanel.add(passIcon);

        JPasswordField passwpf = new JPasswordField();
        passwpf.setBounds(50, 5, 200, 50);
        passwpf.setBorder(null);
        passwpf.setFont(new Font("verdana", Font.ITALIC, 16));
        passwpf.setBackground(Color.WHITE);
        passwpf.setEchoChar('$');
        passwPanel.add(passwpf);
        JLabel passSecure = new JLabel();
        passSecure.setBounds(250, 5, 45, 50);
        passSecure.setIcon(new ImageIcon("Images\\hidePass.png"));
        passSecure.setCursor(new Cursor(Cursor.HAND_CURSOR));
        passwPanel.add(passSecure);
        passSecure.addMouseListener(new MouseAdapter() {
            @Override
            public void mouseClicked(MouseEvent e) {
                if (passwpf.getEchoChar() == '$') {
                    passSecure.setIcon(new ImageIcon("Images\\showPass.png"));
                    passwpf.setEchoChar('\u0000');
                } else {
                    passSecure.setIcon(new ImageIcon("Images\\hidePass.png"));
                    passwpf.setEchoChar('$');
                }
            }
        });

        JFrame parentFrame = HomeTemplate.getMainFrame();
        JLabel loginIcon = new JLabel();
        loginIcon.setBounds(140, 300, 200, 60);
        loginIcon.setCursor(new Cursor(Cursor.HAND_CURSOR));
        loginIcon.setIcon(new ImageIcon("Images\\Login.png"));
        loginIcon.addMouseListener(new MouseAdapter() {
            @Override
            public void mousePressed(MouseEvent e) {
                loginIcon.setIcon(new ImageIcon("Images\\Login-hover.png"));
            }

            @Override
            public void mouseClicked(MouseEvent e) {
                String username = usertf.getText();
                String password = new String(passwpf.getPassword());
                messageAction(dialog, parentFrame, username, password, role, usertf, passwpf);
            }

            @Override
            public void mouseReleased(MouseEvent e) {
                loginIcon.setIcon(new ImageIcon("Images\\Login.png"));

            }

        });
        loginIcon.setFocusable(true);
        loginIcon.addFocusListener(new FocusAdapter() {
            @Override
            public void focusGained(FocusEvent e) {
                // When TAB highlights the label
                loginIcon.setIcon(new ImageIcon("Images\\Login-border.png"));
            }

            @Override
            public void focusLost(FocusEvent e) {
                // Reset icon when focus moves away
                loginIcon.setIcon(new ImageIcon("Images\\Login.png"));
            }
        });
        loginIcon.addKeyListener(new java.awt.event.KeyAdapter() {
            @Override
            public void keyPressed(java.awt.event.KeyEvent e) {

                if (e.getKeyCode() == java.awt.event.KeyEvent.VK_ENTER) {
                    loginIcon.setIcon(new ImageIcon("Images\\Login-hover.png"));

                    String username = usertf.getText();
                    String password = new String(passwpf.getPassword());
                    Timer t = new Timer(0200, ex -> {
                        messageAction(dialog, parentFrame, username, password, role, usertf, passwpf);
                    });
                    t.setRepeats(false);  // <-- IMPORTANT FIX
                    t.start();

                }
            }

            @Override
            public void keyReleased(java.awt.event.KeyEvent e) {
                loginIcon.setIcon(new ImageIcon("Images\\Login.png"));

            }
        });

        parent.add(loginIcon);
        dialog.getContentPane().add(parent);

        return List.of(usertf, passwpf);
    }

    public static void messageAction(JDialog dialog, JFrame parentFrame, String username, String password, String role, JTextField usertf, JPasswordField passwpf) {
        String message = Login_Out.loginDB(parentFrame, username, password, role);
        switch (message) {
            case "Admin Login Successful.", "Librarian Login Successful.", "Student Login Successful." ->
                dialog.dispose();
            case "Invalid Credentials!!!" -> {
                CustomJoption.showCustomDialog(parentFrame, message,0);
                usertf.setText("");
                passwpf.setText("");
                usertf.requestFocusInWindow();
            }
            case "User_id did not found!!!" -> {
                CustomJoption.showCustomDialog(parentFrame, message,0);
                usertf.setText("");
                usertf.requestFocusInWindow();
            }
            case "Please fill all the fields." -> {
                CustomJoption.showCustomDialog(parentFrame, message,0);
                usertf.setText("");
                usertf.requestFocusInWindow();
            }
            case "Please enter username." -> {
                CustomJoption.showCustomDialog(parentFrame, message,0);
                usertf.setText("");
                usertf.requestFocusInWindow();
            }
            case "Please enter password." -> {
                CustomJoption.showCustomDialog(parentFrame, message,0);
                passwpf.setText("");
                passwpf.requestFocusInWindow();
            }
            default -> {
                CustomJoption.showCustomDialog(parentFrame, message,0);
                passwpf.setText("");
                passwpf.requestFocusInWindow();
            }
        }

    }

    public static void signUpDialog(Component parentComponent) {

        // Create the dialog
        JDialog dialog = new JDialog((JFrame) parentComponent, true);
        dialog.setIconImage(new ImageIcon("Images\\login1.png").getImage());
        dialog.setTitle("Student Sign-up");
        dialog.setLayout(null); // Use null layout for absolute positioning
        dialog.setBounds(370, 105, 600, 580);
        dialog.getContentPane().setBackground(Color.white);
        String[] icon = {
            "Images\\Signup.png", "Images\\Signup-hover.png"
        };
        String[] text = {
            "Enrollment No", "Student Name", "Email", "Contact No", "Password", "Confirm Password", "Course", "Semester"
        };
        List<JTextField> signUpPanel = signUpPanelGenerator(dialog, text, icon);

        dialog.setVisible(true);
    }

    public static List<JTextField> signUpPanelGenerator(JDialog dialog, String[] text, String[] iconNames) {

        int row = 0;

        // ---------- OUTER PANEL WITH 10px PADDING ----------
        JPanel outerPanel = new JPanel(new BorderLayout());
        outerPanel.setBounds(0, 0, 600, 580);
        outerPanel.setBackground(Color.WHITE);
        outerPanel.setBorder(BorderFactory.createEmptyBorder(10, 10, 10, 10));

        // ---------- INNER GRIDBAG PANEL ----------
        JPanel rightLowerJPanel = new JPanel(new GridBagLayout());

        GridBagConstraints gbc = new GridBagConstraints();
        gbc.insets = new Insets(8, 8, 8, 8);
        gbc.anchor = GridBagConstraints.NORTHWEST;
        gbc.fill = GridBagConstraints.HORIZONTAL;
        gbc.weightx = 1;

        List<JTextField> textfield = new ArrayList<>();

        // ---------- MAIN FIELD LOOP ----------
        for (String text1 : text) {
            // ADD LABEL
            gbc.gridx = 0;
            gbc.gridy = row;
            gbc.weighty = 0;
            rightLowerJPanel.add(new JLabel(text1), gbc);
            // ---------- SPECIAL CASE: SEMESTER ----------
            if (text1.equalsIgnoreCase("Semester")) {
                // SEMESTER FIELD
                JTextField semField = new JTextField();
                semField.setBorder(new LineBorder(new Color(74, 137, 255), 1));
                semField.setPreferredSize(new Dimension(250, 28));
                semField.setFont(new Font("Verdana", Font.PLAIN, 14));
                textfield.add(semField);

                gbc.gridx = 1;
                gbc.gridy = row;
                rightLowerJPanel.add(semField, gbc);

                row++;

                // ADDRESS LABEL
                gbc.gridx = 0;
                gbc.gridy = row;
                rightLowerJPanel.add(new JLabel("Address"), gbc);

                // ADDRESS TEXTAREA
                JTextArea addressArea = new JTextArea(4, 20);
                addressArea.setBorder(new LineBorder(new Color(74, 137, 255), 1));
                addressArea.setFont(new Font("Verdana", Font.PLAIN, 14));
                addressArea.setLineWrap(true);
                addressArea.setWrapStyleWord(true);

                JScrollPane scroll = new JScrollPane(addressArea);
                scroll.setPreferredSize(new Dimension(250, 80));
                scroll.setBorder(BorderFactory.createEmptyBorder(5, 5, 5, 5));

                gbc.gridx = 1;
                gbc.gridy = row;
                rightLowerJPanel.add(scroll, gbc);

                row++;
                continue;
            }
            // ---------- SPECIAL CASE: PASSWORD ----------
            if (text1.equalsIgnoreCase("Password") || text1.equalsIgnoreCase("Re-Password") || text1.equalsIgnoreCase("Confirm Password")) {
                JPasswordField pf = new JPasswordField();
                pf.setBorder(new LineBorder(new Color(74, 137, 255), 1));
                pf.setPreferredSize(new Dimension(250, 28));
                pf.setEchoChar('$');
                pf.setFont(new Font("Verdana", Font.PLAIN, 14));
                textfield.add(pf);   // still valid: JPasswordField extends JTextField

                gbc.gridx = 1;
                gbc.gridy = row;
                rightLowerJPanel.add(pf, gbc);

                row++;
                continue;
            }
            // ---------- NORMAL TEXT FIELD ----------
            JTextField tf = new JTextField();
            tf.setBorder(new LineBorder(new Color(74, 137, 255), 1));
            tf.setPreferredSize(new Dimension(250, 28));
            tf.setFont(new Font("Verdana", Font.PLAIN, 14));
            textfield.add(tf);
            gbc.gridx = 1;
            gbc.gridy = row;
            rightLowerJPanel.add(tf, gbc);
            row++;
        }

        // ---------- FILLER TO PUSH EVERYTHING UP ----------
        gbc.gridx = 0;
        gbc.gridy = row;
        gbc.weighty = 1;
        rightLowerJPanel.add(Box.createVerticalGlue(), gbc);

        // ---------- SIGN-UP BUTTON ----------
        JLabel sign_UpLabel = new JLabel(new ImageIcon(iconNames[0]));
        sign_UpLabel.setCursor(new Cursor(Cursor.HAND_CURSOR));

        gbc.gridx = 0;
        gbc.gridy = row + 1;
        gbc.gridwidth = 2;
        gbc.weighty = 0;
        gbc.anchor = GridBagConstraints.CENTER;
        sign_UpLabel.addMouseListener(new MouseAdapter() {
            @Override
            public void mousePressed(MouseEvent e) {
                sign_UpLabel.setIcon(new ImageIcon("Images\\Signup-hover.png"));

            }

            @Override
            public void mouseClicked(MouseEvent e) {

                String enrollmentNo = textfield.get(0).getText().trim();
                String studentName = textfield.get(1).getText().trim();
                String email = textfield.get(2).getText().trim();
                String contactNo = textfield.get(3).getText().trim();
                String password = new String(((JPasswordField) textfield.get(4)).getPassword());
                String confirmPassword = new String(((JPasswordField) textfield.get(5)).getPassword());
                String course = textfield.get(6).getText().trim();
                JTextArea addressArea = (JTextArea) ((JScrollPane) rightLowerJPanel.getComponent(17))
                        .getViewport().getView();
                String address = addressArea.getText().trim();
                String semester = textfield.get(7).getText().trim();

                /* ---------------------------------------------------------
       VALIDATION (EMPTY FIELDS, EMAIL, PHONE, PASSWORD MATCH)
       --------------------------------------------------------- */
                // 1️⃣ Any empty field check
                if (enrollmentNo.isEmpty() || studentName.isEmpty() || email.isEmpty()
                        || contactNo.isEmpty() || password.isEmpty() || confirmPassword.isEmpty()
                        || course.isEmpty() || semester.isEmpty() || address.isEmpty()) {

                    CustomJoption.showCustomDialog(dialog, "All fields are required!",0);
                    return;
                }

                // 2️⃣ Email format check
                if (!email.matches("^[A-Za-z0-9+_.-]+@(.+)$")) {
                    CustomJoption.showCustomDialog(dialog, "Invalid email format!",0);
                    return;
                }

                // 3️⃣ Contact number check (10 digits)
                if (!contactNo.matches("\\d{10}")) {
                    CustomJoption.showCustomDialog(dialog, "Contact number must be 10 digits!",0);
                    return;
                }

                // 4️⃣ Password match
                if (!password.equals(confirmPassword)) {
                    CustomJoption.showCustomDialog(dialog, "Password and Confirm Password do not match!",0);
                    return;
                }

                // 5️⃣ Password length
                if (password.length() < 6) {
                    CustomJoption.showCustomDialog(dialog, "Password must be at least 6 characters!",0);
                    return;
                }

                try {
                String message;
                    message = studentSignUp(enrollmentNo, studentName, email, contactNo,
                            password, course, address, semester);
                            // TODO Auto-generated catch block
                            
                            JFrame parentFrame = HomeTemplate.getMainFrame();
                CustomJoption.showCustomDialog(parentFrame, message,0);
                if (message.equals("Student registered successfully")) {
                    StudentPanel sp = new StudentPanel();
                    parentFrame.dispose();
                    dialog.dispose();
                }
                if (message.equals("Student registered successfully")) {

                    // CLEAR ALL TEXTFIELDS
                    for (int i = 0; i < textfield.size(); i++) {
                        if (textfield.get(i) instanceof JPasswordField jPasswordField) {
                            jPasswordField.setText("");
                        } else {
                            textfield.get(i).setText("");
                        }
                    }
                    
                    // CLEAR ADDRESS TEXTAREA
                    addressArea.setText("");
                    
                    // Close dialog (if required)
                    dialog.dispose();
                }
            } catch (SQLException e1) {

                e1.printStackTrace();
            }
        }
            @Override
            public void mouseReleased(MouseEvent e) {
                sign_UpLabel.setIcon(new ImageIcon("Images\\Signup.png"));

            }
        });

        rightLowerJPanel.add(sign_UpLabel, gbc);

        // Add to main padded panel
        outerPanel.add(rightLowerJPanel, BorderLayout.NORTH);

        dialog.getContentPane().add(outerPanel);
        return textfield;
    }

    public static String studentSignUp(String enrollmentNo, String studentName, String email, String contactNo,
            String password, String course, String address, String semester) throws SQLException {
        // TODO Auto-generated method stub
        String message1 = "";
        try (
                Connection con = DatabaseConnectivity.connectionProvider(); 
                CallableStatement cs = con.prepareCall("{CALL student_sign_up(?,?,?,?,?,?,?,?,?)}")) {
            cs.setString(1, enrollmentNo);
            cs.setString(2, studentName);
            cs.setString(3, email);
            cs.setString(4, contactNo);
            cs.setString(5, password);
            cs.setString(6,address);
            cs.setString(7, course);
            cs.setString(8, semester);
            cs.registerOutParameter(9, Types.VARCHAR);
            cs.execute();
            message1 = cs.getString(9);
            
                return message1;

        } catch (Exception e) {
        }

        return message1;
    }

}
