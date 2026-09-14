package librarymanagement;

import java.awt.Desktop;
import java.awt.event.MouseAdapter;
import java.awt.event.MouseEvent;
import java.net.URI;
import java.util.List;
import javax.swing.JFrame;
import javax.swing.JLabel;

public class AdminPanel {
  AdminPanel() 
  {
      
        String[] menuNames = {
            "     Dashboard",
            "     Add User",
            "     Delete User",
            "     Show User",
            "     Reset/Clear",
            "     Log-out"
        };
    
        String[] menuIcons = {
            "Images\\Dashboard-icon.png",
            "Images\\Add-User.png",
            "Images\\delete-User.png",
            "Images\\Librarian.png",
            "Images\\reset-clear.png",
            "Images\\logout.png"
        };
        List<JLabel> menuList = HomeTemplate.createHomeTemplate(List.of(menuNames), List.of(menuIcons));
        JFrame parent = HomeTemplate.getMainFrame();
        
        menuList.get(0).addMouseListener(new MouseAdapter() 
        {
            @Override
            public void mouseClicked(MouseEvent evt) {
                 try {
                    // Check if Desktop is supported by the platform
                    if (Desktop.isDesktopSupported()) {
                        // Get the Desktop instance
                        Desktop desktop = Desktop.getDesktop();
                        
                        // Ensure the platform supports the browse operation
                        if (desktop.isSupported(Desktop.Action.BROWSE)) {
                            // Open the Power BI link in the default web browser
                            desktop.browse(new URI("https://app.powerbi.com/groups/me/reports/2b7b2bf1-d408-4626-8fa0-69f6746aef4e/e55651813bed08659bd9?experience=power-bi"));
                        }
                    } else {
                        CustomJoption.showCustomDialog(parent, "Desktop browsing is not supported on this system.",0);
                    }
                } catch (Exception ex) {
                    ex.printStackTrace();
                    
                    CustomJoption.showCustomDialog(parent, "An error occurred while opening the link: " + ex.getMessage(),0);
                }
            }
        });

        for(int i=0;i<menuList.size();i++){
            if(i==1 || i==2 ){

                menuList.get(i).addMouseListener(new MouseAdapter() 
                {
                    @Override
                    public void mouseClicked(MouseEvent evt) {
                        // FunctionPanel.showCustomDialog(parent); 
                    }
                }); 
            } 
        }  
        menuList.get(5).addMouseListener(new MouseAdapter() 
        {
            @Override
            public void mouseClicked(MouseEvent evt) {
                int result = CustomJoption.showCustomDialog(parent,"Do you want to logout?",1);
                if(result == 1){
                 Login_Out.logoutDB(parent, "Admin");
                 parent.dispose();
                 new Homepage();
                }
            }
        }); 
             
    }
 public static void main(String[] args) {
      new AdminPanel();
   }    
}
