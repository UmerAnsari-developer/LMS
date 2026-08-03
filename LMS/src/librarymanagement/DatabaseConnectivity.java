
 package librarymanagement;
import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.SQLException;

public class DatabaseConnectivity {
    static  Connection con;
    @SuppressWarnings("CallToPrintStackTrace")
 public static Connection connectionProvider() throws ClassNotFoundException{
        try {
            Class.forName("com.mysql.cj.jdbc.Driver");
            String url="jdbc:mysql://localhost:3306/librarymanagement_system";
            String user="root";
            String password="UM@ans12er";
            con = DriverManager.getConnection(url,user,password);
        } catch (SQLException ex) {
            System.out.println("SQLException: " + ex.getMessage());
            ex.printStackTrace();
        }
         return con; 
 }
    
}

