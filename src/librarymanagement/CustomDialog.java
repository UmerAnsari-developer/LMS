package librarymanagement;



import java.awt.BorderLayout;
import java.awt.Color;
import java.awt.Component;
import java.awt.Dimension;
import java.awt.FlowLayout;
import java.awt.Font;
import java.awt.Frame;
import java.awt.Graphics;
import java.awt.Image;
import javax.swing.ImageIcon;
import javax.swing.JButton;
import javax.swing.JDialog;
import javax.swing.JFrame;
import javax.swing.JLabel;
import javax.swing.JPanel;
import javax.swing.SwingConstants;
import javax.swing.SwingUtilities;

public class CustomDialog {

    /**
     * Shows a dynamic, reusable custom dialog with layout managers.
     * 
     * @param parent      Parent component (for centering)
     * @param message     Text message to show
     * @param bgImage     Background image path (null = no image)
     * @param width       Dialog width
     * @param height      Dialog height
     * @param textColor   Message text color
     * @param font        Font for message
     * @param showButtons true = show OK/Cancel buttons
     * @return int (1 = OK, 2 = Cancel)
     */
    public static int showDialog(Component parent, String message, String bgImage,
                                 int width, int height, Color textColor,
                                 Font font, boolean showButtons) {

        // Create modal dialog
        JDialog dialog = new JDialog((Frame) SwingUtilities.getWindowAncestor(parent), true);
        dialog.setSize(width, height);
        dialog.setResizable(false);
        dialog.setLocationRelativeTo(parent);
        dialog.setUndecorated(true);
        dialog.setLayout(new BorderLayout());

        // ================================
        // Background Panel
        // ================================
        JPanel backgroundPanel = new JPanel(new BorderLayout()) {
            @Override
            protected void paintComponent(Graphics g) {
                super.paintComponent(g);
                if (bgImage != null) {
                    Image img = new ImageIcon(bgImage).getImage();
                    g.drawImage(img, 0, 0, width, height, this);
                }
            }
        };
        backgroundPanel.setPreferredSize(new Dimension(width, height));

        // ================================
        // Message Panel (CENTER)
        // ================================
        JPanel messagePanel = new JPanel();
        messagePanel.setOpaque(false); // transparent for bg image
        JLabel label = new JLabel(message, SwingConstants.CENTER);
        label.setFont(font);
        label.setForeground(textColor);
        messagePanel.add(label);

        backgroundPanel.add(messagePanel, BorderLayout.CENTER);

        // ================================
        // BUTTON PANEL (BOTTOM)
        // ================================
        int[] result = {0}; // 1 = OK, 2 = Cancel

        if (showButtons) {
            JPanel buttonPanel = new JPanel(new FlowLayout(FlowLayout.CENTER, 15, 10));
            buttonPanel.setOpaque(false);

            JButton okBtn = new JButton("OK");
            okBtn.addActionListener(e -> {
                result[0] = 1;
                dialog.dispose();
            });

            JButton cancelBtn = new JButton("Cancel");
            cancelBtn.addActionListener(e -> {
                result[0] = 2;
                dialog.dispose();
            });

            buttonPanel.add(okBtn);
            buttonPanel.add(cancelBtn);

            backgroundPanel.add(buttonPanel, BorderLayout.SOUTH);
        }

        dialog.add(backgroundPanel);
        dialog.setVisible(true);

        return result[0];
    }
    public static void main(String[] args) {
        JFrame frame = new JFrame();
        frame.setSize(400, 300);
        frame.setDefaultCloseOperation(JFrame.EXIT_ON_CLOSE);
        frame.setVisible(true);

        int result = showDialog(frame, "This is a custom dialog message.",
                                "Images\\Dbck.jpg", 400, 200,
                                Color.WHITE, new Font("Arial", Font.PLAIN, 16),
                                true);
        System.out.println("Dialog result: " + result);
    }
}
