package librarymanagement;

import java.awt.event.MouseAdapter;
import java.awt.event.MouseEvent;
import java.util.List;
import javax.swing.ImageIcon;
import javax.swing.JFrame;
import javax.swing.JLabel;

public class LibrarianPanel {
  LibrarianPanel() {
      
      String[] menuNames = {
            "     View Books",
            "     Update Book Stock",
            "     Add Books",
            "     Remove Books",
            "     Search Books",
            "     Issue Book",
            "     Issue Books History",
            "     Requested Books",
            "     Returned Books",
            "     Fine Details",
            "     Log-out"
        };
    
        String[] menuIcons = {
            "Images\\viewBook.png",
            "Images\\Available-book.png",
            "Images\\add-book.png",
            "Images\\remove-book.png",
            "Images\\search-book.png",
            "Images\\Issue-books.png",
            "Images\\View-book.png",
            "Images\\request-book.png",
            "Images\\return-book.png",
            "Images\\Show-fine.png",
            "Images\\logout.png"
        };
        List<JLabel> menuList = HomeTemplate.createHomeTemplate(List.of(menuNames), List.of(menuIcons));
        JFrame parent = HomeTemplate.getMainFrame();
        String[] text = {"Student Name", "Course", "Semester", "Student Contact",
                         "Student Email", "Book Name", "Book ID"};
        ImageIcon[] icon = {
            new ImageIcon("Images\\Animated-Images\\IssueBooks.gif"),
            new ImageIcon("Images\\Student.png"),
            new ImageIcon("Images\\Search_student.png"),
            new ImageIcon("Images\\refresh.png"),
            new ImageIcon("Images\\Exit.png"),
            new ImageIcon("Images\\Issue.png")};

         
             
             menuList.get(5).addMouseListener(new MouseAdapter() {
                 @Override
                 public void mouseClicked(MouseEvent evt) {
                    IssueBookPanel.showCustomDialog(parent, text, icon,"Issue Book");
                
                 }
             }); 

             menuList.get(10).addMouseListener(new MouseAdapter() {
                 @Override
                 public void mouseClicked(MouseEvent evt) {
                  int result =  CustomJoption.showCustomDialog(parent,"Do you want to logout?",1);
                  if(result==1){
                    Login_Out.logoutDB(parent, "Librarian");
                    parent.dispose();
                    new Homepage();
                  }
                 }
             });
             
       
  }
 public static void main(String[] args) {
      new LibrarianPanel();
   }    
}
