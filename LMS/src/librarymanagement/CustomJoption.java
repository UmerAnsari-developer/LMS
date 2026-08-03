package librarymanagement;

import java.awt.Color;
import java.awt.Component;
import java.awt.Cursor;
import java.awt.Font;
import java.awt.event.FocusAdapter;
import java.awt.event.FocusEvent;
import java.awt.event.KeyAdapter;
import java.awt.event.KeyEvent;
import java.awt.event.MouseAdapter;
import java.awt.event.MouseEvent;
import java.awt.geom.RoundRectangle2D;
import javax.swing.ImageIcon;
import javax.swing.JDialog;
import javax.swing.JFrame;
import javax.swing.JLabel;
import javax.swing.JPanel;
import javax.swing.SwingConstants;
import javax.swing.Timer;

public class CustomJoption {

    @SuppressWarnings("unused")
    static int close = 1;



    public static void action(JLabel lable, int[] ack, JDialog dialog, ImageIcon icon_default, ImageIcon icon_border, ImageIcon icon_hover, int i) {
        lable.setCursor(new Cursor(Cursor.HAND_CURSOR));
        lable.addMouseListener(new MouseAdapter() {
            @Override
            public void mousePressed(MouseEvent e) {
                lable.setIcon(new ImageIcon(icon_hover.getDescription()));

            }

            @Override
            public void mouseReleased(MouseEvent e) {
                if (lable.isEnabled()) {
                    if (i == 0) {
                        ack[0] = 0;   // <<------ USER PRESSED CANCEL
                        dialog.dispose();
                    } else {
                        ack[0] = 1;      // <<------ USER PRESSED OK

                    }
                    dialog.dispose();

                }
            }
        });
        lable.setFocusable(true);
        lable.addFocusListener(new FocusAdapter() {
            @Override
            public void focusGained(FocusEvent e) {
                // When TAB highlights the label
                lable.setIcon(new ImageIcon(icon_border.getDescription()));
            }

            @Override
            public void focusLost(FocusEvent e) {
                // Reset icon when focus moves away
                lable.setIcon(new ImageIcon(icon_default.getDescription()));
            }
        });
        lable.addKeyListener(new KeyAdapter() {
            @Override
            public void keyPressed(KeyEvent e) {

                switch (e.getKeyCode()) {
                    case KeyEvent.VK_ENTER -> {
                        lable.setIcon(new ImageIcon(icon_hover.getDescription()));

                        new Timer(0200, ex -> {
                            if (i == 0) {
                                ack[0] = 0; // CANCEL
                            } else {
                                ack[0] = 1; // OK
                            }
                            dialog.dispose();
                        }).start();
                    }
                    case KeyEvent.VK_ESCAPE -> {
                        ack[0] = 0;
                        dialog.dispose();
                    }
                    case KeyEvent.VK_TAB -> {
                        lable.setIcon(new ImageIcon(icon_border.getDescription()));  // show TAB hover
                        lable.transferFocus();
                    }
                    default -> // Just print key
                        System.out.println();
                    // Do NOT close dialog
                }
                
            }
        });

    }

    public static int showCustomDialog(Component parentComponent, String message, int n) {
        final int[] ack = {0};
        // Create the dialog
        JDialog dialog = new JDialog((JFrame) parentComponent, true);
        dialog.setLayout(null); // Use null layout for absolute positioning
        dialog.setUndecorated(true);

        JPanel p1 = new JPanel();
        p1.setLayout(null);

        JLabel l3 = new JLabel(new ImageIcon("Images\\close.png"));
        l3.setBounds(374, 0, 25, 25);
        l3.setCursor(new Cursor(Cursor.HAND_CURSOR));
        l3.setHorizontalAlignment(SwingConstants.CENTER);
        p1.add(l3);
        l3.addMouseListener(new MouseAdapter() {
            @Override
            public void mouseClicked(MouseEvent e) {
                ack[0] = 0;   // <<------ USER PRESSED CLOSE
                dialog.dispose();
            }
        });

        JLabel l2 = new JLabel();
        l2.setIcon(new ImageIcon("Images\\Ok_di.png"));
        l2.setBounds(120, 150, 140, 55);
        l2.setHorizontalAlignment(SwingConstants.CENTER);
        l2.setCursor(new Cursor(Cursor.HAND_CURSOR));
        p1.add(l2);

        // Create and position message label
        JLabel messageLabel = new JLabel(message);
        messageLabel.setFont(new Font("Arial", Font.BOLD, 14));
        messageLabel.setForeground(new Color(0, 0, 0));
        messageLabel.setBounds(20, 20, 500, 50); // Set position and size
        dialog.add(messageLabel);
        
        l2.setBounds(80, 120, 110, 50); // Position at (120, 70) with width 64 and height 64
        action(l2, ack, dialog, new ImageIcon("Images\\Ok_di.png"), new ImageIcon("Images\\Ok_border.png"), new ImageIcon("Images\\Ok_di_hover.png"), 1);
        l2.setFocusable(true);
        l2.requestFocusInWindow();

        JLabel l3_cancel = new JLabel();
        l3_cancel.setIcon(new ImageIcon("Images\\Cancel.png"));
        l3_cancel.setBounds(200, 120, 110, 50); // Position at (120, 70) with width 64 and height 64
        action(l3_cancel, ack, dialog, new ImageIcon("Images\\Cancel.png"), new ImageIcon("Images\\Cancel-border.png"), new ImageIcon("Images\\Cancel-hover.png"), 0);
       
       if (n==1) p1.add(l3_cancel);
       else l3_cancel.setEnabled(false);

        JLabel l1 = new JLabel();
        l1.setIcon(new ImageIcon("Images\\Dbck.jpg"));
        l1.setSize(400, 200);
        p1.add(l1);
        dialog.add(p1);
        p1.setBounds(0, 0, 400, 200);

        // Set dialog size, make it non-resizable, and center it relative to parent
        dialog.setSize(400, 200);
        dialog.setShape(new RoundRectangle2D.Double(0, 0, 400, 200, 30, 30));

        dialog.setResizable(false);
        dialog.setLocationRelativeTo(parentComponent);

        // Show dialog
        dialog.setVisible(true);

        return ack[0];

    }

    public static void main(String[] args) {
        JFrame frame = new JFrame();
        frame.setSize(400, 300);
        frame.setDefaultCloseOperation(JFrame.EXIT_ON_CLOSE);
        frame.setVisible(true);

        int result = showCustomDialog(frame, "This is a custom dialog message.",0);
        System.out.println("User selected option: " + result);
    }
}
