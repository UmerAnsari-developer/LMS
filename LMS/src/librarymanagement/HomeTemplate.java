package librarymanagement;

import java.awt.Color;
import java.awt.Cursor;
import java.awt.Font;
import java.awt.event.MouseAdapter;
import java.awt.event.MouseEvent;
import java.util.ArrayList;
import java.util.List;

import javax.swing.ImageIcon;
import javax.swing.JFrame;
import javax.swing.JLabel;
import javax.swing.JPanel;
import javax.swing.border.LineBorder;

public class HomeTemplate {
     public static void menuDesign(JPanel p2, JLabel hmicon, JPanel sp, String name, int y, ImageIcon icon, int height) {
        hmicon.setIcon(icon);
        hmicon.setIcon(icon);
        hmicon.setText(name);
        hmicon.setFont(new Font("Arial", Font.PLAIN, 16));
        hmicon.setForeground(Color.BLACK);
        hmicon.setBounds(25, y, 270, height + 40);
        hmicon.setCursor(new Cursor(Cursor.HAND_CURSOR));
        hmicon.addMouseListener(new MouseAdapter() {
            @Override
            public void mouseEntered(MouseEvent e) {
                hmicon.setBorder(new LineBorder(Color.BLACK, 1));

            }

            @Override
            public void mouseExited(MouseEvent e) {
                hmicon.setBorder(null);

            }

            // @Override
            // public void mouseClicked(MouseEvent e) {
            //    new Login(1);
            // }
        });
        p2.add(hmicon);
    }
    public static List<JLabel> menuGeneration(List<String> menuNames, List<String> menuIcons, JPanel p2) {

    List<JLabel> menuItems = new ArrayList<>();

    int startY = 50;
    int gap = 40;

    for (int i = 0; i < menuNames.size(); i++) {

        JLabel label = new JLabel();
        JPanel smallPanel = new JPanel();

        int y = startY + (i * gap);

        menuDesign(
                p2,
                label,
                smallPanel,
                menuNames.get(i),
                y,
                new ImageIcon(menuIcons.get(i)),
                0
        );

        menuItems.add(label); // store created menu label
    }

    return menuItems;
}
    private static JFrame mainFrame;
    public static List<JLabel> createHomeTemplate(List<String> menuNames, List<String> menuIcons) {
       mainFrame = new JFrame();      // store
        JFrame f = mainFrame;
        f.setBounds(20, 20, 1200, 700);
        f.setDefaultCloseOperation(JFrame.EXIT_ON_CLOSE);
        f.setUndecorated(true);

        // Creating Background panel
        JPanel p1 = new JPanel();
        p1.setBounds(0, 0, 1200, 700);
        p1.setBackground(Color.BLACK);
        p1.setLayout(null);
        f.add(p1);

        JPanel colorSepartor = new JPanel();
        colorSepartor.setBounds(0, 80, 270, 620);
        colorSepartor.setBackground(new Color(64, 64, 64));
        colorSepartor.setLayout(null);
        p1.add(colorSepartor);

        JLabel titLabel = new JLabel("Library Management System");
        titLabel.setFont(new Font("Arial", Font.BOLD, 25));
        titLabel.setForeground(Color.WHITE);
        titLabel.setBounds(400, 20, 400, 40);
        p1.add(titLabel);
        JLabel librLogo = new JLabel(new ImageIcon("Images\\Library-Homepage.png"));
        librLogo.setBounds(0, 0, 55, 110);
        p1.add(librLogo);
        JLabel closeWindow = new JLabel(new ImageIcon("Images\\Close2.png"));
        closeWindow.setBounds(1180, 0, 20, 15);
        closeWindow.setCursor(new Cursor(Cursor.HAND_CURSOR));
        p1.add(closeWindow);
        closeWindow.addMouseListener(new MouseAdapter() {
            @Override
            public void mouseClicked(MouseEvent e) {
                f.dispose();
            }
        });

        // Slide menu panel
        JPanel p2 = new JPanel();
        p2.setBounds(0, 0, 270, 620);
        p2.setBackground(new Color(255, 255, 255));
        p2.setLayout(null);

        // creating Background panel icon 
        JLabel backgroundicon = new JLabel(new ImageIcon("Images\\round-icon1.png"));
        backgroundicon.setBounds(0, 5, 40, 40);
        backgroundicon.setCursor(new Cursor(Cursor.HAND_CURSOR));
        colorSepartor.add(backgroundicon);
        backgroundicon.addMouseListener(new MouseAdapter() {
            @Override
            public void mouseClicked(MouseEvent e) {
                int y = 0;

                if (y == 0) {
                    colorSepartor.add(p2);
                    // p2.show();
                    p2.setSize(y, 620);
                    Thread th;
                    th = new Thread() {
                        @Override
                        public void run() {
                            try {
                                for (int i = 0; i <= 270; i++) {
                                    sleep(2);
                                    p2.setSize(i, 620);
                                }
                            } catch (InterruptedException e) {
                                //    CustomJoption.showCustomDialog(f, "" + e, "Custom Dialog Box");
                            }
                        }
                    };
                    th.start();
                    colorSepartor.remove(backgroundicon);
                }
            }

        });

        // creating Slide menu panel icon
        JLabel slideicon = new JLabel();
        slideicon.setBounds(3, 5, 40, 40);
        slideicon.setIcon(new ImageIcon("Images\\round-icon1.png"));
        slideicon.setCursor(new Cursor(Cursor.HAND_CURSOR));
        p2.add(slideicon);

        JPanel secondaryPanel = new JPanel();
        secondaryPanel.setBounds(270, 80, 930, 620);
        secondaryPanel.setBackground(new Color(195, 223, 242));
        secondaryPanel.setLayout(null);
        p1.add(secondaryPanel);

        JLabel spLabel = new JLabel(new ImageIcon("Images\\Animated-Images\\LibraryBackground.gif"));
        spLabel.setBounds(0, 0, 930, 620);
        secondaryPanel.add(spLabel);

        List<JLabel> menuList = menuGeneration(menuNames, menuIcons, p2);

        JLabel copyRigth = new JLabel("Copyright © Umair Ansari ");
        copyRigth.setBounds(30, 590, 200, 20);
        copyRigth.setFont(new Font("Verdana", Font.BOLD, 12));
        copyRigth.setForeground(new Color(0, 0, 0));
        p2.add(copyRigth);

        slideicon.addMouseListener(new MouseAdapter() {
            int x = 270;

            @Override
            public void mouseClicked(MouseEvent e) {

                if (x == 270) {
                    p2.setSize(270, 620);
                    Thread th = new Thread() {
                        @Override
                        public void run() {
                            try {
                                for (int i = 270; i >= 0; i--) {
                                    sleep(2);
                                    p2.setSize(i, 620);
                                }
                            } catch (InterruptedException e) {
                                // CustomJoption.showCustomDialog(f, "" + e, "Custom Dialog Box");
                            }
                        }

                    };
                    th.start();
                    colorSepartor.add(backgroundicon);
                }
            }
        });
        f.setVisible(true);
        return menuList;
    }

        public static JFrame getMainFrame() {
        return mainFrame;
    }
    
    
}
