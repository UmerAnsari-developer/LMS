package librarymanagement;

import java.awt.event.MouseAdapter;
import java.awt.event.MouseEvent;
import java.util.List;
import javax.swing.JFrame;
import javax.swing.JLabel;

public class Homepage {

    public Homepage() {
        
        String[] menuNames = {
            "     Admin Login",
            "     Librarian Login",
            "     Student Login",
            "     Student Sign-up",
            "     Exit"
        };
    
        String[] menuIcons = {
            "Images\\administrator.png",
            "Images\\Librarian.png",
            "Images\\student1.png",
            "Images\\student1.png",
            "Images\\logout.png"
        };
        String[] msg = {
            "Admin Login Here",
            "Librarian Login Here",
            "Student Login Here",
            
        };
        String[] DBmsg = {
            "Admin",
            "Librarian",
            "Student",
            
        };
        
        JFrame frame = HomeTemplate.getMainFrame();
        List<JLabel> menuList = HomeTemplate.createHomeTemplate(List.of(menuNames), List.of(menuIcons));
        for(int i = 0;i<menuNames.length-2;i++){
            final int index = i;
           menuList.get(i).addMouseListener(new MouseAdapter() {
            @Override
            public void mouseClicked(MouseEvent e){
                
                Login_Out.loginDialog(frame, msg[index], DBmsg[index]);
            }
           });
        }
        menuList.get(menuNames.length-2).addMouseListener(new MouseAdapter() {
            @Override
            public void mouseClicked(MouseEvent e){
                
                Login_Out.signUpDialog(frame);
            }
           });
        menuList.get(menuNames.length-1).addMouseListener(new MouseAdapter() {
            @Override
            public void mouseClicked(MouseEvent e){
                
               int result=  CustomJoption.showCustomDialog(frame, "Do you want to exit?",1);
                if(result==1)
                System.exit(0);
            }
           });
        
    }
    
  public static void main(String[] args) {
      new Homepage();
  }
}